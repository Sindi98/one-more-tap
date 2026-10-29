extends SceneTree
## Headless tests for RelayPeer, AIR HOCKEY's connection to the relay. Run
## from the project folder:
##   godot --headless --path . --script res://tests/test_relay_peer.gd
## The last tests need the relay running on this computer (npm start in
## server/); without it they are skipped. Exit code 0 = all passed.

const RelayScript := preload("res://scripts/relay_peer.gd")
const RELAY := "ws://127.0.0.1:47620"
const RELIABLE := MultiplayerPeer.TRANSFER_MODE_RELIABLE
const ORDERED := MultiplayerPeer.TRANSFER_MODE_UNRELIABLE_ORDERED

var _fails := 0


func _init() -> void:
	_test_frames()
	_test_host_side()
	_test_guest_side()
	_test_refused()
	_test_nothing_goes_out_unconnected()
	_test_with_the_relay()
	print("all tests passed" if _fails == 0 else "%d failures" % _fails)
	quit(1 if _fails > 0 else 0)


func _check(cond: bool, msg: String) -> void:
	if not cond:
		_fails += 1
		print("FAIL ", msg)


func _test_frames() -> void:
	var bytes: PackedByteArray = RelayScript.frame(-7, 1, ORDERED, "abc".to_utf8_buffer())
	_check(bytes.size() == RelayScript.HEADER + 3, "header and payload")
	_check(bytes.decode_s32(0) == -7, "the peer id, little-endian")
	var back: Dictionary = RelayScript.unframe(bytes)
	_check(back["peer"] == -7 and back["channel"] == 1, "peer and channel back")
	_check(back["mode"] == ORDERED, "transfer mode back")
	_check(back["data"].get_string_from_utf8() == "abc", "payload back")
	_check(RelayScript.unframe(PackedByteArray([1, 2, 3])).is_empty(), "too short to be a packet")
	_check(RelayScript.mode_of(9) == RELIABLE, "an unknown mode is reliable")
	_check(RelayScript.why_closed(4000, "closed") == "closed", "the host left")
	_check(RelayScript.why_closed(4001, "full") == "full", "a refusal says why")
	_check(RelayScript.why_closed(4001, "made up") == "offline", "unknown reasons are not trusted")
	_check(RelayScript.why_closed(1006, "") == "offline", "the connection was lost")
	var empty: PackedByteArray = RelayScript.frame(1, 0, RELIABLE, PackedByteArray())
	var guest = RelayScript.new()
	guest._on_packet(empty)
	_check(guest.get_available_packet_count() == 0, "empty packets are dropped")


func _test_host_side() -> void:
	var host = RelayScript.new()
	host._server = true
	host._id = 1
	host._status = MultiplayerPeer.CONNECTION_CONNECTING
	var codes := []
	var came := []
	var went := []
	host.hosted.connect(func(code: String) -> void: codes.append(code))
	host.peer_connected.connect(func(id: int) -> void: came.append(id))
	host.peer_disconnected.connect(func(id: int) -> void: went.append(id))
	host._on_message('{"t": "hosted", "code": "K7Q2M"}')
	_check(codes == ["K7Q2M"] and host.code == "K7Q2M", "the relay gives the code")
	_check(host.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED, "connected")
	_check(host.is_server() and host.get_unique_id() == 1, "the host is peer 1")
	host._on_message('{"t": "peer", "id": 55, "on": true}')
	host._on_message('{"t": "peer", "id": 55, "on": true}')
	_check(came == [55], "a guest comes in, once")
	host._on_packet(RelayScript.frame(55, 0, RELIABLE, "hi".to_utf8_buffer()))
	host._on_packet(RelayScript.frame(99, 0, RELIABLE, "who?".to_utf8_buffer()))
	_check(host.get_available_packet_count() == 1, "only guests in the room are heard")
	_check(host.get_packet_peer() == 55, "from the guest")
	_check(host.get_packet().get_string_from_utf8() == "hi", "what the guest said")
	host._on_message('{"t": "peer", "id": 55, "on": false}')
	_check(went == [55], "the guest leaves")
	host._on_message("not json")
	host._on_message('["a list"]')
	_check(
		host.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED, "junk changes nothing"
	)


func _test_guest_side() -> void:
	var guest = RelayScript.new()
	guest._id = 4321
	guest._status = MultiplayerPeer.CONNECTION_CONNECTING
	var came := []
	guest.peer_connected.connect(func(id: int) -> void: came.append(id))
	guest._on_message('{"t": "joined"}')
	_check(came == [1], "in: the host is there")
	_check(guest.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED, "connected")
	_check(not guest.is_server() and guest.get_unique_id() == 4321, "a guest's own id")
	guest._on_message('{"t": "peer", "id": 77, "on": true}')
	_check(came == [1], "guests don't hear of each other")
	guest._on_packet(RelayScript.frame(1, 1, ORDERED, "snap".to_utf8_buffer()))
	guest._on_packet(RelayScript.frame(77, 0, RELIABLE, "psst".to_utf8_buffer()))
	_check(guest.get_available_packet_count() == 1, "only the host is heard")
	_check(guest.get_packet_channel() == 1 and guest.get_packet_mode() == ORDERED, "channel, mode")
	_check(guest.get_packet().get_string_from_utf8() == "snap", "the host's packet")


func _test_refused() -> void:
	var guest = RelayScript.new()
	guest._status = MultiplayerPeer.CONNECTION_CONNECTING
	guest._on_message('{"t": "error", "reason": "not_found"}')
	_check(guest.reason == "not_found", "the reason is kept")
	var status: int = guest.get_connection_status()
	_check(status == MultiplayerPeer.CONNECTION_DISCONNECTED, "and the peer is closed")


func _test_nothing_goes_out_unconnected() -> void:
	var peer = RelayScript.new()
	_check(peer.put_packet(PackedByteArray([1, 2])) == ERR_UNCONFIGURED, "not connected yet")


## Polls `peers` until `done` says so, for up to `seconds`.
func _wait(peers: Array, done: Callable, seconds := 3.0) -> bool:
	var until := Time.get_ticks_msec() + int(seconds * 1000.0)
	while Time.get_ticks_msec() < until:
		for p in peers:
			p.poll()
		if done.call():
			return true
		OS.delay_msec(10)
	return false


## The real thing, against the relay on this computer.
func _test_with_the_relay() -> void:
	var host = RelayScript.new()
	host.host(RELAY)
	var connected := MultiplayerPeer.CONNECTION_CONNECTED
	var ready := func() -> bool:
		return host.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTING
	_wait([host], ready)
	if host.get_connection_status() != connected:
		print("relay not running (npm start in server/): online tests skipped")
		return
	_check(host.code.length() == 5, "a 5-character code: %s" % host.code)

	var guest = RelayScript.new()
	var came := []
	host.peer_connected.connect(func(id: int) -> void: came.append(id))
	guest.join(RELAY, host.code)
	var both_in := func() -> bool:
		return not came.is_empty() and guest.get_connection_status() == connected
	_check(_wait([host, guest], both_in), "the guest gets in")
	_check(came == [guest.get_unique_id()], "the host hears of the guest by its id")

	host.set_target_peer(guest.get_unique_id())
	host.put_packet("ping".to_utf8_buffer())
	_check(
		_wait([host, guest], func() -> bool: return guest.get_available_packet_count() > 0), "ping"
	)
	_check(
		guest.get_packet_peer() == 1 and guest.get_packet().get_string_from_utf8() == "ping",
		"from the host"
	)
	guest.set_target_peer(1)
	guest.transfer_channel = 1
	guest.put_packet("pong".to_utf8_buffer())
	_check(
		_wait([host, guest], func() -> bool: return host.get_available_packet_count() > 0), "pong"
	)
	_check(host.get_packet_peer() == guest.get_unique_id(), "from the guest")
	_check(host.get_packet_channel() == 1, "on its channel")

	var lost = RelayScript.new()
	lost.join(RELAY, "ZZZZZ")
	var refused := func() -> bool:
		return lost.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED
	_check(_wait([lost], refused), "a wrong code is refused")
	_check(lost.reason == "not_found", "because there is no such lobby: %s" % lost.reason)

	host.close()
	var gone := func() -> bool:
		return guest.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED
	_check(_wait([guest], gone), "the host leaves: the guest is let go")
	_check(guest.reason == "closed", "because the lobby closed: %s" % guest.reason)
