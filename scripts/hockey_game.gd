class_name HockeyGame
extends Node
## AIR HOCKEY's flow: the lobbies nearby, the lobby, the match and its result.
## Net carries the lobby and the match between the phones, Hockey runs the
## match (the host's is the real one, guests run a copy kept in step),
## HockeyView draws it and LobbyPanel shows the screens around it. Behind the
## lobby screens two bots play. Main hands over the screen and the input
## while AIR HOCKEY is open, and takes them back on `closed`.

signal closed  ## back to the start screen
signal changed  ## the player's name changed: save it

enum Phase { BROWSE, ROOM, PLAY, RESULT }

const SNAPSHOT_EVERY := 1.0 / 30.0  ## seconds between the host's snapshots
const SOUND_GAP := 0.07  ## seconds: one knock per hit, not one per frame of contact
const LEFT_REASONS := {
	"closed": "LEFT_CLOSED",
	"full": "LEFT_FULL",
	"playing": "LEFT_PLAYING",
	"version": "LEFT_VERSION",
	"failed": "LEFT_FAILED",
}

var player_name := ""  ## saved by Main
var phase := Phase.BROWSE

var _net: Net
var _view: HockeyView
var _panel: LobbyPanel
var _sfx: Sfx
var _music: Music
var _match: Hockey  ## on the table: a real match, or the bots behind the lobby
var _me := -1  ## our mallet in the match, -1 if none
var _roster: Array[int] = []  ## the peer playing each mallet, 0 for a bot
var _snap_in := 0.0
var _sound_in := 0.0
var _touch := -1  ## the finger moving our mallet, -1 if none
var _target := Vector2.INF  ## where our mallet should go
var _sent := Vector2.INF  ## the last target sent to the host


func _ready() -> void:
	if player_name.is_empty():
		player_name = tr("PLAYER_NAME") % randi_range(10, 99)


func setup(net: Net, view: HockeyView, panel: LobbyPanel, sfx: Sfx, music: Music) -> void:
	_net = net
	_view = view
	_panel = panel
	_sfx = sfx
	_music = music
	_net.lobbies_changed.connect(_on_lobbies_changed)
	_net.joined.connect(_on_joined)
	_net.left.connect(_on_left)
	_net.lobby_changed.connect(_on_lobby_changed)
	_net.match_started.connect(_begin)
	_net.snapshot_received.connect(_on_snapshot)
	_net.target_received.connect(_on_target)
	_net.match_ended.connect(_on_match_ended)
	_net.peer_left.connect(_on_peer_left)
	_panel.back_pressed.connect(_on_back)
	_panel.create_pressed.connect(_on_create)
	_panel.join_pressed.connect(_on_join)
	_panel.code_entered.connect(_on_code)
	_panel.name_changed.connect(_on_name)
	_panel.switch_pressed.connect(_net.switch_team)
	_panel.size_pressed.connect(_on_size)
	_panel.goals_pressed.connect(_net.next_goals)
	_panel.start_pressed.connect(_net.start_match)
	_panel.rematch_pressed.connect(_net.start_match)
	_panel.lobby_pressed.connect(_on_to_lobby)
	_panel.leave_pressed.connect(_on_leave)


## Phones only: the web version has no sockets.
func available() -> bool:
	return _net.available()


## AIR HOCKEY opens on the lobbies nearby.
func open() -> void:
	_net.player_name = player_name
	_music.set_playlist("neon")
	_demo()
	_browse()


func tick(delta: float) -> void:
	if _match == null:
		return
	_match.update(delta)
	if phase == Phase.PLAY:
		if _net.is_host():
			_snap_in -= delta
			if _snap_in <= 0.0:
				_snap_in = SNAPSHOT_EVERY
				_net.send_snapshot(_match.snapshot())
		elif _target.is_finite() and _target != _sent:
			_sent = _target
			_net.send_target(_target)
	_sound_in = maxf(0.0, _sound_in - delta)
	_view.tick(delta)


## During a match, one finger drags our mallet; on a computer, the mouse.
func handle_input(event: InputEvent) -> void:
	if phase != Phase.PLAY or _me < 0:
		return
	var at := Vector2.INF
	var touch := event as InputEventScreenTouch
	if touch:
		if touch.pressed and _touch < 0:
			_touch = touch.index
		elif not touch.pressed and touch.index == _touch:
			_touch = -1
			return
		if touch.index == _touch:
			at = touch.position
	var drag := event as InputEventScreenDrag
	if drag and drag.index == _touch:
		at = drag.position
	# Mouse events that Godot makes up from a touch come from device -1:
	# that finger was already counted.
	var mouse := event as InputEventMouse
	if mouse and mouse.device != -1:
		at = mouse.position
	if at.is_finite():
		_match.set_target(_me, _view.table_point(at))
		_target = _match.mallets[_me].target


# --- screens ---------------------------------------------------------------


func _browse(message := "") -> void:
	phase = Phase.BROWSE
	_net.start_browsing()
	_panel.set_busy(false)
	_panel.show_browse(player_name, _net.found)
	if not message.is_empty():
		_panel.show_message(message, true)
	_music.set_mood(Music.Mood.MENU)
	if _me >= 0:
		_demo()


func _show_room() -> void:
	phase = Phase.ROOM
	_panel.show_room(_net.lobby, _net.my_id(), _net.is_host())
	_music.set_mood(Music.Mood.MENU)
	if _me >= 0:
		_demo()


## Two bots play behind the lobby screens, and start again when one wins.
func _demo() -> void:
	var demo := Hockey.new(1, Hockey.GOALS_TO_WIN)
	for m in demo.mallets:
		m.bot = true
	_show_match(demo, -1, PackedStringArray())


func _show_match(rules: Hockey, me: int, names: PackedStringArray) -> void:
	_match = rules
	_me = me
	_match.goal.connect(_on_goal)
	_match.hit.connect(_on_hit)
	_match.bounced.connect(_on_bounced)
	_match.held.connect(_on_held)
	_match.won.connect(_on_won)
	_view.reset(_match, me, names)
	_view.fx.reset(Hockey.WIDTH / 390.0)


## Everyone to the table: the setup comes from the host (see Net.start_match).
func _begin(setup: Dictionary) -> void:
	var size := Lobby.int_of(setup, "size", 1)
	var goals := clampi(Lobby.int_of(setup, "goals", Hockey.GOALS_TO_WIN), 1, 9)
	var rules := Hockey.new(size, goals)
	var roster: Variant = setup.get("roster", [])
	var given: Variant = setup.get("names", [])
	var names := PackedStringArray()
	_roster.clear()
	for i in rules.mallets.size():
		var id := 0
		if roster is Array and i < roster.size() and roster[i] is int:
			id = roster[i]
		_roster.append(id)
		var text := ""
		if id != 0 and given is Array and i < given.size():
			text = Lobby.clean_name(str(given[i]))
		names.append(text)
	rules.scoring = _net.is_host()
	if _net.is_host():
		for i in rules.mallets.size():
			rules.mallets[i].bot = _roster[i] == 0
	_show_match(rules, _roster.find(_net.my_id()), names)
	phase = Phase.PLAY
	_touch = -1
	_target = Vector2.INF
	_sent = Vector2.INF
	_snap_in = 0.0
	_panel.show_play()
	_music.set_mood(Music.Mood.RUN)
	_vibrate(20)


func _finish(winner: int) -> void:
	phase = Phase.RESULT
	var my_team := _match.mallets[_me].team if _me >= 0 else -1
	_panel.show_result(winner, my_team, _match.score, _net.is_host())
	_music.set_mood(Music.Mood.MENU)
	if my_team == winner:
		_sfx.record()
	else:
		_sfx.die()
	_vibrate(40)


# --- the panel -------------------------------------------------------------


func _on_back() -> void:
	_net.leave()
	_net.stop_browsing()
	closed.emit()


func _on_create() -> void:
	_net.player_name = player_name
	if not _net.host():
		_panel.show_message(tr("HOST_FAILED"), true)


func _on_join(ip: String) -> void:
	_net.player_name = player_name
	_panel.set_busy(true)
	_panel.show_message(tr("CONNECTING"))
	_net.join(ip)


func _on_code(text: String) -> void:
	_net.player_name = player_name
	_panel.set_busy(true)
	_panel.show_message(tr("CONNECTING"))
	if not _net.join_code(text):
		_panel.set_busy(false)
		_panel.show_message(tr("BAD_CODE"), true)


func _on_name(text: String) -> void:
	if text == player_name:
		return
	player_name = text
	_net.player_name = text
	changed.emit()


func _on_size() -> void:
	if not _net.toggle_team_size():
		_panel.show_message(tr("TOO_MANY"), true)


func _on_to_lobby() -> void:
	if _net.in_lobby():
		_show_room()


func _on_leave() -> void:
	_net.leave()
	_browse()


# --- the network -----------------------------------------------------------


func _on_lobbies_changed() -> void:
	if phase == Phase.BROWSE:
		_panel.set_lobbies(_net.found)


func _on_joined() -> void:
	_panel.set_busy(false)
	_sfx.buy()
	_show_room()


func _on_left(reason: String) -> void:
	_browse(tr(LEFT_REASONS.get(reason, "LEFT_CLOSED")))


func _on_lobby_changed() -> void:
	if phase == Phase.ROOM:
		_show_room()


## Guests: the host's match. The puck glides from where it was to where the
## host has it.
func _on_snapshot(data: PackedFloat32Array) -> void:
	if phase != Phase.PLAY or _net.is_host():
		return
	var before := _match.puck
	_match.apply_snapshot(data, _me)
	_view.nudge(before - _match.puck)


## Host: a guest's finger.
func _on_target(peer: int, target: Vector2) -> void:
	var i := _roster.find(peer)
	if phase == Phase.PLAY and i >= 0:
		_match.set_target(i, target)


func _on_match_ended(winner: int, last: PackedFloat32Array) -> void:
	if phase != Phase.PLAY:
		return
	_match.apply_snapshot(last, _me)
	_finish(winner)


## Host: a guest went away during the match. A bot takes over their mallet.
func _on_peer_left(peer: int) -> void:
	var i := _roster.find(peer)
	if phase != Phase.PLAY or i < 0:
		return
	_roster[i] = 0
	_match.mallets[i].bot = true
	var at := _view.camera_target()
	_view.fx.float_text(tr("PLAYER_LEFT"), at, UiKit.MUTED)


# --- the match -------------------------------------------------------------


func _on_goal(team: int) -> void:
	_view.flash_goal(team)
	var color := HockeyView.team_color(team)
	var mouth := _view.goal_position(1 - team)
	_view.fx.burst(mouth, 26, color, 1.6)
	if phase != Phase.PLAY:
		return
	_view.fx.float_text(tr("GOAL"), _view.camera_target(), color)
	var mine := _me >= 0 and _match.mallets[_me].team == team
	if mine:
		_sfx.goal()
	else:
		_sfx.die()
	_vibrate(45 if mine else 25)


func _on_hit(strength: float) -> void:
	if phase != Phase.PLAY or strength < 0.02 or _sound_in > 0.0:
		return
	_sound_in = SOUND_GAP
	_sfx.hit()
	_view.fx.burst(_view.puck_position(), 3 + int(strength * 8.0), UiKit.INK, 0.4 + strength)
	_vibrate(6)


func _on_bounced(strength: float) -> void:
	if phase != Phase.PLAY or strength < 0.08 or _sound_in > 0.0:
		return
	_sound_in = SOUND_GAP
	_sfx.tick()


## Host: seven seconds in a half; the puck goes to the other team.
func _on_held(_team: int) -> void:
	if phase == Phase.PLAY:
		_view.fx.float_text(tr("HOLD_TIME"), _view.puck_position(), UiKit.HOT)


func _on_won(winner: int) -> void:
	if phase != Phase.PLAY:
		_demo.call_deferred()  # the bots behind the lobby: again
		return
	_net.end_match(winner, _match.snapshot())
	_finish(winner)


func _vibrate(ms: int) -> void:
	if OS.has_feature("mobile"):
		Input.vibrate_handheld(ms)
