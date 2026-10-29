class_name LobbyPanel
extends Control
## AIR HOCKEY's screens, built in code: the lobbies nearby (create one, join
## one, or type its code), the lobby itself (teams, settings, start), the
## result of a match, and the way out during one. HockeyGame fills it and
## listens to it; Hud shows it and places it. Texts are keys of
## assets/i18n/strings.csv.

signal back_pressed  ## out of AIR HOCKEY, to the start screen
signal create_pressed
signal join_pressed(ip: String)
signal code_entered(code: String)
signal name_changed(player_name: String)
signal switch_pressed
signal size_pressed  ## host: 1 vs 1 or 2 vs 2
signal goals_pressed  ## host: goals to win
signal start_pressed  ## host
signal rematch_pressed  ## host, after a match
signal lobby_pressed  ## after a match: back to the lobby
signal leave_pressed  ## out of the lobby, or of the match

const ROW_W := 560.0
const LOBBY_ROWS := 4  ## lobbies listed at most
const TEAM_KEYS := ["TEAM_BLUE", "TEAM_RED"]
const CONFIRM_TIME := 2.5  ## seconds to tap ESCI again during a match

var box: VBoxContainer  ## the page on screen, placed by Hud under the safe area
var bottom: HBoxContainer  ## back / leave, placed by Hud
var exit: Button  ## during a match, in a top corner: placed by Hud

var _display := UiKit.load_font(UiKit.DISPLAY_FONT)
var _body := UiKit.load_font(UiKit.BODY_FONT)
var _body_bold := UiKit.load_font(UiKit.BODY_BOLD_FONT)
var _neon := Color.from_hsv(188.0 / 360.0, 0.78, 1.0)
var _neon_labels: Array[Label] = []
var _page := ""  ## "browse", "room", "result" or "play"
var _menus: Control  ## the pages, on a shade; hidden during a match
var _browse: VBoxContainer
var _name: LineEdit
var _list: VBoxContainer
var _none: Label
var _code: LineEdit
var _join: Button
var _create: Button
var _room: VBoxContainer
var _room_code: Label
var _teams: Array[VBoxContainer] = []
var _switch: Button
var _host_row: HBoxContainer
var _size: Button
var _goals: Button
var _settings: Label
var _start: Button
var _wait: Label
var _result: VBoxContainer
var _result_title: Label
var _result_score: Label
var _rematch: Button
var _result_hint: Label
var _message: Label
var _back: Button
var _busy := false
var _confirm_until := 0  ## msec: ESCI pressed once, a second press leaves


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_menus = UiKit.panel(self)
	_menus.visible = true
	box = UiKit.vbox(8)
	_menus.add_child(box)
	box.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_build_browse()
	_build_room()
	_build_result()
	_message = UiKit.label("", _body_bold, 24, _neon)
	_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_message.custom_minimum_size.x = ROW_W
	_message.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(_message)
	# Both leave this screen: on release, like RIPROVA.
	bottom = UiKit.bottom_row(_menus)
	_back = _button(tr("BACK"), Vector2(Hud.MODE_BUTTON_W * 1.3, 72), 26, _on_back)
	bottom.add_child(_back)
	exit = _button(tr("LEAVE"), Vector2(190, 60), 20, _on_exit)
	add_child(exit)
	exit.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_style_all()


## The lobbies nearby. found: ip -> {"name", "players", "places"} (see Net).
func show_browse(player_name: String, found: Dictionary) -> void:
	_show("browse")
	if not _name.has_focus():
		_name.text = player_name
	set_lobbies(found)


func set_lobbies(found: Dictionary) -> void:
	for c in _list.get_children():
		_list.remove_child(c)
		c.queue_free()
	var shown := 0
	for ip: String in found:
		if shown >= LOBBY_ROWS:
			break
		var info: Dictionary = found[ip]
		var places: int = info["places"]
		var players: int = info["players"]
		var text := "%s    %d/%d" % [tr("LOBBY_OF") % info["name"], players, places]
		var b := _button(text, Vector2(ROW_W, 76), 24, func() -> void: _on_lobby(ip))
		b.disabled = _busy or players >= places
		_style(b, 24, UiKit.MUTED if b.disabled else _neon)
		_list.add_child(b)
		shown += 1
	_none.visible = shown == 0


## Who is in the lobby and on which team, and what the host can change.
## me: this phone's peer id.
func show_room(lobby: Lobby, me: int, host: bool) -> void:
	_show("room")
	_room_code.text = lobby.code if not lobby.code.is_empty() else "—"
	for team in 2:
		var column := _teams[team]
		for c in column.get_children():
			if c.get_index() > 0:  # the team's name stays
				column.remove_child(c)
				c.queue_free()
		for id in lobby.roster(team):
			var text := tr("CPU") if id == 0 else lobby.name_of(id)
			if id == me:
				text += " " + tr("YOU")
			var color := UiKit.MUTED if id == 0 else UiKit.INK
			column.add_child(UiKit.label(text, _body_bold, 28, color))
	var size_text := tr("TEAM_SIZE") % [lobby.team_size, lobby.team_size]
	var goals_text := tr("FIRST_TO") % lobby.goals
	_size.text = size_text
	_goals.text = goals_text
	_settings.text = "%s  ·  %s" % [size_text, goals_text]
	_host_row.visible = host
	_start.visible = host
	_settings.visible = not host
	_wait.visible = not host
	_wait.text = tr("WAITING_HOST") % lobby.name_of(1)


## The match is over. my_team: -1 for someone who only watched.
func show_result(winner: int, my_team: int, score: Array[int], host: bool) -> void:
	_show("result")
	var won := my_team == winner
	var color := HockeyView.team_color(winner)
	if my_team < 0:
		_result_title.text = tr("TEAM_WINS") % tr(TEAM_KEYS[winner])
	else:
		_result_title.text = tr("VICTORY") if won else tr("DEFEAT")
		color = color if won else UiKit.HOT
	_result_title.label_settings.font_color = color
	_result_title.label_settings.shadow_color = Color(color, 0.32)
	_result_score.text = (
		"%s %d  –  %d %s" % [tr(TEAM_KEYS[0]), score[0], score[1], tr(TEAM_KEYS[1])]
	)
	_rematch.visible = host
	_result_hint.visible = not host


## During a match: only the way out, in a corner.
func show_play() -> void:
	_show("play")


## A line under the page: what happened, or what is going on.
func show_message(text: String, bad := false) -> void:
	_message.text = text
	_message.label_settings.font_color = UiKit.HOT if bad else _neon


## While joining a lobby: nothing else can be started.
func set_busy(on: bool) -> void:
	_busy = on
	_create.disabled = on
	_join.disabled = on
	for b in _list.get_children():
		(b as Button).disabled = on
	_style_all()


## The theme colour changed.
func set_neon(color: Color) -> void:
	_neon = color
	for l in _neon_labels:
		l.label_settings.font_color = _neon
		l.label_settings.shadow_color = Color(_neon, 0.32)
	_style_all()


# --- building --------------------------------------------------------------


func _build_browse() -> void:
	_browse = UiKit.vbox(8)
	box.add_child(_browse)
	_browse.add_child(_title(tr("MODE_HOCKEY"), 72))
	_browse.add_child(UiKit.label(tr("HOCKEY_SUB"), _body, 26, UiKit.MUTED))
	_browse.add_child(UiKit.spacer(10))

	var name_row := UiKit.center_row(14)
	_browse.add_child(name_row)
	name_row.add_child(UiKit.label(tr("YOUR_NAME"), _body_bold, 24, UiKit.MUTED))
	_name = _line_edit(Vector2(320, 64), Lobby.NAME_MAX)
	_name.text_submitted.connect(func(_text: String) -> void: _commit_name())
	_name.focus_exited.connect(_commit_name)
	name_row.add_child(_name)
	_browse.add_child(UiKit.spacer(8))

	_browse.add_child(UiKit.label(tr("NEARBY_LOBBIES"), _body_bold, 22, UiKit.MUTED))
	_list = UiKit.vbox(10)
	_browse.add_child(_list)
	_none = UiKit.label(tr("NO_LOBBIES"), _body, 22, UiKit.MUTED)
	_none.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_none.custom_minimum_size.x = ROW_W
	_none.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_browse.add_child(_none)
	_browse.add_child(UiKit.spacer(8))

	var code_row := UiKit.center_row(14)
	_browse.add_child(code_row)
	_code = _line_edit(Vector2(220, 72), Lobby.CODE_LENGTH)
	_code.placeholder_text = tr("CODE")
	_code.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_code.text_changed.connect(_on_code_typed)
	_code.text_submitted.connect(func(_text: String) -> void: _on_join_code())
	code_row.add_child(_code)
	_join = _button(tr("JOIN"), Vector2(200, 72), 28, _on_join_code)
	code_row.add_child(_join)
	_browse.add_child(UiKit.spacer(12))

	var row := UiKit.center_row(0)
	_browse.add_child(row)
	_create = _button(tr("CREATE_LOBBY"), Vector2(Hud.BUTTON_W, 96), 34, _on_create)
	row.add_child(_create)


func _build_room() -> void:
	_room = UiKit.vbox(8)
	box.add_child(_room)
	_room.add_child(_title(tr("LOBBY"), 64))
	var code_row := UiKit.center_row(16)
	_room.add_child(code_row)
	code_row.add_child(UiKit.label(tr("CODE"), _body_bold, 24, UiKit.MUTED))
	_room_code = UiKit.label("", _display, 56, UiKit.INK)
	code_row.add_child(_room_code)
	var hint := UiKit.label(tr("ROOM_HINT"), _body, 22, UiKit.MUTED)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.custom_minimum_size.x = ROW_W
	hint.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_room.add_child(hint)
	_room.add_child(UiKit.spacer(14))

	var teams := UiKit.center_row(24)
	_room.add_child(teams)
	for team in 2:
		var column := UiKit.vbox(6)
		column.custom_minimum_size.x = 300
		var color := HockeyView.team_color(team)
		column.add_child(UiKit.label(tr(TEAM_KEYS[team]), _display, 36, color, true))
		teams.add_child(column)
		_teams.append(column)
	_room.add_child(UiKit.spacer(12))

	var switch_row := UiKit.center_row(0)
	_room.add_child(switch_row)
	_switch = _button(tr("SWITCH_TEAM"), Vector2(Hud.BUTTON_W, 72), 28, switch_pressed.emit)
	switch_row.add_child(_switch)
	_host_row = UiKit.center_row(14)
	_room.add_child(_host_row)
	_size = _button("", Vector2(Hud.MODE_BUTTON_W * 1.3, 72), 26, size_pressed.emit)
	_host_row.add_child(_size)
	_goals = _button("", Vector2(Hud.MODE_BUTTON_W * 1.3, 72), 26, goals_pressed.emit)
	_host_row.add_child(_goals)
	_settings = UiKit.label("", _body_bold, 26, UiKit.INK)
	_room.add_child(_settings)
	_room.add_child(UiKit.spacer(10))

	var start_row := UiKit.center_row(0)
	_room.add_child(start_row)
	_start = _button(tr("START"), Vector2(Hud.BUTTON_W, 96), 40, start_pressed.emit)
	start_row.add_child(_start)
	_wait = UiKit.label("", _body, 26, UiKit.INK)
	_room.add_child(_wait)
	var rules := UiKit.label(tr("HOCKEY_RULES"), _body, 22, UiKit.MUTED)
	rules.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rules.custom_minimum_size.x = ROW_W
	rules.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_room.add_child(rules)


func _build_result() -> void:
	_result = UiKit.vbox(10)
	box.add_child(_result)
	_result.add_child(UiKit.spacer(60))
	_result_title = UiKit.label("", _display, 80, UiKit.INK, true)
	_result.add_child(_result_title)
	_result_score = UiKit.label("", _display, 40, UiKit.INK)
	_result.add_child(_result_score)
	_result.add_child(UiKit.spacer(36))
	var row := UiKit.center_row(0)
	_result.add_child(row)
	_rematch = _button(tr("REMATCH"), Vector2(Hud.BUTTON_W, 96), 40, rematch_pressed.emit)
	row.add_child(_rematch)
	_result_hint = UiKit.label(tr("REMATCH_HINT"), _body, 24, UiKit.MUTED)
	_result.add_child(_result_hint)
	_result.add_child(UiKit.spacer(10))
	var lobby_row := UiKit.center_row(0)
	_result.add_child(lobby_row)
	lobby_row.add_child(_button(tr("TO_LOBBY"), Vector2(Hud.BUTTON_W, 72), 28, lobby_pressed.emit))


# --- events ----------------------------------------------------------------


func _show(page: String) -> void:
	_page = page
	_menus.visible = page != "play"
	exit.visible = page == "play"
	_browse.visible = page == "browse"
	_room.visible = page == "room"
	_result.visible = page == "result"
	_back.text = tr("BACK") if page == "browse" else tr("LEAVE")
	_message.text = ""
	_confirm_until = 0
	exit.text = tr("LEAVE")
	get_viewport().gui_release_focus()


func _on_back() -> void:
	if _page == "browse":
		_commit_name()
		back_pressed.emit()
	else:
		leave_pressed.emit()


func _on_create() -> void:
	_commit_name()
	create_pressed.emit()


func _on_lobby(ip: String) -> void:
	_commit_name()
	join_pressed.emit(ip)


func _on_join_code() -> void:
	_commit_name()
	get_viewport().gui_release_focus()
	code_entered.emit(_code.text)


## Codes are in capitals, whatever the keyboard types.
func _on_code_typed(text: String) -> void:
	var up := text.to_upper()
	if up != text:
		var caret := _code.caret_column
		_code.text = up
		_code.caret_column = caret


func _commit_name() -> void:
	var clean := Lobby.clean_name(_name.text)
	_name.text = clean
	name_changed.emit(clean)


## During a match, ESCI asks once more: a stray tap must not end it.
func _on_exit() -> void:
	var now := Time.get_ticks_msec()
	if now < _confirm_until:
		leave_pressed.emit()
		return
	_confirm_until = now + int(CONFIRM_TIME * 1000.0)
	exit.text = tr("LEAVE_SURE")
	get_tree().create_timer(CONFIRM_TIME).timeout.connect(
		func() -> void:
			if Time.get_ticks_msec() >= _confirm_until:
				exit.text = tr("LEAVE")
	)


# --- helpers ---------------------------------------------------------------


func _title(text: String, font_size: int) -> Label:
	var l := UiKit.label(text, _display, font_size, _neon, true)
	_neon_labels.append(l)
	return l


## A button that acts on release: most of them leave the screen they are on.
func _button(text: String, min_size: Vector2, font_size: int, on_press: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = min_size
	b.focus_mode = Control.FOCUS_NONE
	b.action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE
	b.pressed.connect(on_press)
	b.set_meta("font_size", font_size)
	return b


func _line_edit(min_size: Vector2, max_length: int) -> LineEdit:
	var e := LineEdit.new()
	e.custom_minimum_size = min_size
	e.max_length = max_length
	e.add_theme_font_override("font", _body_bold)
	e.add_theme_font_size_override("font_size", 30)
	e.add_theme_color_override("font_color", UiKit.INK)
	e.add_theme_color_override("font_placeholder_color", UiKit.MUTED)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(UiKit.SHADE, 0.8)
	normal.border_color = UiKit.MUTED
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(8)
	normal.set_content_margin_all(12)
	e.add_theme_stylebox_override("normal", normal)
	e.add_theme_stylebox_override("read_only", normal)
	e.set_meta("normal", normal)
	return e


## Buttons: the main ones in the theme colour, the others outlined in grey;
## a button that can't be pressed now is grey.
func _style_all() -> void:
	for b in [_join, _create, _start, _rematch]:
		_style(b, int(b.get_meta("font_size")), UiKit.MUTED if b.disabled else _neon)
	for b in [_back, exit, _switch, _size, _goals]:
		_style(b, int(b.get_meta("font_size")), UiKit.MUTED)
	for e in [_name, _code]:
		var focus := (e.get_meta("normal") as StyleBoxFlat).duplicate() as StyleBoxFlat
		focus.border_color = _neon
		e.add_theme_stylebox_override("focus", focus)
		e.add_theme_color_override("caret_color", _neon)


func _style(b: Button, font_size: int, accent: Color) -> void:
	UiKit.style_button(b, _display, font_size, accent)
	b.add_theme_color_override("font_disabled_color", UiKit.MUTED)
