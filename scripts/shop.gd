class_name Shop
extends Node
## What the game knows about in-app purchases: prices, "buy this", "restore",
## and what the player owns (inventory). The store is optional: where the
## godot-iap plugin cannot run (desktop builds, headless tests) nothing is on
## sale and the game plays as before; run from the editor (F5) purchases are
## pretend and always go through, to try the whole flow without a phone.

signal changed  ## something was granted or spent, prices arrived, or the store connected
## A purchase or a restore ended. product: its id, or "restore". outcome: "ok",
## "pending" (paid later, e.g. cash), "cancelled", "failed" or, for a restore,
## "nothing" (nothing to restore).
signal finished(product: String, outcome: String)

const BACKEND_PATH := "res://scripts/iap_backend.gd"
const PLUGIN_PATH := "res://addons/godot-iap/godot_iap.gd"
const PLUGIN_NODE := "/root/GodotIapPlugin"  ## the plugin's autoload
const MOCK_DELAY := 0.6  ## editor: how long a pretend purchase takes
## Unblocks the shop if the store never answers. A late answer still counts:
## whatever it grants lands in the inventory.
const BUSY_TIMEOUT := 180.0

var inventory := Inventory.new()

## iap_backend.gd, loaded by path only where the plugin can run, so that
## desktop and test runs never load the plugin's scripts.
var _backend: Node
var _mock := false
var _busy := ""  ## product being bought, or "restore", while the store works
var _busy_count := 0  ## tells the timeout of an old request from the current one
var _mock_count := 0


## Called once the inventory is loaded: purchases restored at launch land in it.
func start() -> void:
	if _plugin_can_run():
		_backend = (load(BACKEND_PATH) as GDScript).new()
		add_child(_backend)
		_backend.connect("changed", func() -> void: changed.emit())
		_backend.connect("granted", _on_granted)
		_backend.connect("finished", _on_finished)
		_backend.call("start", get_node(PLUGIN_NODE), Catalog.product_ids())
	elif OS.has_feature("editor") and DisplayServer.get_name() != "headless":
		_mock = true


## The store is there: prices can show and purchases can start.
func available() -> bool:
	return _mock or (_backend != null and _backend.call("connected"))


## Price in the player's currency, "" while the store has not said it.
func price(id: String) -> String:
	if _mock:
		return Catalog.price_band(id)
	if _backend == null:
		return ""
	return _backend.call("price", id)


func can_buy(id: String) -> bool:
	return not busy() and available() and price(id) != ""


## A purchase or restore is under way: the store's own sheet is on top.
func busy() -> bool:
	return _busy != ""


## The store opens its payment sheet; finished() tells how it went.
func buy(id: String) -> void:
	if not can_buy(id):
		return
	_set_busy(id)
	if _mock:
		_mock_count += 1
		var purchase := "editor-%d" % _mock_count
		get_tree().create_timer(MOCK_DELAY).timeout.connect(
			func() -> void:
				_on_granted(id, purchase)
				_on_finished(id, "ok")
		)
		return
	_backend.call("buy", id)


## Apple requires a way to get back what was bought on another device or
## before a reinstall. On Android this happens at launch as well.
func restore() -> void:
	if busy():
		return
	_set_busy("restore")
	if _mock:
		get_tree().create_timer(MOCK_DELAY).timeout.connect(
			func() -> void: _on_finished("restore", "nothing")
		)
		return
	if _backend == null:
		_on_finished.call_deferred("restore", "failed")
		return
	_backend.call("restore")


## The shop was opened: a store that did not answer at launch gets another try.
func refresh() -> void:
	if _backend != null:
		_backend.call("refresh")


func _plugin_can_run() -> bool:
	if not ResourceLoader.exists(PLUGIN_PATH) or not has_node(PLUGIN_NODE):
		return false  # plugin not installed: nothing on sale
	# Android: the plugin's singleton. iOS: its GDExtension class.
	return Engine.has_singleton("GodotIap") or ClassDB.class_exists("GodotIap")


func _set_busy(id: String) -> void:
	_busy = id
	_busy_count += 1
	var count := _busy_count
	get_tree().create_timer(BUSY_TIMEOUT).timeout.connect(
		func() -> void:
			if _busy == id and _busy_count == count:
				_on_finished(id, "failed")
	)
	changed.emit()


## The store confirmed a purchase. The game saves on changed, right away: the
## store finishes (and so consumes) the purchase as soon as this returns.
func _on_granted(id: String, purchase_id: String) -> void:
	inventory.grant(id, purchase_id)
	changed.emit()


func _on_finished(id: String, outcome: String) -> void:
	if id == _busy:
		_busy = ""
	finished.emit(id, outcome)
	changed.emit()
