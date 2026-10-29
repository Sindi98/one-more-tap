class_name ShopPanel
extends Control
## The shop, built in code: tabs of looks and extras, a card for each with its
## rarity and price, the big button that buys or puts on the card picked, back
## and restore. Hud shows it; what is on sale and owned comes from Shop. Texts
## are keys of assets/i18n/strings.csv.

signal closed
signal look_previewed(id: String)  ## a card was picked: show its look, owned or not
signal wear_pressed(id: String)
signal buy_pressed(id: String)
signal restore_pressed

const CARD_SIZE := Vector2(330, 108)
const CARD_ROWS := 4  ## the grid keeps the height of the longest tab
const TABS := {"colors": "TAB_COLORS", "ball": "TAB_BALL", "extra": "TAB_EXTRA"}
## Extras on their cards: a short name, a line instead of the rarity, and the
## colour of the rarity their price matches.
const EXTRA_CARDS := {
	"no_ads": ["CARD_NO_ADS", "TAG_FOREVER", "epic"],
	"collection": ["CARD_COLLECTION", "TAG_ALL_STYLES", "legendary"],
	"tokens_10": ["CARD_TOKENS", "TAG_FOR_CONTINUE", "rare"],
	"tokens_30": ["CARD_TOKENS", "TAG_FOR_CONTINUE", "rare"],
	"tokens_100": ["CARD_TOKENS", "TAG_FOR_CONTINUE", "rare"],
}

var box: VBoxContainer  ## the panel's content, placed by Hud under the safe area
var bottom: HBoxContainer  ## back and restore, placed by Hud

var _display := UiKit.load_font(UiKit.DISPLAY_FONT)
var _body := UiKit.load_font(UiKit.BODY_FONT)
var _body_bold := UiKit.load_font(UiKit.BODY_BOLD_FONT)
var _neon := Color.from_hsv(188.0 / 360.0, 0.78, 1.0)
var _neon_labels: Array[Label] = []
var _shop: Shop
var _records := {}  ## records per mode, shared with Main: some looks unlock with them
var _tokens: Label
var _tabs := {}  ## tab -> Button
var _grid: GridContainer
var _about: Label
var _action: Button
var _action_kind := ""  ## what the big button does now: "wear", "buy" or nothing
var _message: Label
var _tab := "colors"
var _selected := ""
var _cards := {}  ## id -> Button
var _icons: Array[Control] = []  ## redrawn every frame: some looks move


func _init() -> void:
	UiKit.shade(self)
	box = UiKit.vbox(8)
	add_child(box)
	box.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)

	var title := UiKit.label(tr("STYLES"), _display, 72, _neon, true)
	_neon_labels.append(title)
	box.add_child(title)
	_tokens = UiKit.label("", _body_bold, 24, UiKit.MUTED)
	box.add_child(_tokens)
	box.add_child(UiKit.spacer(6))

	# Tabs don't hide anything: they act on press, like the mode picker.
	var tabs := UiKit.center_row(14)
	box.add_child(tabs)
	for tab in TABS:
		var b := Button.new()
		b.text = tr(TABS[tab])
		b.custom_minimum_size = Vector2(Hud.MODE_BUTTON_W, 72)
		b.focus_mode = Control.FOCUS_NONE
		b.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
		b.pressed.connect(func() -> void: _open_tab(tab))
		tabs.add_child(b)
		_tabs[tab] = b
	box.add_child(UiKit.spacer(10))

	_grid = GridContainer.new()
	_grid.columns = 2
	_grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_grid.add_theme_constant_override("h_separation", 16)
	_grid.add_theme_constant_override("v_separation", 14)
	_grid.custom_minimum_size.y = CARD_ROWS * CARD_SIZE.y + (CARD_ROWS - 1) * 14
	box.add_child(_grid)
	box.add_child(UiKit.spacer(10))

	_about = UiKit.label("", _body, 26, UiKit.INK)
	_about.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_about.custom_minimum_size = Vector2(640, 72)
	_about.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(_about)

	var row := UiKit.center_row(0)
	box.add_child(row)
	_action = Button.new()
	_action.custom_minimum_size = Vector2(Hud.BUTTON_W, 96)
	_action.focus_mode = Control.FOCUS_NONE
	_action.action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE  # the store sheet opens on top
	_action.pressed.connect(_on_action)
	row.add_child(_action)
	_message = UiKit.label("", _body_bold, 24, _neon)
	_neon_labels.append(_message)
	box.add_child(_message)

	# Both leave the shop or open a store sheet: on release, like RIPROVA.
	bottom = UiKit.bottom_row(self)
	bottom.add_child(_wide_button(tr("BACK"), closed.emit))
	bottom.add_child(_wide_button(tr("RESTORE"), restore_pressed.emit))


func _process(_delta: float) -> void:
	if visible:
		for icon in _icons:
			icon.queue_redraw()


## What is on sale and owned; records is Main's dictionary, kept up to date in place.
func setup(shop: Shop, records: Dictionary) -> void:
	_shop = shop
	_records = records


## tab: "colors", "ball" or "extra"; pick: a card to start on, if not the first.
func open(tab: String, pick := "") -> void:
	_open_tab(tab)
	if not pick.is_empty():
		_select(pick)


## Owned looks, tokens, prices or the store changed.
func refresh() -> void:
	if _shop == null:
		return
	_tokens.text = tr("TOKENS_COUNT") % _shop.inventory.tokens
	UiKit.style_picker(_tabs, _tab, _display, 26, _neon)
	for id in _cards:
		_style_card(id)
	_update_action()


## The theme colour changed (it follows the look worn or previewed).
func set_neon(color: Color) -> void:
	_neon = color
	for l in _neon_labels:
		l.label_settings.font_color = _neon
		l.label_settings.shadow_color = Color(_neon, 0.32)
	if visible:
		refresh()


## How a purchase or a restore went, in a line under the big button.
func show_result(product: String, outcome: String) -> void:
	var text := ""
	match outcome:
		"ok":
			if product == "restore":
				text = tr("RESTORED")
			elif Catalog.LOOKS.has(product):
				text = tr("LOOK_BOUGHT") % tr(Catalog.LOOKS[product]["name"])
			elif product == Catalog.NO_ADS:
				text = tr("NO_ADS_BOUGHT") % _shop.inventory.tokens
			elif product == Catalog.COLLECTION:
				text = tr("COLLECTION_BOUGHT")
			else:
				text = tr("TOKENS_BOUGHT") % int(Catalog.EXTRAS[product]["tokens"])
		"pending":
			text = tr("PAYMENT_PENDING")
		"nothing":
			text = tr("NOTHING_TO_RESTORE")
		"failed":
			text = tr("RESTORE_FAILED") if product == "restore" else tr("PURCHASE_FAILED")
	_message.text = text
	refresh()


func _open_tab(tab: String) -> void:
	_tab = tab
	for c in _grid.get_children():
		_grid.remove_child(c)
		c.queue_free()
	_cards.clear()
	_icons.clear()
	var ids: Array = Catalog.EXTRAS.keys() if tab == "extra" else Catalog.looks(tab)
	for id in ids:
		var card := _make_card(id)
		_grid.add_child(card)
		_cards[id] = card
	# Start on the look worn, so the preview behind shows no change yet.
	_select(_shop.inventory.wearing[tab] if tab in Catalog.DEFAULT_LOOKS else ids[0])


func _select(id: String) -> void:
	_selected = id
	_message.text = ""
	look_previewed.emit(id)
	refresh()


func _on_action() -> void:
	match _action_kind:
		"wear":
			wear_pressed.emit(_selected)
		"buy":
			_message.text = ""
			buy_pressed.emit(_selected)


## A card: icon, name, rarity (or what an extra is for) and its state.
func _make_card(id: String) -> Button:
	var b := Button.new()
	b.custom_minimum_size = CARD_SIZE
	b.focus_mode = Control.FOCUS_NONE
	b.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	b.pressed.connect(func() -> void: _select(id))
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 10)
	b.add_child(row)
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 10.0
	row.offset_right = -8.0
	var icon := Control.new()
	icon.custom_minimum_size = Vector2(84, 84)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.draw.connect(func() -> void: _draw_icon(icon, id))
	row.add_child(icon)
	_icons.append(icon)
	var texts := UiKit.vbox(0)
	texts.alignment = BoxContainer.ALIGNMENT_CENTER
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(texts)
	var name_text: String
	if Catalog.LOOKS.has(id):
		name_text = tr(Catalog.LOOKS[id]["name"])
	elif Catalog.is_consumable(id):
		name_text = tr(EXTRA_CARDS[id][0]) % int(Catalog.EXTRAS[id]["tokens"])
	else:
		name_text = tr(EXTRA_CARDS[id][0])
	var labels: Array[Label] = [
		UiKit.label(name_text, _body_bold, 25, UiKit.INK),
		UiKit.label("", _body_bold, 17, UiKit.MUTED),
		UiKit.label("", _body, 22, UiKit.MUTED),
	]
	for l in labels:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		texts.add_child(l)
	b.set_meta("labels", labels)
	b.set_meta("icon", icon)
	return b


func _style_card(id: String) -> void:
	var b: Button = _cards[id]
	var labels: Array[Label] = b.get_meta("labels")
	var rarity: String
	if Catalog.LOOKS.has(id):
		rarity = Catalog.LOOKS[id]["rarity"]
		labels[1].text = tr(Catalog.RARITIES[rarity]["name"])
	else:
		rarity = EXTRA_CARDS[id][2]
		labels[1].text = tr(EXTRA_CARDS[id][1])
	var accent: Color = Catalog.RARITIES[rarity]["color"]
	labels[1].label_settings.font_color = accent
	var state := _card_state(id)
	labels[2].text = state[0]
	labels[2].label_settings.font_color = state[1]
	var locked := Catalog.LOOKS.has(id) and not _shop.inventory.has_look(id, _records)
	(b.get_meta("icon") as Control).modulate.a = 0.55 if locked else 1.0

	var chosen := id == _selected
	var style := StyleBoxFlat.new()
	style.bg_color = Color(accent, 0.18) if chosen else Color(UiKit.SHADE, 0.75)
	style.border_color = accent if chosen else Color(accent, 0.6)
	style.set_border_width_all(4 if chosen else 2)
	style.set_corner_radius_all(10)
	for st in ["normal", "hover", "focus", "pressed", "disabled"]:
		b.add_theme_stylebox_override(st, style)


## [text, colour] of a card's last line.
func _card_state(id: String) -> Array:
	var inv := _shop.inventory
	if Catalog.LOOKS.has(id):
		if inv.wearing[Catalog.LOOKS[id]["kind"]] == id:
			return [tr("WEARING"), _neon]
		if inv.has_look(id, _records):
			return [tr("OWNED"), UiKit.INK]
		var unlock: Array = Catalog.LOOKS[id].get("unlock", [])
		if not unlock.is_empty():
			var at := tr("UNLOCK_AT") % [unlock[1], tr(Hud.MODE_NAMES[unlock[0]])]
			return [at, UiKit.MUTED]
	elif id == Catalog.NO_ADS and inv.no_ads():
		return [tr("ACTIVE"), _neon]
	elif id == Catalog.COLLECTION and inv.owned.has(id):
		return [tr("OWNED_COLLECTION"), _neon]
	var price := _shop.price(id)
	return [price if price != "" else "—", UiKit.INK]


## The big button and the line above it follow the card picked.
func _update_action() -> void:
	var id := _selected
	var inv := _shop.inventory
	var text := ""
	var about := ""
	var for_sale := false
	_action_kind = ""
	if Catalog.LOOKS.has(id):
		var look: Dictionary = Catalog.LOOKS[id]
		var where := tr("EVERY_MODE") if look["kind"] == "colors" else tr("BALL_MODES")
		about = "%s. %s" % [tr(look["name"] + "_ABOUT"), where]
		if inv.wearing[look["kind"]] == id:
			text = tr("WEARING")
		elif inv.has_look(id, _records):
			text = tr("WEAR")
			_action_kind = "wear"
		elif not Catalog.is_product(id):
			var unlock: Array = look["unlock"]
			var mode_name := tr(Hud.MODE_NAMES[unlock[0]])
			text = tr("LOCKED")
			about = (tr("UNLOCK_HOW") % [unlock[1], mode_name, int(_records.get(unlock[0], 0))])
		else:
			for_sale = true
	elif Catalog.is_consumable(id):
		about = tr("TOKENS_ABOUT") % inv.tokens
		for_sale = true
	else:
		about = tr(Catalog.EXTRAS[id]["about"])
		if id == Catalog.NO_ADS and inv.no_ads():
			text = tr("ACTIVE")
		elif id == Catalog.COLLECTION and inv.owned.has(id):
			text = tr("ALREADY_YOURS")
		else:
			for_sale = true
	if for_sale:
		if _shop.busy():
			text = tr("WAIT")
		elif _shop.can_buy(id):
			text = tr("BUY") % _shop.price(id)
			_action_kind = "buy"
		else:
			text = tr("UNAVAILABLE")
			if OS.has_feature("web"):
				about += "\n" + tr("STORE_IN_APP")  # the web version sells nothing
			elif not _shop.available():
				about += "\n" + tr("STORE_OFFLINE")
	_action.text = text
	_action.disabled = _action_kind.is_empty()
	UiKit.style_button(_action, _display, 34, UiKit.MUTED if _action.disabled else _neon)
	_action.add_theme_color_override("font_disabled_color", UiKit.MUTED)
	_about.text = about


## Card pictures: a ring of a colour look's hues, a ball look in motion, or
## a sign for the extras.
func _draw_icon(c: Control, id: String) -> void:
	var mid := c.size * 0.5
	var t := Time.get_ticks_msec() / 1000.0
	if Catalog.LOOKS.has(id) and Catalog.LOOKS[id]["kind"] == "colors":
		for i in 6:
			var col := Color.from_hsv(Catalog.theme_hue(id, i * 12, 12, t) / 360.0, 0.78, 1.0)
			var a0 := -PI * 0.5 + i * TAU / 6.0 + 0.07
			var a1 := a0 + TAU / 6.0 - 0.14
			c.draw_arc(mid, 26.0, a0, a1, 10, Color(col, 0.22), 18.0, true)
			c.draw_arc(mid, 26.0, a0, a1, 10, col, 7.0, true)
		return
	if Catalog.LOOKS.has(id):
		# The ball runs up a short diagonal, like in ZIGZAG.
		var r := 9.0
		var head := mid + Vector2(10.0, -10.0)
		var trail := PackedVector2Array()
		for i in 16:
			trail.append(head + Vector2(-40.0, 40.0) * (1.0 - i / 15.0))
		BallLook.draw_trail(c, id, trail, r, _neon, 0.35)
		BallLook.draw_ball(c, id, head, r, _neon, 1.0)
		return
	match id:
		Catalog.NO_ADS:
			var left := mid + Vector2(-40.0, 11.0)
			c.draw_string(_display, left, "AD", HORIZONTAL_ALIGNMENT_CENTER, 80.0, 28, UiKit.INK)
			c.draw_arc(mid, 30.0, 0.0, TAU, 40, UiKit.HOT, 5.0, true)
			var d := Vector2.from_angle(-PI * 0.25) * 30.0
			c.draw_line(mid - d, mid + d, UiKit.HOT, 5.0, true)
		Catalog.COLLECTION:
			var i := 0
			for rarity in Catalog.RARITIES:
				var at := mid + Vector2(-13.0 if i % 2 == 0 else 13.0, -13.0 if i < 2 else 13.0)
				c.draw_colored_polygon(_diamond(at, 12.0), Catalog.RARITIES[rarity]["color"])
				i += 1
		_:
			# A stack of tokens, taller for the bigger packs.
			var coins: int = {"tokens_10": 1, "tokens_30": 2, "tokens_100": 3}.get(id, 1)
			var gold: Color = Catalog.RARITIES["legendary"]["color"]
			for k in coins:
				var at := mid + Vector2(0.0, (coins - 1) * 5.5 - k * 11.0)
				c.draw_circle(at + Vector2(0.0, 4.0), 22.0, gold.darkened(0.45))
				c.draw_circle(at, 22.0, gold)
				c.draw_arc(at, 15.0, 0.0, TAU, 28, gold.darkened(0.3), 3.0, true)


func _diamond(at: Vector2, size: float) -> PackedVector2Array:
	return PackedVector2Array(
		[
			at + Vector2(0, -size),
			at + Vector2(size, 0),
			at + Vector2(0, size),
			at + Vector2(-size, 0)
		]
	)


## A wide outlined button for the bottom row, acting on release.
func _wide_button(text: String, on_press: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(Hud.MODE_BUTTON_W * 1.3, 72)
	b.focus_mode = Control.FOCUS_NONE
	b.action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE
	b.pressed.connect(on_press)
	UiKit.style_button(b, _display, 26, UiKit.MUTED)
	return b
