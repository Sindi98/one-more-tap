class_name ShareCard
extends SubViewport
## The picture a player shares from the game over panel: the game world as it
## is on screen (track, ball, the marker of the miss) with the game's name, the
## mode, the score and the record on top, and a challenge at the bottom.
## Rendered off screen and sharper than the screen (WIDTH pixels wide), so
## nothing flickers when the player taps SHARE.

const WIDTH := 1080

var _camera := Camera2D.new()
var _neon_labels: Array[Label] = []  ## labels whose colour follows the theme
var _mode: Label
var _score: Label
var _record: Label


func _init(display: Font, body: Font, body_bold: Font) -> void:
	disable_3d = true
	render_target_update_mode = SubViewport.UPDATE_DISABLED
	size_2d_override_stretch = true  # lay out in game units, render at WIDTH pixels
	add_child(_camera)

	var layer := CanvasLayer.new()
	add_child(layer)
	var root := Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(_shade(0.0, 0.58, true))
	root.add_child(_shade(0.8, 1.0, false))

	var top := _vbox(4)
	root.add_child(top)
	top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top.grow_vertical = Control.GROW_DIRECTION_END
	top.offset_top = 84.0
	top.offset_bottom = 84.0
	var title := HBoxContainer.new()
	title.alignment = BoxContainer.ALIGNMENT_CENTER
	title.add_theme_constant_override("separation", 18)
	title.add_child(_label("ONE MORE", display, 52, Hud.INK))
	var tap := _label("TAP", display, 52, Hud.INK, true)
	_neon_labels.append(tap)
	title.add_child(tap)
	top.add_child(title)
	top.add_child(_spacer(36))
	_mode = _label("", display, 36, Hud.MUTED)
	top.add_child(_mode)
	_score = _label("", display, 168, Hud.INK, true)
	top.add_child(_score)
	_record = _label("", body_bold, 32, Hud.MUTED)
	top.add_child(_record)

	var bottom := _vbox(6)
	root.add_child(bottom)
	bottom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.grow_vertical = Control.GROW_DIRECTION_BEGIN
	bottom.offset_top = -64.0
	bottom.offset_bottom = -64.0
	var challenge := _label(tr("CARD_CHALLENGE"), display, 42, Hud.INK, true)
	_neon_labels.append(challenge)
	bottom.add_child(challenge)
	bottom.add_child(_label(tr("CARD_FREE"), body, 26, Hud.INK))


## Renders the card and returns the picture. `view` is the size of the screen in
## game units and `center` the camera position: the card frames the same world.
func render(
	world: World2D,
	center: Vector2,
	view: Vector2,
	neon: Color,
	mode_name: String,
	score: String,
	record: String,
	new_record: bool
) -> Image:
	world_2d = world
	size_2d_override = Vector2i(view.round())
	size = Vector2i(WIDTH, roundi(WIDTH * view.y / view.x))
	_camera.position = center
	_camera.make_current()
	_mode.text = mode_name
	_score.text = score
	_score.label_settings.font_size = 168 if score.length() <= 3 else 128
	_score.label_settings.shadow_color = Color(neon, 0.4)
	_record.text = record
	_record.label_settings.font_color = neon if new_record else Hud.MUTED
	for l in _neon_labels:
		l.label_settings.font_color = neon
		l.label_settings.shadow_color = Color(neon, 0.32)
	render_target_update_mode = SubViewport.UPDATE_ONCE
	await RenderingServer.frame_post_draw
	return get_texture().get_image()


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


func _vbox(separation: int) -> VBoxContainer:
	var b := VBoxContainer.new()
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_theme_constant_override("separation", separation)
	return b


func _spacer(height: float) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, height)
	return c


## A dark band between two heights (fractions of the card), solid at the outer
## edge and clear toward the middle, so the text reads over the world.
func _shade(from: float, to: float, dark_on_top: bool) -> TextureRect:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	g.colors = PackedColorArray(
		[Color(Hud.SHADE, 0.94), Color(Hud.SHADE, 0.78), Color(Hud.SHADE, 0.0)]
	)
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill_from = Vector2(0, 0) if dark_on_top else Vector2(0, 1)
	tex.fill_to = Vector2(0, 1) if dark_on_top else Vector2(0, 0)
	tex.width = 4
	tex.height = 256
	var shade := TextureRect.new()
	shade.texture = tex
	shade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	shade.stretch_mode = TextureRect.STRETCH_SCALE
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shade.anchor_left = 0.0
	shade.anchor_right = 1.0
	shade.anchor_top = from
	shade.anchor_bottom = to
	return shade
