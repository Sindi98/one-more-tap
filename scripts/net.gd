class_name Net
extends Node
## AIR HOCKEY between phones, two ways. On the local network (the same Wi-Fi,
## or a phone's hotspot) there is no server: the phone that creates a lobby
## hosts it with ENet and says so on the network every second (a UDP
## broadcast), so the others can list it; guests can also type the lobby's
## 4-character code (see Lobby.code_for), which works where broadcasts don't
## get through, as on iPhones. Over the internet, phones talk through the
## relay in server/ (see RelayPeer), and the relay gives the lobby a
## 5-character code to send to friends.
## Either way the host keeps the lobby, runs the match and sends snapshots;
## guests send where their finger is. The only file that opens connections.

signal lobbies_changed  ## the lobbies heard nearby changed: see `found`
signal joined  ## in a lobby: hosting one, or the host let us in
## Out of the lobby without asking: "closed" (the host left), "full",
## "playing" (a match is on), "version" (another version of the game),
## "failed" (the host can't be reached); online also "offline" (no relay),
## "not_found" (no lobby with that code), "busy" (the relay is) or "bad".
signal left(reason: String)
signal lobby_changed  ## players, teams or settings changed: see `lobby`
signal match_started(setup: Dictionary)  ## see start_match()
signal snapshot_received(data: PackedFloat32Array)  ## guests: see Hockey.snapshot()
signal target_received(peer: int, target: Vector2)  ## host: where a guest's finger is
signal match_ended(winner: int, last: PackedFloat32Array)  ## guests: the result and last snapshot
signal peer_left(peer: int)  ## host: a guest went away; a bot takes their place

const GAME_PORT := 47610
const DISCOVERY_PORT := 47611
const MAX_GUESTS := 6  ## a full 2 vs 2 has 3, the rest is room for those being turned away
const BEACON_EVERY := 1.0  ## seconds
const LOBBY_TIMEOUT := 3.5  ## a lobby not heard for this long is gone
const LOBBIES_MAX := 8  ## lobbies listed at most
const CONNECT_TIMEOUT := 6.0  ## seconds to reach the host and be let in
const PACKETS_PER_FRAME := 32
const BEACON_RETRY := 5.0  ## seconds before trying again when a beacon can't go out
## The relay for AIR HOCKEY over the internet (see server/README.md), for
## example "wss://omt-relay.onrender.com". Empty: debug builds use the one
## started on this computer (npm start in server/), release builds have no
## online lobbies.
const RELAY_URL := ""
const RELAY_LOCAL := "ws://127.0.0.1:47620"
const ONLINE_TIMEOUT := 45.0  ## seconds: a relay on a free plan may need waking up

var lobby := Lobby.new()
var found := {}  ## ip -> what its beacon says (see Lobby.parse_beacon) and "seen"
var player_name := "?"
var playing := false  ## a match is on

var _hosting := false
var _in_lobby := false
var _connecting := 0.0  ## seconds left to get into a lobby, 0 when not trying
var _beacon_in := 0.0
var _listener: PacketPeerUDP
var _sender: PacketPeerUDP
var _clock := 0.0
var _relay: RelayPeer  ## the connection to the relay, when online
var _retired: MultiplayerPeer  ## a connection just let go, kept until the next frame


func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)


func _process(delta: float) -> void:
	_clock += delta
	_retired = null
	if _listener:
		_listen()
	if _hosting and not playing and _relay == null:
		_beacon_in -= delta
		if _beacon_in <= 0.0:
			_beacon_in = BEACON_EVERY if _send_beacon() else BEACON_RETRY
	if _connecting > 0.0:
		_connecting -= delta
		if _connecting <= 0.0:
			var why := "offline" if _relay else "failed"
			_close()
			left.emit(why)


## Lobbies on the local network need sockets the web version doesn't have.
func lan_available() -> bool:
	return not OS.has_feature("web")


## Lobbies over the internet need a relay.
func online_available() -> bool:
	return not _relay_url().is_empty()


func available() -> bool:
	return lan_available() or online_available()


func _relay_url() -> String:
	if not RELAY_URL.is_empty():
		return RELAY_URL
	return RELAY_LOCAL if OS.is_debug_build() else ""


func is_host() -> bool:
	return _hosting


## The lobby goes through the relay.
func is_online() -> bool:
	return _relay != null


func in_lobby() -> bool:
	return _in_lobby


func my_id() -> int:
	return multiplayer.get_unique_id()


## Listen for the lobbies nearby. If the port is taken, lobbies can still be
## joined by code.
func start_browsing() -> void:
	if _listener:
		return
	found.clear()
	_listener = PacketPeerUDP.new()
	# On Android broadcasts reach the app only with this on: it holds a Wi-Fi
	# multicast lock (permission CHANGE_WIFI_MULTICAST_STATE).
	_listener.set_broadcast_enabled(true)
	if _listener.bind(DISCOVERY_PORT, "0.0.0.0") != OK:
		_listener = null


func stop_browsing() -> void:
	if _listener:
		_listener.close()
		_listener = null
	found.clear()


## A new lobby, with this phone as host and first player: on this network
## (`joined` at once; false if the game port can't be opened), or online on
## the relay (`joined` once the relay gives it its code, `left` if it can't
## be reached).
func host(online := false) -> bool:
	if online:
		_host_online()
		return true
	_close()
	var peer := ENetMultiplayerPeer.new()
	if peer.create_server(GAME_PORT, MAX_GUESTS) != OK:
		return false
	_use(peer)
	stop_browsing()
	_hosting = true
	_in_lobby = true
	lobby = Lobby.new()
	lobby.add(1, player_name)
	lobby.code = Lobby.code_for(Lobby.local_ip(IP.get_local_addresses()))
	_beacon_in = 0.0
	joined.emit()
	lobby_changed.emit()
	return true


## Into the lobby hosted at `ip`: `joined` or `left` follows.
func join(ip: String) -> void:
	_close()
	var peer := ENetMultiplayerPeer.new()
	if peer.create_client(ip, GAME_PORT) != OK:
		left.emit("failed")
		return
	_use(peer)
	_connecting = CONNECT_TIMEOUT


func _host_online() -> void:
	_close()
	stop_browsing()
	var relay := RelayPeer.new()
	if relay.host(_relay_url()) != OK:
		left.emit("offline")
		return
	relay.hosted.connect(_on_hosted)
	_relay = relay
	_use(relay)
	_connecting = ONLINE_TIMEOUT


## Into the lobby with `text` as code: 5 characters for one on the relay, 4
## for one on this network. False if the code can't be right: then nothing
## is tried.
func join_code(text: String) -> bool:
	var clean := Lobby.clean_code(text)
	if clean.length() == Lobby.ONLINE_CODE_LENGTH:
		if not online_available():
			return false
		_join_online(clean)
		return true
	if not lan_available():
		return false
	var ip := Lobby.ip_for(clean, Lobby.local_ip(IP.get_local_addresses()))
	if ip.is_empty():
		return false
	join(ip)
	return true


## Out of the lobby; the host closes it for everyone.
func leave() -> void:
	_close()


## To the other team, if it has room.
func switch_team() -> void:
	if _hosting:
		if not playing and lobby.switch(1):
			_share_lobby()
	elif _in_lobby:
		_rpc_switch.rpc_id(1)


## Host: 1 vs 1 or 2 vs 2. False if there are too many players for 1 vs 1.
func toggle_team_size() -> bool:
	if not _hosting or playing:
		return false
	if not lobby.set_team_size(1 if lobby.team_size == 2 else 2):
		return false
	_share_lobby()
	return true


## Host: the next choice of goals to win.
func next_goals() -> void:
	if _hosting and not playing:
		lobby.next_goals()
		_share_lobby()


## Host: everyone to the table. The setup says the team size, the goals to
## win, and for each mallet its player (0 for a bot) and name.
func start_match() -> void:
	if not _hosting or playing:
		return
	var roster := []
	var names := []
	for team in 2:
		for id in lobby.roster(team):
			roster.append(id)
			names.append(lobby.name_of(id))
	var setup := {"size": lobby.team_size, "goals": lobby.goals, "roster": roster, "names": names}
	playing = true
	for id in _guests():
		_rpc_start.rpc_id(id, setup)
	match_started.emit(setup)


## Guest: where the finger wants the mallet.
func send_target(target: Vector2) -> void:
	if _in_lobby and not _hosting and playing:
		_rpc_target.rpc_id(1, target)


## Host: the match as it is now, to every guest.
func send_snapshot(data: PackedFloat32Array) -> void:
	if _hosting and playing:
		for id in _guests():
			_rpc_snapshot.rpc_id(id, data)


## Host: the match is over; the lobby opens again for a rematch.
func end_match(winner: int, last: PackedFloat32Array) -> void:
	if not _hosting or not playing:
		return
	playing = false
	for id in _guests():
		_rpc_end.rpc_id(id, winner, last)


# --- the host's side -------------------------------------------------------

@rpc("any_peer", "call_remote", "reliable")
func _rpc_hello(protocol: int, guest_name: String) -> void:
	if not _hosting:
		return
	var id := multiplayer.get_remote_sender_id()
	var why := ""
	if protocol != Lobby.PROTOCOL:
		why = "version"
	elif playing:
		why = "playing"
	elif not lobby.players.has(id) and not lobby.add(id, guest_name):
		why = "full"
	if why.is_empty():
		_share_lobby()
	else:
		_rpc_refused.rpc_id(id, why)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_switch() -> void:
	if _hosting and not playing and lobby.switch(multiplayer.get_remote_sender_id()):
		_share_lobby()


@rpc("any_peer", "call_remote", "unreliable_ordered", 1)
func _rpc_target(target: Vector2) -> void:
	var id := multiplayer.get_remote_sender_id()
	if _hosting and playing and lobby.players.has(id):
		target_received.emit(id, target)


# --- the guests' side ------------------------------------------------------

@rpc("authority", "call_remote", "reliable")
func _rpc_refused(reason: String) -> void:
	_close()
	left.emit(reason)


@rpc("authority", "call_remote", "reliable")
func _rpc_lobby(data: Dictionary) -> void:
	lobby.from_dict(data)
	if not _in_lobby:
		_in_lobby = true
		_connecting = 0.0
		joined.emit()
	lobby_changed.emit()


@rpc("authority", "call_remote", "reliable")
func _rpc_start(setup: Dictionary) -> void:
	if _in_lobby:
		playing = true
		match_started.emit(setup)


# Snapshots and fingers go on their own channel: a late one is dropped, and
# never holds up the lobby messages.
@rpc("authority", "call_remote", "unreliable_ordered", 1)
func _rpc_snapshot(data: PackedFloat32Array) -> void:
	if playing:
		snapshot_received.emit(data)


@rpc("authority", "call_remote", "reliable")
func _rpc_end(winner: int, last: PackedFloat32Array) -> void:
	if playing:
		playing = false
		match_ended.emit(winner, last)


# --- connection --------------------------------------------------------------


func _on_connected() -> void:
	_set_timeout(1)
	_rpc_hello.rpc_id(1, Lobby.PROTOCOL, player_name)


func _on_connection_failed() -> void:
	if _connecting > 0.0:
		var why := _relay_reason("failed")
		_close()
		left.emit(why)


func _on_server_disconnected() -> void:
	if not _in_lobby and _connecting <= 0.0:
		return
	var why := _relay_reason("closed")
	_close()
	left.emit(why)


## Online: the relay opened our lobby.
func _on_hosted(room_code: String) -> void:
	_connecting = 0.0
	_hosting = true
	_in_lobby = true
	lobby = Lobby.new()
	lobby.add(1, player_name)
	lobby.code = room_code
	joined.emit()
	lobby_changed.emit()


func _join_online(room_code: String) -> void:
	_close()
	var relay := RelayPeer.new()
	if relay.join(_relay_url(), room_code) != OK:
		left.emit("offline")
		return
	_relay = relay
	_use(relay)
	_connecting = ONLINE_TIMEOUT


## Why the relay let us go, if it did; `fallback` otherwise.
func _relay_reason(fallback: String) -> String:
	if _relay and not _relay.reason.is_empty():
		return _relay.reason
	return fallback


func _on_peer_connected(id: int) -> void:
	if _hosting:
		_set_timeout(id)


func _on_peer_disconnected(id: int) -> void:
	if not _hosting or not lobby.players.has(id):
		return
	lobby.remove(id)
	peer_left.emit(id)
	_share_lobby()


func _use(peer: MultiplayerPeer) -> void:
	var api := multiplayer as SceneMultiplayer
	if api:
		api.server_relay = false  # guests talk to the host only
	multiplayer.multiplayer_peer = peer


## Back to no network at all. The flags go first: closing the peer may fire
## the disconnection signals, which then have nothing to do. The peer is
## kept until the next frame: this may run while it is still busy.
func _close() -> void:
	_hosting = false
	_in_lobby = false
	_connecting = 0.0
	playing = false
	lobby = Lobby.new()
	_sender = null
	_relay = null
	var peer := multiplayer.multiplayer_peer
	if peer and not peer is OfflineMultiplayerPeer:
		_retired = peer
		peer.close()
		multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()


## A phone that stops answering is let go after a few seconds, not thirty.
func _set_timeout(id: int) -> void:
	var enet := multiplayer.multiplayer_peer as ENetMultiplayerPeer
	if enet == null:
		return
	var p := enet.get_peer(id)
	if p:
		p.set_timeout(32, 3000, 6000)


func _guests() -> Array[int]:
	var ids: Array[int] = []
	for id in lobby.order:
		if id != 1:
			ids.append(id)
	return ids


func _share_lobby() -> void:
	var data := lobby.to_dict()
	for id in _guests():
		_rpc_lobby.rpc_id(id, data)
	lobby_changed.emit()


# --- discovery ---------------------------------------------------------------


## True if the beacon went out. iPhones need a special permission from Apple
## to broadcast, and Wi-Fi may be off for a moment: then it is tried again
## less often, and guests can still use the code.
func _send_beacon() -> bool:
	if _sender == null:
		_sender = PacketPeerUDP.new()
		_sender.set_broadcast_enabled(true)
	var data := Lobby.beacon(player_name, lobby.players.size(), lobby.capacity(), lobby.code)
	var sent := false
	for address in _broadcast_addresses():
		_sender.set_dest_address(address, DISCOVERY_PORT)
		sent = _sender.put_packet(data) == OK or sent
	return sent


## The whole network, and this phone's own subnet for routers that drop the
## first kind.
func _broadcast_addresses() -> PackedStringArray:
	var out := PackedStringArray(["255.255.255.255"])
	var p := Lobby.local_ip(IP.get_local_addresses()).split(".")
	if p.size() == 4:
		out.append("%s.%s.%s.255" % [p[0], p[1], p[2]])
	return out


func _listen() -> void:
	var changed := false
	var budget := PACKETS_PER_FRAME
	while _listener.get_available_packet_count() > 0 and budget > 0:
		budget -= 1
		var bytes := _listener.get_packet()
		var ip := _listener.get_packet_ip()
		var info := Lobby.parse_beacon(bytes)
		if info.is_empty() or ip.is_empty():
			continue
		if not found.has(ip) and found.size() >= LOBBIES_MAX:
			continue
		var old: Dictionary = found.get(ip, {})
		for key in ["name", "players", "places", "code"]:
			changed = changed or old.get(key) != info[key]
		info["seen"] = _clock
		found[ip] = info
	for ip: String in found.keys():
		if _clock - float(found[ip]["seen"]) > LOBBY_TIMEOUT:
			found.erase(ip)
			changed = true
	if changed:
		lobbies_changed.emit()
