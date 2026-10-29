class_name RelayPeer
extends MultiplayerPeerExtension
## AIR HOCKEY over the internet: a MultiplayerPeer that goes through the relay
## server in server/ over a WebSocket, so Net and its RPCs work exactly as on
## the local network. The host is peer 1; a guest picks its own id and the
## relay checks it. Every packet travels with a 6-byte header: the peer id
## (who gets it on the way out, who sent it on the way in), the channel and
## the transfer mode. Over a WebSocket everything arrives, and in order.

signal hosted(code: String)  ## the relay opened our room, with this code

const PROTOCOL := 1  ## the relay's (server/relay.mjs): bumped together
const HEADER := 6
const MAX_PACKET := 4096 - HEADER  ## the relay drops bigger messages
const CLOSED_BY_HOST := 4000  ## the relay's close code when the host leaves

## Why the relay let us go: "not_found", "full", "playing", "version", "busy"
## or "bad" when it refused, "closed" when the host left, "offline" when the
## connection was lost or never made. Empty while connected.
var reason := ""
var code := ""  ## the room's, once hosted

var _ws := WebSocketPeer.new()
var _status := MultiplayerPeer.CONNECTION_DISCONNECTED
var _server := false
var _id := 0
var _room := ""  ## the code to join, for a guest
var _said_hello := false
var _target := 0
var _channel := 0
var _mode := MultiplayerPeer.TRANSFER_MODE_RELIABLE
var _refusing := false
var _inbox: Array[Dictionary] = []  ## {"peer", "channel", "mode", "data"}, oldest first
var _guests: Array[int] = []


## Opens a room on the relay at `url` (ws:// or wss://). `hosted` follows, or
## the connection fails.
func host(url: String) -> Error:
	_server = true
	_id = 1
	return _open(url)


## Joins the room with `room_code` on the relay at `url`.
func join(url: String, room_code: String) -> Error:
	_server = false
	_id = generate_unique_id()
	_room = room_code
	return _open(url)


## A packet as it goes to the relay: `peer`, `channel` and `mode`, then the
## payload.
static func frame(peer: int, channel: int, mode: int, payload: PackedByteArray) -> PackedByteArray:
	var out := PackedByteArray()
	out.resize(HEADER)
	out.encode_s32(0, peer)
	out[4] = channel
	out[5] = mode
	out.append_array(payload)
	return out


## A packet from the relay: {"peer", "channel", "mode", "data"}, or {} if it
## is too short to be one.
static func unframe(bytes: PackedByteArray) -> Dictionary:
	if bytes.size() < HEADER:
		return {}
	return {
		"peer": bytes.decode_s32(0),
		"channel": int(bytes[4]),
		"mode": mode_of(bytes[5]),
		"data": bytes.slice(HEADER),
	}


## The transfer mode a header byte stands for; reliable if it's no mode.
static func mode_of(byte: int) -> MultiplayerPeer.TransferMode:
	if byte == MultiplayerPeer.TRANSFER_MODE_UNRELIABLE:
		return MultiplayerPeer.TRANSFER_MODE_UNRELIABLE
	if byte == MultiplayerPeer.TRANSFER_MODE_UNRELIABLE_ORDERED:
		return MultiplayerPeer.TRANSFER_MODE_UNRELIABLE_ORDERED
	return MultiplayerPeer.TRANSFER_MODE_RELIABLE


# --- MultiplayerPeer ---------------------------------------------------------


func _poll() -> void:
	if _status == MultiplayerPeer.CONNECTION_DISCONNECTED:
		return
	_ws.poll()
	var state := _ws.get_ready_state()
	if state == WebSocketPeer.STATE_OPEN:
		if not _said_hello:
			_said_hello = true
			if _server:
				_say({"t": "host", "v": PROTOCOL})
			else:
				_say({"t": "join", "code": _room, "id": _id, "v": PROTOCOL})
		while (
			_status != MultiplayerPeer.CONNECTION_DISCONNECTED
			and _ws.get_available_packet_count() > 0
		):
			var data := _ws.get_packet()
			if _ws.was_string_packet():
				_on_message(data.get_string_from_utf8())
			else:
				_on_packet(data)
	elif state == WebSocketPeer.STATE_CLOSED:
		if reason.is_empty():
			reason = "closed" if _ws.get_close_code() == CLOSED_BY_HOST else "offline"
		_lost()


func _get_available_packet_count() -> int:
	return _inbox.size()


func _get_packet_script() -> PackedByteArray:
	if _inbox.is_empty():
		return PackedByteArray()
	return _inbox.pop_front()["data"]


func _get_packet_peer() -> int:
	return _inbox[0]["peer"] if not _inbox.is_empty() else 0


func _get_packet_channel() -> int:
	return _inbox[0]["channel"] if not _inbox.is_empty() else 0


func _get_packet_mode() -> MultiplayerPeer.TransferMode:
	if _inbox.is_empty():
		return MultiplayerPeer.TRANSFER_MODE_RELIABLE
	return mode_of(_inbox[0]["mode"])


func _put_packet_script(p_buffer: PackedByteArray) -> Error:
	if _status != MultiplayerPeer.CONNECTION_CONNECTED:
		return ERR_UNCONFIGURED
	if p_buffer.size() > MAX_PACKET:
		return ERR_INVALID_PARAMETER
	return _ws.send(frame(_target, _channel, _mode, p_buffer))


func _get_max_packet_size() -> int:
	return MAX_PACKET


func _set_transfer_channel(p_channel: int) -> void:
	_channel = p_channel


func _get_transfer_channel() -> int:
	return _channel


func _set_transfer_mode(p_mode: MultiplayerPeer.TransferMode) -> void:
	_mode = p_mode


func _get_transfer_mode() -> MultiplayerPeer.TransferMode:
	return _mode


func _set_target_peer(p_peer: int) -> void:
	_target = p_peer


func _is_server() -> bool:
	return _server


func _close() -> void:
	_ws.close()
	_status = MultiplayerPeer.CONNECTION_DISCONNECTED
	_inbox.clear()
	_guests.clear()


func _disconnect_peer(p_peer: int, _p_force: bool) -> void:
	if _server and _status == MultiplayerPeer.CONNECTION_CONNECTED:
		_say({"t": "kick", "id": p_peer})


func _get_unique_id() -> int:
	return _id


func _get_connection_status() -> MultiplayerPeer.ConnectionStatus:
	return _status


func _is_server_relay_supported() -> bool:
	return false


func _set_refuse_new_connections(p_enable: bool) -> void:
	_refusing = p_enable
	if _server and _status == MultiplayerPeer.CONNECTION_CONNECTED:
		_say({"t": "lock", "on": p_enable})


func _is_refusing_new_connections() -> bool:
	return _refusing


# --- the relay ---------------------------------------------------------------


func _open(url: String) -> Error:
	reason = ""
	var err := _ws.connect_to_url(url)
	if err == OK:
		_status = MultiplayerPeer.CONNECTION_CONNECTING
	return err


func _say(msg: Dictionary) -> void:
	_ws.send_text(JSON.stringify(msg))


## What the relay says about the room. The connection is marked connected
## before the multiplayer API hears of the host, so it can answer at once.
func _on_message(text: String) -> void:
	var json := JSON.new()
	if json.parse(text) != OK or not json.data is Dictionary:
		return
	var msg: Dictionary = json.data
	match str(msg.get("t", "")):
		"hosted":
			code = str(msg.get("code", ""))
			_status = MultiplayerPeer.CONNECTION_CONNECTED
			hosted.emit(code)
		"joined":
			_status = MultiplayerPeer.CONNECTION_CONNECTED
			peer_connected.emit(1)
		"peer":
			var id := Lobby.int_of(msg, "id", 0)
			if not _server or id < 2:
				return
			if msg.get("on", false):
				if not id in _guests:
					_guests.append(id)
					peer_connected.emit(id)
			elif id in _guests:
				_guests.erase(id)
				peer_disconnected.emit(id)
		"error":
			reason = str(msg.get("reason", "bad"))
			_ws.close()
			_lost()


func _on_packet(bytes: PackedByteArray) -> void:
	var packet := unframe(bytes)
	if packet.is_empty():
		return
	var peer: int = packet["peer"]
	# Guests hear only from the host, the host only from its guests.
	if (_server and peer in _guests) or (not _server and peer == 1):
		_inbox.append(packet)


## The relay is gone: so is everyone reached through it.
func _lost() -> void:
	_status = MultiplayerPeer.CONNECTION_DISCONNECTED
	_inbox.clear()
	for id in _guests:
		peer_disconnected.emit(id)
	_guests.clear()
