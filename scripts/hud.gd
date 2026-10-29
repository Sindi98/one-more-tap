class_name Hud
extends CanvasLayer
## On-screen UI, built in code: score, combo, start / game over / pause / continue
## / no lives panels, the mode picker, the lives, the sound toggle, the share
## button, the privacy links and, on the web version, the link to the app.
## Panels never block taps; only the buttons do.

signal retry_pressed
signal continue_pressed
signal mute_pressed
signal privacy_pressed
signal consent_pressed
signal mode_pressed(mode: String)
signal menu_pressed  ## back to the start screen, to pick another mode
signal refill_pressed  ## out of lives: watch a video to get them all back
signal share_pressed  ## game over: send a picture of the run to a friend
signal app_pressed  ## web version: go to the page with the store links

const INK := Color("eef2ff")
const MUTED := Color("8a90b8")
const HOT := Color("ff4d6d")
const SHADE := Color("06060c")
const BUTTON_W := 380.0
const BUTTON_PAIR_W := 310.0  ## CONTINUE and RETRY side by side
const MODE_BUTTON_W := 206.0
const BANNER_GAP := 24.0  ## between the banner and the buttons above it: no accidental taps

## Game modes, in the order of the picker, with their translation keys. Every
## text on screen is a key of assets/i18n/strings.csv, shown in the device's
## language (Italian or English).
const MODE_NAMES := {"zigzag": "MODE_ZIGZAG", "tower": "MODE_TOWER", "runner": "MODE_RUNNER"}
const RULES := {
	"zigzag": ["RULES_ZIGZAG_1", "RULES_ZIGZAG_2", "RULES_ZIGZAG_3"],
	"tower": ["RULES_TOWER_1", "RULES_TOWER_2", "RULES_TOWER_3"],
	"runner": ["RULES_RUNNER_1", "RULES_RUNNER_2", "RULES_RUNNER_3"],
}
const REASONS := {
	"zigzag":
	{
		"early": ["REASON_EARLY", "REASON_ZIGZAG_EARLY"],
		"late": ["REASON_LATE", "REASON_ZIGZAG_LATE"],
	},
	"tower":
	{
		"early": ["REASON_EARLY", "REASON_TOWER_EARLY"],
		"late": ["REASON_LATE", "REASON_TOWER_LATE"],
	},
	"runner":
	{
		"early": ["REASON_EARLY", "REASON_RUNNER_EARLY"],
		"late": ["REASON_LATE", "REASON_RUNNER_LATE"],
		"high": ["REASON_HIGH", "REASON_RUNNER_HIGH"],
	},
}

var _display: Font
var _body: Font
var _body_bold: Font
var _neon := Color.from_hsv(188.0 / 360.0, 0.78, 1.0)
var _last_hue := -1000.0
var _neon_labels: Array[Label] = []  ## labels whose colour follows the theme
var _mode := "zigzag"
var _digits := 0  ## scores are padded with zeros to this many digits
var _banner_h := 0.0  ## height of the ad banner along the bottom edge, 0 if none
var _new_record := false  ## the game over panel on screen shows a new record

var _root: Control
var _top: VBoxContainer
var _score: Label
var _best: Label
var _combo: Label
var _mute: Button
var _start: Control
var _start_box: VBoxContainer
var _start_best: Label
var _start_rules: Label
var _prompt: Label
var _modes: HBoxContainer
var _mode_buttons := {}  ## mode -> Button
var _lives_views: Array[LivesView] = []  ## start, game over and no lives panels
var _over: Control
var _over_box: VBoxContainer
var _reason: Label
var _reason_sub: Label
var _final: Label
var _record: Label
var _stats: Label
var _continue: Button
var _continue_hint: Label
var _retry: Button
var _tap_hint: Label
var _menu_row: HBoxContainer
var _menu: Button
var _share: Button
var _pause: Control
var _pause_box: VBoxContainer
var _revive: Control
var _revive_box: VBoxContainer
var _no_lives: Control
var _no_lives_box: VBoxContainer
var _refill: Button
var _refill_hint: Label
var _no_lives_menu_row: HBoxContainer
var _privacy: Button
var _consent: Button
var _consent_available := false
var _app: Button
var _card: ShareCard
var _combo_tween: Tween
var _score_tween: Tween


func _ready() -> void:
	_display = _font("res://assets/fonts/Bungee-Regular.ttf")
	_body = _font("res://assets/fonts/ChakraPetch-Medium.ttf")
	_body_bold = _font("res://assets/fonts/ChakraPetch-Bold.ttf")

	_root = Control.new()
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_build_top()
	_build_start()
	_build_over()
	_build_pause()
	_build_revive()
	_build_no_lives()
	_build_mute()
	_build_privacy()
	_card = ShareCard.new(_display, _body, _body_bold)
	add_child(_card)
	_apply_safe_area()
	get_viewport().size_changed.connect(_apply_safe_area)


# --- public API ------------------------------------------------------------


func show_start(best: int) -> void:
	_start_best.text = "%s  %d" % [tr("BEST"), best] if best > 0 else tr("FIRST_RECORD")
	_set_panel(_start)
	_top.visible = false


func show_playing() -> void:
	_set_panel(null)
	_top.visible = true


func show_pause() -> void:
	_set_panel(_pause)


## After a rewarded video: the ball is back, waiting for a tap.
func show_revive() -> void:
	_set_panel(_revive)
	_top.visible = false


## Out of lives: watch a video, wait, or go back to the menu.
func show_no_lives(video_ready: bool) -> void:
	set_refill_available(video_ready)
	_set_panel(_no_lives)
	_top.visible = false


func set_refill_available(available: bool) -> void:
	_refill.visible = available
	_refill_hint.text = tr("REFILL_HINT") if available else tr("NO_VIDEO")


## Hearts on the menus. total = 0 hides them (no ads, no lives: unlimited play).
func set_lives(left: int, total: int, wait_seconds: int) -> void:
	for v in _lives_views:
		v.visible = total > 0
		v.set_lives(left, total, wait_seconds)


## The start screen's banner sits along the bottom: lift the mode picker above it.
func set_banner_height(height: float) -> void:
	if absf(height - _banner_h) < 0.5:
		return
	_banner_h = height
	_apply_safe_area()


## A full-screen ad is on top: nothing of ours should show or take taps.
func show_ad() -> void:
	_set_panel(null)
	_top.visible = false


## stats: one line about the run, already worded for the mode. can_share: the
## device can share a picture (see Social).
func show_over(
	score: int,
	best: int,
	new_record: bool,
	reason: String,
	stats: String,
	can_continue: bool,
	can_share: bool
) -> void:
	var reasons: Dictionary = REASONS[_mode]
	var r: Array = reasons.get(reason, reasons["late"])
	_reason.text = tr(r[0])
	_reason_sub.text = tr(r[1])
	_final.text = _format(score)
	_record.text = tr("NEW_RECORD") if new_record else "%s  %d" % [tr("BEST"), best]
	_record.label_settings.font_color = _neon if new_record else MUTED
	_new_record = new_record
	_stats.text = stats
	_share.visible = can_share
	set_continue_available(can_continue)
	_set_panel(_over)
	_top.visible = false
	_over_box.modulate.a = 0.0
	create_tween().tween_property(_over_box, "modulate:a", 1.0, 0.18)


## Rules on the start screen, reasons on the game over panel, score digits and
## the highlighted button of the picker all follow the mode.
func set_mode(mode: String) -> void:
	_mode = mode
	var rules := PackedStringArray()
	for key in RULES[mode]:
		rules.append(tr(key))
	_start_rules.text = "\n".join(rules)
	_digits = 5 if mode == "runner" else 0  # like the offline game's counter
	_score.label_settings.font_size = 84 if _digits > 0 else 120
	_final.label_settings.font_size = 128 if _digits > 0 else 168
	_style_mode_buttons()


func set_score(score: int, pop := false) -> void:
	_score.text = _format(score)
	if pop:
		_score.pivot_offset = _score.size * 0.5
		if _score_tween:
			_score_tween.kill()
		_score.scale = Vector2(1.16, 1.16)
		_score_tween = create_tween()
		# Explicit start value: the VBox resets child scale when it re-sorts
		# (the label width changes with the digits), which would flatten the pop.
		var pt := _score_tween.tween_property(_score, "scale", Vector2.ONE, 0.14)
		pt.from(Vector2(1.16, 1.16)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func set_best(best: int) -> void:
	_best.text = "%s %d" % [tr("BEST"), best] if best > 0 else ""


func show_combo(combo: int) -> void:
	_combo.text = "%s  ×%d" % [tr("PERFECT"), combo] if combo >= 2 else tr("PERFECT")
	if _combo_tween:
		_combo_tween.kill()
	_combo.modulate.a = 1.0
	_combo_tween = create_tween()
	_combo_tween.tween_interval(0.45)
	_combo_tween.tween_property(_combo, "modulate:a", 0.0, 0.5)


func hide_combo() -> void:
	if _combo_tween:
		_combo_tween.kill()
	_combo.modulate.a = 0.0


## The continue offer appears only while a rewarded video is ready.
func set_continue_available(available: bool) -> void:
	_continue.visible = available
	_continue_hint.visible = available
	_retry.custom_minimum_size.x = BUTTON_PAIR_W if available else BUTTON_W
	_tap_hint.text = tr("TAP_TO_RETRY") if available else tr("OR_TAP")


func set_consent_available(available: bool) -> void:
	_consent_available = available
	_consent.visible = available and _privacy.visible


## A picture of the run on the game over panel: the world around `center`
## with the mode, the score and the record on top (see ShareCard).
func share_image(world: World2D, center: Vector2) -> Image:
	var view := get_viewport().get_visible_rect().size
	var mode_name := tr(MODE_NAMES[_mode])
	return await _card.render(
		world, center, view, _neon, mode_name, _final.text, _record.text, _new_record
	)


func set_muted(muted: bool) -> void:
	_mute.text = tr("SOUND_OFF") if muted else tr("SOUND_ON")


## Theme colour follows the track (it shifts every few points).
func set_hue(hue: float) -> void:
	if absf(hue - _last_hue) < 1.0:
		return
	_last_hue = hue
	_neon = Color.from_hsv(hue / 360.0, 0.78, 1.0)
	for l in _neon_labels:
		l.label_settings.font_color = _neon
		l.label_settings.shadow_color = Color(_neon, 0.32)
	_score.label_settings.shadow_color = Color(_neon, 0.4)
	_style_button(_retry, 40, _neon)
	_style_button(_continue, 40, _neon)
	_style_button(_refill, 40, _neon)
	_style_mode_buttons()
	for v in _lives_views:
		v.color = _neon
		v.queue_redraw()


# --- building --------------------------------------------------------------


func _build_top() -> void:
	_top = _vbox(0)
	_top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_root.add_child(_top)
	_score = _label("0", _display, 120, INK, true)
	_best = _label("", _body, 26, MUTED)
	_combo = _label("", _display, 30, _neon, true)
	_combo.modulate.a = 0.0
	_neon_labels.append(_combo)
	_top.add_child(_score)
	_top.add_child(_best)
	_top.add_child(_combo)


func _build_start() -> void:
	_start = _panel()
	_start_box = _vbox(4)
	_start.add_child(_start_box)
	_start_box.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)

	_start_box.add_child(_label("ONE", _display, 104, INK))
	_start_box.add_child(_label("MORE", _display, 104, INK))
	var tap := _label("TAP", _display, 104, _neon, true)
	_neon_labels.append(tap)
	_start_box.add_child(tap)
	_start_box.add_child(_spacer(28))

	_start_rules = _label("", _body, 30, MUTED)
	_start_box.add_child(_start_rules)
	_start_box.add_child(_spacer(36))

	_prompt = _label(tr("TAP_TO_START"), _display, 38, _neon, true)
	_neon_labels.append(_prompt)
	_start_box.add_child(_prompt)
	var blink := create_tween().set_loops()
	blink.tween_property(_prompt, "modulate:a", 0.35, 0.7).set_trans(Tween.TRANS_SINE)
	blink.tween_property(_prompt, "modulate:a", 1.0, 0.7).set_trans(Tween.TRANS_SINE)

	_start_box.add_child(_spacer(16))
	_start_best = _label("", _body_bold, 28, INK)
	_start_box.add_child(_start_best)
	_start_box.add_child(_spacer(10))
	_start_box.add_child(_lives_view())

	# Mode picker, low on the screen where the thumb is. Switching does not
	# hide anything, so it can act on press.
	_modes = _bottom_row(_start)
	for mode in MODE_NAMES:
		var b := Button.new()
		b.text = tr(MODE_NAMES[mode])
		b.custom_minimum_size = Vector2(MODE_BUTTON_W, 84)
		b.focus_mode = Control.FOCUS_NONE
		b.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
		b.pressed.connect(func() -> void: mode_pressed.emit(mode))
		_modes.add_child(b)
		_mode_buttons[mode] = b
	_style_mode_buttons()


func _build_over() -> void:
	_over = _panel()
	_over_box = _vbox(6)
	_over.add_child(_over_box)
	_over_box.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)

	_reason = _label("", _display, 44, HOT, true)
	_reason.label_settings.shadow_color = Color(HOT, 0.3)
	_reason_sub = _label("", _body, 30, INK)
	_final = _label("0", _display, 168, INK, true)
	_record = _label("", _body_bold, 30, MUTED)
	_stats = _label("", _body, 24, MUTED)
	_over_box.add_child(_reason)
	_over_box.add_child(_reason_sub)
	_over_box.add_child(_spacer(12))
	_over_box.add_child(_final)
	_over_box.add_child(_record)
	_over_box.add_child(_stats)
	_over_box.add_child(_spacer(10))
	_over_box.add_child(_lives_view())
	_over_box.add_child(_spacer(30))

	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 20)
	_over_box.add_child(row)

	_continue = Button.new()
	_continue.text = tr("CONTINUE")
	_continue.custom_minimum_size = Vector2(BUTTON_PAIR_W, 104)
	_continue.focus_mode = Control.FOCUS_NONE
	_continue.action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE  # same reason as RETRY
	_continue.pressed.connect(func() -> void: continue_pressed.emit())
	_style_button(_continue, 40, _neon)
	row.add_child(_continue)

	_retry = Button.new()
	_retry.text = tr("RETRY")
	_retry.custom_minimum_size = Vector2(BUTTON_W, 104)
	_retry.focus_mode = Control.FOCUS_NONE
	# Fires on release on purpose: on press it would hide itself before the
	# matching touch event arrives, and that touch would turn the new ball.
	_retry.action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE
	_retry.pressed.connect(func() -> void: retry_pressed.emit())
	_style_button(_retry, 40, _neon)
	row.add_child(_retry)
	_over_box.add_child(_spacer(6))
	_continue_hint = _label(tr("CONTINUE_HINT"), _body, 24, INK)
	_over_box.add_child(_continue_hint)
	_tap_hint = _label(tr("OR_TAP"), _body, 24, MUTED)
	_over_box.add_child(_tap_hint)

	_menu_row = _bottom_row(_over)
	_menu = Button.new()
	_menu.text = tr("MODES")
	_menu.custom_minimum_size = Vector2(MODE_BUTTON_W * 1.3, 72)
	_menu.focus_mode = Control.FOCUS_NONE
	_menu.action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE  # same reason as RETRY
	_menu.pressed.connect(func() -> void: menu_pressed.emit())
	_style_button(_menu, 26, MUTED)
	_menu_row.add_child(_menu)

	_share = Button.new()
	_share.text = tr("SHARE")
	_share.custom_minimum_size = Vector2(MODE_BUTTON_W * 1.3, 72)
	_share.focus_mode = Control.FOCUS_NONE
	_share.action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE  # the share sheet goes on top
	_share.pressed.connect(func() -> void: share_pressed.emit())
	_style_button(_share, 26, MUTED)
	_menu_row.add_child(_share)


func _build_pause() -> void:
	_pause = _panel()
	_pause_box = _vbox(10)
	_pause.add_child(_pause_box)
	_pause_box.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_pause_box.add_child(_label(tr("PAUSED"), _display, 88, INK, true))
	_pause_box.add_child(_label(tr("TAP_TO_RESUME"), _body, 30, MUTED))


func _build_revive() -> void:
	_revive = _panel()
	_revive_box = _vbox(10)
	_revive.add_child(_revive_box)
	_revive_box.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	var title := _label(tr("ONE_MORE"), _display, 72, _neon, true)
	_neon_labels.append(title)
	_revive_box.add_child(title)
	_revive_box.add_child(_label(tr("TAP_WHEN_READY"), _body, 30, INK))
	_revive_box.add_child(_label(tr("STARTS_SLOW"), _body, 26, MUTED))


func _build_no_lives() -> void:
	_no_lives = _panel()
	_no_lives_box = _vbox(10)
	_no_lives.add_child(_no_lives_box)
	_no_lives_box.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	var title := _label(tr("NO_LIVES"), _display, 72, HOT, true)
	title.label_settings.shadow_color = Color(HOT, 0.3)
	_no_lives_box.add_child(title)
	_no_lives_box.add_child(_spacer(8))
	_no_lives_box.add_child(_lives_view())
	_no_lives_box.add_child(_spacer(36))
	_refill = Button.new()
	_refill.text = tr("REFILL")
	_refill.custom_minimum_size = Vector2(BUTTON_W, 104)
	_refill.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_refill.focus_mode = Control.FOCUS_NONE
	_refill.action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE  # a video goes on top
	_refill.pressed.connect(func() -> void: refill_pressed.emit())
	_style_button(_refill, 40, _neon)
	_no_lives_box.add_child(_refill)
	_no_lives_box.add_child(_spacer(6))
	_refill_hint = _label("", _body, 26, INK)
	_no_lives_box.add_child(_refill_hint)
	_no_lives_box.add_child(_label(tr("WAIT_FOR_LIVES"), _body, 24, MUTED))
	_no_lives_menu_row = _bottom_row(_no_lives)
	var menu := Button.new()
	menu.text = tr("MODES")
	menu.custom_minimum_size = Vector2(MODE_BUTTON_W * 1.3, 72)
	menu.focus_mode = Control.FOCUS_NONE
	menu.action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE
	menu.pressed.connect(func() -> void: menu_pressed.emit())
	_style_button(menu, 26, MUTED)
	_no_lives_menu_row.add_child(menu)


func _build_mute() -> void:
	_mute = Button.new()
	_mute.text = tr("SOUND_ON")
	_mute.focus_mode = Control.FOCUS_NONE
	_mute.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	_mute.pressed.connect(func() -> void: mute_pressed.emit())
	_style_button(_mute, 20, MUTED)
	_root.add_child(_mute)
	_mute.set_anchors_preset(Control.PRESET_TOP_RIGHT)


## Privacy policy link (required by both stores), for players in the EEA/UK the
## ad consent form and, on the web version, the way to the app. Shown on the
## menus only, never during a run.
func _build_privacy() -> void:
	_privacy = _small_button(tr("PRIVACY"), func() -> void: privacy_pressed.emit())
	_consent = _small_button(tr("CONSENT"), func() -> void: consent_pressed.emit())
	_consent.visible = false
	_app = _small_button(tr("GET_APP"), func() -> void: app_pressed.emit())
	_app.visible = false


func _apply_safe_area() -> void:
	var inset := _safe_insets()
	# Boxes are anchored to the top edge; they grow downward to fit their content.
	_place_top(_top, 36.0 + inset.y)
	_place_top(_start_box, 110.0 + inset.y)
	_place_top(_over_box, 120.0 + inset.y)
	_place_top(_pause_box, 320.0 + inset.y)
	_place_top(_revive_box, 320.0 + inset.y)
	_place_top(_no_lives_box, 220.0 + inset.y)
	var banner := _banner_h + BANNER_GAP if _banner_h > 0.0 else 0.0
	_place_bottom(_modes, 44.0 + inset.w + banner)
	_place_bottom(_menu_row, 44.0 + inset.w)
	_place_bottom(_no_lives_menu_row, 44.0 + inset.w)
	var w := 190.0
	var h := 60.0
	_mute.offset_right = -20.0 - inset.x
	_mute.offset_left = _mute.offset_right - w
	_mute.offset_top = 20.0 + inset.y
	_mute.offset_bottom = _mute.offset_top + h
	# The consent form (ads) and the app link (web version) never show together.
	for slot in [[_privacy, 0], [_consent, 1], [_app, 1]]:
		var b: Button = slot[0]
		b.offset_left = 20.0 + inset.z + slot[1] * (w + 12.0)
		b.offset_right = b.offset_left + w
		b.offset_top = 20.0 + inset.y
		b.offset_bottom = b.offset_top + h


func _place_top(box: Control, y: float) -> void:
	box.grow_vertical = Control.GROW_DIRECTION_END
	box.offset_top = y
	box.offset_bottom = y


## Rows anchored to the bottom edge grow upward to fit their content.
func _place_bottom(box: Control, y: float) -> void:
	box.grow_vertical = Control.GROW_DIRECTION_BEGIN
	box.offset_top = -y
	box.offset_bottom = -y


## Safe-area insets (notch, rounded corners, home bar) in viewport units:
## x = right, y = top, z = left, w = bottom.
func _safe_insets() -> Vector4:
	if not OS.has_feature("mobile"):
		return Vector4.ZERO
	var win := Vector2(DisplayServer.window_get_size())
	var safe := Rect2(DisplayServer.get_display_safe_area())
	if win.y <= 0.0 or safe.size.y <= 0.0:
		return Vector4.ZERO
	var k := get_viewport().get_visible_rect().size.y / win.y
	return Vector4(
		maxf(0.0, win.x - safe.end.x) * k,
		maxf(0.0, safe.position.y) * k,
		maxf(0.0, safe.position.x) * k,
		maxf(0.0, win.y - safe.end.y) * k
	)


func _set_panel(panel: Control) -> void:
	for p in [_start, _over, _pause, _revive, _no_lives]:
		p.visible = p == panel
	_privacy.visible = panel == _start or panel == _over or panel == _pause
	_consent.visible = _consent_available and _privacy.visible
	_app.visible = OS.has_feature("web") and _privacy.visible  # the web version leads to the app


# --- helpers ---------------------------------------------------------------


func _font(path: String) -> Font:
	var f: Font = load(path)
	return f if f else ThemeDB.fallback_font


func _label(text: String, font: Font, size: int, color: Color, glow := false) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ls := LabelSettings.new()
	ls.font = font
	ls.font_size = size
	ls.font_color = color
	ls.line_spacing = 2.0
	if glow:
		ls.shadow_size = 18
		ls.shadow_color = Color(color, 0.32)
		ls.shadow_offset = Vector2.ZERO
	l.label_settings = ls
	return l


## Small corner button, styled like the sound toggle.
func _small_button(text: String, on_press: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE  # it opens a page on top
	b.pressed.connect(on_press)
	_style_button(b, 20, MUTED)
	_root.add_child(b)
	b.set_anchors_preset(Control.PRESET_TOP_LEFT)
	return b


## A centred row of buttons along the bottom of a panel.
func _bottom_row(panel: Control) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 14)
	panel.add_child(row)
	row.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	return row


## The chosen mode is a filled button, the others are outlined.
func _style_mode_buttons() -> void:
	for mode in _mode_buttons:
		var b: Button = _mode_buttons[mode]
		if mode == _mode:
			_style_button(b, 30, _neon)
			var on := b.get_theme_stylebox("normal").duplicate() as StyleBoxFlat
			on.bg_color = _neon
			for state in ["normal", "hover", "focus", "pressed", "disabled"]:
				b.add_theme_stylebox_override(state, on)
			for state in [
				"font_color", "font_hover_color", "font_focus_color", "font_pressed_color"
			]:
				b.add_theme_color_override(state, SHADE)
		else:
			_style_button(b, 30, MUTED)


func _lives_view() -> LivesView:
	var v := LivesView.new()
	v.font = _body_bold
	v.color = _neon
	v.text_color = MUTED
	v.visible = false
	_lives_views.append(v)
	return v


func _format(score: int) -> String:
	return str(score).pad_zeros(_digits)


func _vbox(separation: int) -> VBoxContainer:
	var b := VBoxContainer.new()
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_theme_constant_override("separation", separation)
	return b


func _spacer(height: float) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, height)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


## Full-screen panel with a shade that is dark at the top and clear at the
## bottom, so the ball and the miss marker stay visible under the text.
func _panel() -> Control:
	var panel := Control.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.visible = false
	_root.add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.45, 0.66])
	g.colors = PackedColorArray([Color(SHADE, 0.94), Color(SHADE, 0.8), Color(SHADE, 0.0)])
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill_from = Vector2(0, 0)
	tex.fill_to = Vector2(0, 1)
	tex.width = 4
	tex.height = 256
	var shade := TextureRect.new()
	shade.texture = tex
	shade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	shade.stretch_mode = TextureRect.STRETCH_SCALE
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return panel


func _style_button(b: Button, font_size: int, accent: Color) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(SHADE, 0.7)
	normal.border_color = accent
	normal.set_border_width_all(3)
	normal.set_corner_radius_all(8)
	normal.set_content_margin_all(14)
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color(accent, 0.28)
	for state in ["normal", "hover", "focus", "disabled"]:
		b.add_theme_stylebox_override(state, normal)
	b.add_theme_stylebox_override("pressed", pressed)
	b.add_theme_font_override("font", _display)
	b.add_theme_font_size_override("font_size", font_size)
	for state in ["font_color", "font_hover_color", "font_focus_color"]:
		b.add_theme_color_override(state, accent)
	b.add_theme_color_override("font_pressed_color", INK)
