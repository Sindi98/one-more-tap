class_name InfoPanel
extends Control
## INFO, built in code: who makes the game and how to reach them, the privacy
## policy and the terms of use (pages on the game's site), the credits and the
## licenses of everything made by others that ships inside the game: the
## engine and its parts, the plugins, the fonts. Those licenses ask for their
## notice to reach the player, and this is where it does. Hud shows it; texts
## are keys of assets/i18n/strings.csv.

signal closed
signal privacy_pressed
signal terms_pressed

## Who makes the game. The same data is on the game's pages (docs/): fill in
## both before publishing (see LEGALE.md).
const DEVELOPER := "[NOME E COGNOME DELLO SVILUPPATORE]"
const CONTACT := "[EMAIL DI CONTATTO]"
const YEAR := "2026"
const WIDTH := 640.0
## Authors of the tracks in assets/music (see the README), from Pixabay.
const MUSIC_AUTHORS := "GR0ZA, alex-morgan, QubeSounds, AtlasAudio, Serhii_Kliets, White_Records"
## What ships inside the game besides the engine: name, copyright, license.
## The full license texts are the engine's, which uses the same ones.
const NOTICES := [
	["Bungee", "2023 The Bungee Project Authors (github.com/djrrb/Bungee)", "OFL-1.1"],
	[
		"Chakra Petch",
		"2018 The Chakra Petch Project Authors (github.com/m4rc1e/Chakra-Petch)",
		"OFL-1.1"
	],
	["Godot AdMob Plugin", "2020-present Poing Studios", "Expat"],
	["godot-iap (OpenIAP)", "2025 hyo.dev", "Expat"],
	["SwiftGodotRuntime", "2020-2024 Miguel de Icaza", "Expat"],
	["Share, In-App Review", "2025 Godot Mobile Plugins", "Expat"],
	["AndroidX", "The Android Open Source Project", "Apache-2.0"],
	["Kotlin, kotlinx.coroutines", "JetBrains s.r.o. and Kotlin contributors", "Apache-2.0"],
]

var box: VBoxContainer  ## from under the safe area down to the back button, placed by Hud

var _display := UiKit.load_font(UiKit.DISPLAY_FONT)
var _body := UiKit.load_font(UiKit.BODY_FONT)
var _body_bold := UiKit.load_font(UiKit.BODY_BOLD_FONT)
var _neon := Color.from_hsv(188.0 / 360.0, 0.78, 1.0)
var _neon_labels: Array[Label] = []
var _scroll: ScrollContainer
var _list: VBoxContainer  ## credits and licenses, filled the first time the panel opens


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# Long text from top to bottom: a plain dark shade, not the other panels' fade.
	var shade := ColorRect.new()
	shade.color = Color(UiKit.SHADE, 0.94)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	box = UiKit.vbox(8)
	add_child(box)
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var title := UiKit.label(tr("INFO"), _display, 72, _neon, true)
	_neon_labels.append(title)
	box.add_child(title)
	var version: String = ProjectSettings.get_setting("application/config/version", "")
	box.add_child(UiKit.label("ONE MORE TAP %s" % version, _body_bold, 24, UiKit.INK))
	box.add_child(UiKit.label("© %s %s" % [YEAR, DEVELOPER], _body, 24, UiKit.MUTED))
	box.add_child(UiKit.label(tr("CONTACT") % CONTACT, _body, 24, UiKit.MUTED))
	box.add_child(UiKit.spacer(6))

	var links := UiKit.center_row(14)
	box.add_child(links)
	links.add_child(_wide_button(tr("PRIVACY"), privacy_pressed.emit))
	links.add_child(_wide_button(tr("TERMS"), terms_pressed.emit))
	box.add_child(UiKit.spacer(6))

	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.custom_minimum_size.x = WIDTH
	_scroll.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(_scroll)
	_list = UiKit.vbox(6)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(_list)

	box.add_child(UiKit.spacer(6))
	var bottom := UiKit.center_row(0)
	box.add_child(bottom)
	bottom.add_child(_wide_button(tr("BACK"), closed.emit))

	visibility_changed.connect(_on_visibility_changed)


## The theme colour changed (it follows the look worn).
func set_neon(color: Color) -> void:
	_neon = color
	for l in _neon_labels:
		l.label_settings.font_color = _neon
		l.label_settings.shadow_color = Color(_neon, 0.32)


func _on_visibility_changed() -> void:
	if not visible:
		return
	if _list.get_child_count() == 0:
		_fill()  # a lot of text: only for those who open the panel
	_scroll.scroll_vertical = 0


func _fill() -> void:
	_heading(tr("CREDITS"))
	_paragraph(tr("CREDITS_ENGINE"))
	_paragraph(tr("CREDITS_FONTS"))
	_paragraph(tr("CREDITS_MUSIC") % MUSIC_AUTHORS)

	_heading(tr("LICENSES"))
	_paragraph(tr("LICENSES_INTRO"))
	_notice("Godot Engine", _reflow(Engine.get_license_text()))
	_notice("FreeType", _freetype_credit())
	for n: Array in NOTICES:
		_notice(n[0], "© %s\n%s" % [n[1], tr("LICENSE_OF") % n[2]])

	_heading(tr("ENGINE_PARTS"))
	for component: Dictionary in Engine.get_copyright_info():
		var lines := PackedStringArray()
		for part: Dictionary in component["parts"]:
			for holder: String in part["copyright"]:
				lines.append("© " + holder)
			lines.append(tr("LICENSE_OF") % part["license"])
		_notice(component["name"], "\n".join(lines))

	_heading(tr("LICENSE_TEXTS"))
	var texts := Engine.get_license_info()
	for license: String in texts:
		_notice(license, _reflow(texts[license]))


## The statement FreeType's license asks for, with the years of the version
## inside the engine.
func _freetype_credit() -> String:
	var years := ""
	for component: Dictionary in Engine.get_copyright_info():
		if "FreeType" in str(component["name"]):
			var owners: Array = component["parts"][0]["copyright"]
			if not owners.is_empty():
				years = str(owners[0]).get_slice(",", 0).strip_edges() + " "
	var credit := "Portions of this software are copyright © %sThe FreeType Project" % years
	return credit + " (www.freetype.org). All rights reserved."


func _heading(text: String) -> void:
	_list.add_child(UiKit.spacer(14))
	var l := UiKit.label(text, _display, 32, _neon, true)
	_neon_labels.append(l)
	_list.add_child(l)


func _paragraph(text: String) -> void:
	var l := UiKit.label(text, _body, 22, UiKit.INK)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_list.add_child(l)


## A name and its notice, left-aligned: some of them are long.
func _notice(title: String, text: String) -> void:
	var t := UiKit.label(title, _body_bold, 22, UiKit.INK)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_list.add_child(t)
	var l := UiKit.label(text, _body, 18, UiKit.MUTED)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_list.add_child(l)
	_list.add_child(UiKit.spacer(8))


## License texts come wrapped at about 80 columns: wrap them to the screen
## instead, keeping the paragraphs.
static func _reflow(text: String) -> String:
	var paragraphs := PackedStringArray()
	for p in text.strip_edges().split("\n\n"):
		var lines := PackedStringArray()
		for line in p.split("\n"):
			lines.append(line.strip_edges())
		paragraphs.append(" ".join(lines))
	return "\n\n".join(paragraphs)


## A wide outlined button, acting on release: like the shop's.
func _wide_button(text: String, on_press: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(Hud.MODE_BUTTON_W * 1.3, 72)
	b.focus_mode = Control.FOCUS_NONE
	b.action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE
	b.pressed.connect(on_press)
	UiKit.style_button(b, _display, 26, UiKit.MUTED)
	return b
