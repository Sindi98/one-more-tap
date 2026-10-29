class_name UiKit
extends RefCounted
## Building blocks of the UI, shared by Hud and ShopPanel: colours, fonts,
## labels, buttons, boxes and the shaded full-screen panel, all built in code.

const INK := Color("eef2ff")
const MUTED := Color("8a90b8")
const HOT := Color("ff4d6d")
const SHADE := Color("06060c")
const DISPLAY_FONT := "res://assets/fonts/Bungee-Regular.ttf"
const BODY_FONT := "res://assets/fonts/ChakraPetch-Medium.ttf"
const BODY_BOLD_FONT := "res://assets/fonts/ChakraPetch-Bold.ttf"


static func load_font(path: String) -> Font:
	var f: Font = load(path)
	return f if f else ThemeDB.fallback_font


static func label(text: String, font: Font, size: int, color: Color, glow := false) -> Label:
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


static func vbox(separation: int) -> VBoxContainer:
	var b := VBoxContainer.new()
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_theme_constant_override("separation", separation)
	return b


static func spacer(height: float) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, height)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


## A centred row, to be placed in a box.
static func center_row(separation: int) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", separation)
	return row


## A centred row of buttons along the bottom of a panel.
static func bottom_row(panel: Control) -> HBoxContainer:
	var row := center_row(14)
	panel.add_child(row)
	row.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	return row


## Full-screen panel, hidden, added to `parent`. See shade().
static func panel(parent: Control) -> Control:
	var p := Control.new()
	parent.add_child(p)
	shade(p)
	return p


## Makes `p` a full-screen panel with a shade that is dark at the top and clear
## at the bottom, so the ball and the miss marker stay visible under the text.
## Panels never block taps; only their buttons do.
static func shade(p: Control) -> void:
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.visible = false
	p.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.45, 0.66])
	g.colors = PackedColorArray([Color(SHADE, 0.94), Color(SHADE, 0.8), Color(SHADE, 0.0)])
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill_from = Vector2(0, 0)
	tex.fill_to = Vector2(0, 1)
	tex.width = 4
	tex.height = 256
	var rect := TextureRect.new()
	rect.texture = tex
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(rect)
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


static func style_button(b: Button, font: Font, font_size: int, accent: Color) -> void:
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
	b.add_theme_font_override("font", font)
	b.add_theme_font_size_override("font_size", font_size)
	for state in ["font_color", "font_hover_color", "font_focus_color"]:
		b.add_theme_color_override(state, accent)
	b.add_theme_color_override("font_pressed_color", INK)


## The chosen button of a picker (modes, shop tabs) is filled with `accent`,
## the others are outlined.
static func style_picker(
	buttons: Dictionary, chosen: String, font: Font, font_size: int, accent: Color
) -> void:
	for key in buttons:
		var b: Button = buttons[key]
		if key == chosen:
			style_button(b, font, font_size, accent)
			var on := b.get_theme_stylebox("normal").duplicate() as StyleBoxFlat
			on.bg_color = accent
			for state in ["normal", "hover", "focus", "pressed", "disabled"]:
				b.add_theme_stylebox_override(state, on)
			for state in [
				"font_color", "font_hover_color", "font_focus_color", "font_pressed_color"
			]:
				b.add_theme_color_override(state, SHADE)
		else:
			style_button(b, font, font_size, MUTED)
