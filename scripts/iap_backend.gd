extends Node
## In-app purchases through the godot-iap plugin (addons/godot-iap, OpenIAP):
## store connection, prices, purchases and restore on Google Play and the App
## Store. Shop loads this script only where the plugin can run, so nothing else
## in the game depends on the plugin's classes.
##
## There is no server: a purchase the store reports as paid is granted on the
## device. Everything for sale is cosmetic or a convenience and the save is
## local, so checking receipts on a server would protect very little.

signal changed  ## connected, or prices arrived
signal granted(product: String, purchase_id: String)  ## give it to the player now
signal finished(product: String, outcome: String)  ## see Shop.finished

const TYPES_PATH := "res://addons/godot-iap/types.gd"
const RETRY_FIRST := 15.0  ## seconds before trying the store again, doubled each time
const RETRY_MAX := 300.0

# Untyped: the plugin's classes are only known where it is installed.
var _iap  ## the plugin's GodotIapPlugin autoload: the only wrapper we listen to
var _flow  ## confirms, grants and finishes every purchase
var _types  ## the plugin's OpenIAP types (loaded, not preloaded: the plugin may be missing)
var _ids: Array[String] = []
var _prices := {}  ## product id -> price in the player's currency
var _connected := false
var _connecting := false
var _retry := 0.0
var _buying := ""  ## the product the player asked for, until the store answers
var _recovering := false  ## a pass over past purchases: no "purchase done" messages


## iap: the plugin's autoload. types: its OpenIAP types, given only by tests.
func start(iap: Node, ids: Array[String], types: Script = null) -> void:
	_iap = iap
	_ids = ids
	_types = types if types != null else load(TYPES_PATH)
	_flow = _iap.create_purchase_flow(
		{
			"confirm_with_backend": _confirm,
			"is_consumable": func(sku: String) -> bool: return Catalog.is_consumable(_id(sku)),
		}
	)
	_flow.purchase_processed.connect(_on_processed)
	_iap.purchase_error.connect(_on_error)
	_connect_store()


func connected() -> bool:
	return _connected


func price(id: String) -> String:
	return _prices.get(id, "")


func refresh() -> void:
	if not _connected or _prices.is_empty():
		_connect_store()


func buy(id: String) -> void:
	_buying = id
	var sku := Catalog.PREFIX + id
	var skus: Array[String] = [sku]
	var props = _types.RequestPurchaseProps.new()
	props.request = _types.RequestPurchasePropsByPlatforms.new()
	props.request.google = _types.RequestPurchaseAndroidProps.new()
	props.request.google.skus = skus
	props.request.apple = _types.RequestPurchaseIosProps.new()
	props.request.apple.sku = sku
	props.type = _types.ProductQueryType.IN_APP
	_iap.request_purchase(props)  # the answer comes through the flow or purchase_error


## Asks the store for everything bought with this account (on iOS it may show
## the App Store sign-in) and grants it again.
func restore() -> void:
	var result = await _iap.restore_purchases()
	if not result.success:
		finished.emit("restore", "cancelled" if result.code == "user-cancelled" else "failed")
		return
	var outcomes = await _recover()
	if not outcomes is Array:
		finished.emit("restore", "failed")
		return
	var found: bool = outcomes.any(
		func(o: Dictionary) -> bool: return o["status"].status == "entitled"
	)
	finished.emit("restore", "ok" if found else "nothing")


func _connect_store() -> void:
	if _connecting:
		return
	_connecting = true
	_connected = await _iap.init_connection()
	if _connected:
		changed.emit()
		# Purchases left unfinished (a crash, a payment approved later) and, after
		# a reinstall, everything bought before come back here.
		await _recover()
		await _fetch_prices()
	_connecting = false
	if not _connected or _prices.is_empty():
		_retry_later()
	else:
		_retry = 0.0


func _fetch_prices() -> void:
	var skus: Array[String] = []
	for id in _ids:
		skus.append(Catalog.PREFIX + id)
	var request = _types.ProductRequest.new()
	request.skus = skus
	request.type = _types.ProductQueryType.IN_APP
	var products: Array = await _iap.fetch_products(request)
	for product in products:
		if product.display_price != "":
			_prices[_id(product.id)] = product.display_price
	changed.emit()


func _recover() -> Variant:
	_recovering = true
	var outcomes = await _flow.recover_purchases(true)
	_recovering = false
	return outcomes


## The flow asks whether to grant a purchase the store reports as paid (it has
## already set aside payments still pending). The player gets it before the
## flow finishes it: a token pack is consumed then, and must be counted first.
func _confirm(purchase: Dictionary, _is_consumable: bool) -> Variant:
	var id := _id(str(purchase.get("productId", "")))
	if not Catalog.is_product(id):
		return {"status": "invalid", "reason": "not sold by this game"}
	if purchase.get("revocationDateIOS") != null:
		return {"status": "invalid", "reason": "refunded"}
	granted.emit(id, str(purchase.get("id", "")))
	return {"status": "entitled", "alreadyGranted": false}


func _on_processed(purchase: Dictionary, status) -> void:
	var id := _id(str(purchase.get("productId", "")))
	var outcome := "failed"
	match status.status:
		"entitled":
			outcome = "ok"
		"store_pending":
			outcome = "pending"
	if id == _buying:
		_buying = ""
		finished.emit(id, outcome)
	elif outcome == "ok" and not _recovering:
		finished.emit(id, outcome)  # e.g. a pending payment that went through later


## Errors of the purchase the player asked for. Other operations (restore,
## queries) tag a "method" and report through their own results.
func _on_error(error: Dictionary) -> void:
	if error.has("method") or _buying.is_empty():
		return
	var id := _buying
	_buying = ""
	match str(error.get("code", "")):
		"user-cancelled":
			finished.emit(id, "cancelled")
		"already-owned":
			# Bought before, maybe on another device: fetch it and give it back.
			await _recover()
			finished.emit(id, "ok")
		_:
			finished.emit(id, "failed")


## No store, no network, or no prices yet: try again later, waiting longer each time.
func _retry_later() -> void:
	var wait: float = clampf(_retry * 2.0, RETRY_FIRST, RETRY_MAX)
	_retry = wait
	get_tree().create_timer(wait).timeout.connect(refresh)


func _id(sku: String) -> String:
	return sku.trim_prefix(Catalog.PREFIX)
