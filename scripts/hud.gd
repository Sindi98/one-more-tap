class_name Hud
extends CanvasLayer
## On-screen UI, built in code: score, combo, start / game over / pause / continue
## panels, the sound toggle and the privacy links. Panels never block taps; only
## the buttons do.

signal retry_pressed
signal continue_pressed
signal mute_pressed
signal privacy_pressed
signal consent_pressed

const INK := Color("eef2ff")
const MUTED := Color("8a90b8")
const HOT := Color("ff4d6d")
const SHADE := Color("06060c")
const BUTTON_W := 380.0
const BUTTON_PAIR_W := 310.0  ## CONTINUA and RIPROVA side by side

const REASONS := {
	"early": ["TROPPO PRESTO", "Hai girato prima dell'angolo"],
	"late": ["TROPPO TARDI", "Non hai girato all'angolo"],
}

var _display: Font
var _body: Font
var _body_bold: Font
var _neon := Color.from_hsv(188.0 / 360.0, 0.78, 1.0)
var _last_hue := -1000.0
var _neon_labels: Array[Label] = []  ## labels whose colour follows the theme

var _root: Control
var _top: VBoxContainer
var _score: Label
var _best: Label
var _combo: Label
var _mute: Button
var _start: Control
var _start_box: VBoxContainer
var _start_best: Label
var _prompt: Label
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
var _pause: Control
var _pause_box: VBoxContainer
var _revive: Control
var _revive_box: VBoxContainer
var _privacy: Button
var _consent: Button
var _consent_available := false
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
	_build_mute()
	_build_privacy()
	_apply_safe_area()
	get_viewport().size_changed.connect(_apply_safe_area)


# --- public API ------------------------------------------------------------


func show_start(best: int) -> void:
	_start_best.text = "RECORD  %d" % best if best > 0 else "Il primo record è tuo"
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


## A full-screen ad is on top: nothing of ours should show or take taps.
func show_ad() -> void:
	_set_panel(null)
	_top.visible = false


func show_over(
	score: int,
	best: int,
	new_record: bool,
	reason: String,
	platforms: int,
	perfects: int,
	best_combo: int,
	can_continue: bool
) -> void:
	var r: Array = REASONS.get(reason, REASONS["late"])
	_reason.text = r[0]
	_reason_sub.text = r[1]
	_final.text = str(score)
	_record.text = "NUOVO RECORD" if new_record else "RECORD  %d" % best
	_record.label_settings.font_color = _neon if new_record else MUTED
	_stats.text = (
		"%d piattaforme  ·  %d perfetti  ·  combo max %d" % [platforms, perfects, best_combo]
	)
	set_continue_available(can_continue)
	_set_panel(_over)
	_top.visible = false
	_over_box.modulate.a = 0.0
	create_tween().tween_property(_over_box, "modulate:a", 1.0, 0.18)


func set_score(score: int, pop := false) -> void:
	_score.text = str(score)
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
	_best.text = "RECORD %d" % best if best > 0 else ""


func show_combo(combo: int) -> void:
	_combo.text = "PERFETTO  ×%d" % combo if combo >= 2 else "PERFETTO"
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
	_tap_hint.text = "tocca lo schermo per riprovare" if available else "oppure tocca lo schermo"


func set_consent_available(available: bool) -> void:
	_consent_available = available
	_consent.visible = available and _privacy.visible


func set_muted(muted: bool) -> void:
	_mute.text = "SUONO OFF" if muted else "SUONO ON"


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

	var rules_lines := PackedStringArray(
		[
			"Tocca: la pallina cambia direzione.",
			"Gira sugli angoli, mai prima, mai dopo.",
			"Al centro esatto: PERFETTO, +1.",
		]
	)
	var rules_text := "\n".join(rules_lines)
	var rules := _label(rules_text, _body, 30, MUTED)
	_start_box.add_child(rules)
	_start_box.add_child(_spacer(36))

	_prompt = _label("TOCCA PER INIZIARE", _display, 38, _neon, true)
	_neon_labels.append(_prompt)
	_start_box.add_child(_prompt)
	var blink := create_tween().set_loops()
	blink.tween_property(_prompt, "modulate:a", 0.35, 0.7).set_trans(Tween.TRANS_SINE)
	blink.tween_property(_prompt, "modulate:a", 1.0, 0.7).set_trans(Tween.TRANS_SINE)

	_start_box.add_child(_spacer(16))
	_start_best = _label("", _body_bold, 28, INK)
	_start_box.add_child(_start_best)


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
	_over_box.add_child(_spacer(40))

	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 20)
	_over_box.add_child(row)

	_continue = Button.new()
	_continue.text = "CONTINUA"
	_continue.custom_minimum_size = Vector2(BUTTON_PAIR_W, 104)
	_continue.focus_mode = Control.FOCUS_NONE
	_continue.action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE  # same reason as RIPROVA
	_continue.pressed.connect(func() -> void: continue_pressed.emit())
	_style_button(_continue, 40, _neon)
	row.add_child(_continue)

	_retry = Button.new()
	_retry.text = "RIPROVA"
	_retry.custom_minimum_size = Vector2(BUTTON_W, 104)
	_retry.focus_mode = Control.FOCUS_NONE
	# Fires on release on purpose: on press it would hide itself before the
	# matching touch event arrives, and that touch would turn the new ball.
	_retry.action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE
	_retry.pressed.connect(func() -> void: retry_pressed.emit())
	_style_button(_retry, 40, _neon)
	row.add_child(_retry)
	_over_box.add_child(_spacer(6))
	_continue_hint = _label("CONTINUA: guarda un breve video e riparti da qui", _body, 24, INK)
	_over_box.add_child(_continue_hint)
	_tap_hint = _label("oppure tocca lo schermo", _body, 24, MUTED)
	_over_box.add_child(_tap_hint)


func _build_pause() -> void:
	_pause = _panel()
	_pause_box = _vbox(10)
	_pause.add_child(_pause_box)
	_pause_box.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_pause_box.add_child(_label("PAUSA", _display, 88, INK, true))
	_pause_box.add_child(_label("Tocca per riprendere", _body, 30, MUTED))


func _build_revive() -> void:
	_revive = _panel()
	_revive_box = _vbox(10)
	_revive.add_child(_revive_box)
	_revive_box.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	var title := _label("ANCORA UNA", _display, 72, _neon, true)
	_neon_labels.append(title)
	_revive_box.add_child(title)
	_revive_box.add_child(_label("Tocca quando sei pronto", _body, 30, INK))
	_revive_box.add_child(_label("la pallina riparte piano", _body, 26, MUTED))


func _build_mute() -> void:
	_mute = Button.new()
	_mute.text = "SUONO ON"
	_mute.focus_mode = Control.FOCUS_NONE
	_mute.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	_mute.pressed.connect(func() -> void: mute_pressed.emit())
	_style_button(_mute, 20, MUTED)
	_root.add_child(_mute)
	_mute.set_anchors_preset(Control.PRESET_TOP_RIGHT)


## Privacy policy link (required by both stores) and, for players in the EEA/UK,
## the ad consent form. Shown on the menus only, never during a run.
func _build_privacy() -> void:
	_privacy = _small_button("PRIVACY", func() -> void: privacy_pressed.emit())
	_consent = _small_button("CONSENSO", func() -> void: consent_pressed.emit())
	_consent.visible = false


func _apply_safe_area() -> void:
	var inset := _safe_insets()
	# Boxes are anchored to the top edge; they grow downward to fit their content.
	_place_top(_top, 36.0 + inset.y)
	_place_top(_start_box, 110.0 + inset.y)
	_place_top(_over_box, 120.0 + inset.y)
	_place_top(_pause_box, 320.0 + inset.y)
	_place_top(_revive_box, 320.0 + inset.y)
	var w := 190.0
	var h := 60.0
	_mute.offset_right = -20.0 - inset.x
	_mute.offset_left = _mute.offset_right - w
	_mute.offset_top = 20.0 + inset.y
	_mute.offset_bottom = _mute.offset_top + h
	for i in 2:
		var b: Button = [_privacy, _consent][i]
		b.offset_left = 20.0 + inset.z + i * (w + 12.0)
		b.offset_right = b.offset_left + w
		b.offset_top = 20.0 + inset.y
		b.offset_bottom = b.offset_top + h


func _place_top(box: Control, y: float) -> void:
	box.grow_vertical = Control.GROW_DIRECTION_END
	box.offset_top = y
	box.offset_bottom = y


## Safe-area insets (notch, rounded corners) in viewport units:
## x = right, y = top, z = left.
func _safe_insets() -> Vector3:
	if not OS.has_feature("mobile"):
		return Vector3.ZERO
	var win := Vector2(DisplayServer.window_get_size())
	var safe := Rect2(DisplayServer.get_display_safe_area())
	if win.y <= 0.0 or safe.size.y <= 0.0:
		return Vector3.ZERO
	var k := get_viewport().get_visible_rect().size.y / win.y
	return Vector3(
		maxf(0.0, win.x - safe.end.x) * k,
		maxf(0.0, safe.position.y) * k,
		maxf(0.0, safe.position.x) * k
	)


func _set_panel(panel: Control) -> void:
	for p in [_start, _over, _pause, _revive]:
		p.visible = p == panel
	_privacy.visible = panel == _start or panel == _over or panel == _pause
	_consent.visible = _consent_available and _privacy.visible


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
