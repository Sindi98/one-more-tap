extends Node
## Fake of the godot-iap plugin's autoload (GodotIapPlugin) for headless tests:
## a store with prices and purchases, answering the next request as `answer`
## says. Its purchase flow confirms purchases like the real one: pending ones
## are set aside, the others go through the game's confirm callback, and
## consumables are used up once granted.

signal purchase_error(error: Dictionary)

## What the next request_purchase does: ok, pending, cancel, fail or owned
## (bought before, e.g. on another device).
var answer := "ok"
var connected_ok := true
var prices := {}  ## sku -> price shown
var owned: Array = []  ## purchases the store holds (JSON shape, like the plugin's)
var flow: Flow
var _count := 0


class Product:
	var id: String
	var display_price: String

	func _init(sku: String, price: String) -> void:
		id = sku
		display_price = price


class Status:
	var status: String

	func _init(s: String) -> void:
		status = s


class Flow:
	signal purchase_processed(purchase: Dictionary, status: Status)

	var options: Dictionary
	var store  ## the fake plugin

	func _init(o: Dictionary, s) -> void:
		options = o
		store = s

	func deliver(purchase: Dictionary) -> Status:
		if purchase.get("purchaseState") == "pending":
			var waiting := Status.new("store_pending")
			purchase_processed.emit(purchase, waiting)
			return waiting
		var consumable: bool = options.is_consumable.call(purchase.productId)
		var answer = await options.confirm_with_backend.call(purchase, consumable)
		var status := Status.new(answer.status)
		if status.status == "entitled" and consumable:
			store.owned.erase(purchase)
		purchase_processed.emit(purchase, status)
		return status

	func recover_purchases(_include_finished := false) -> Variant:
		var out := []
		for purchase in store.owned.duplicate():
			out.append({"purchase": purchase, "status": await deliver(purchase)})
		return out


func create_purchase_flow(options: Dictionary) -> Flow:
	flow = Flow.new(options, self)
	return flow


func init_connection(_config = null) -> bool:
	await get_tree().process_frame
	return connected_ok


func fetch_products(request) -> Array:
	await get_tree().process_frame
	var out := []
	for sku in request.skus:
		if prices.has(sku):
			out.append(Product.new(sku, prices[sku]))
	return out


func request_purchase(props) -> Variant:
	var sku: String = props.request.google.skus[0]
	assert(props.request.apple.sku == sku, "the same product on both stores")
	_count += 1
	match answer:
		"cancel":
			purchase_error.emit({"code": "user-cancelled", "message": "cancelled"})
		"fail":
			purchase_error.emit({"code": "service-error", "message": "no network"})
		"owned":
			owned.append({"id": "old%d" % _count, "productId": sku, "purchaseState": "purchased"})
			purchase_error.emit({"code": "already-owned", "message": "owned"})
		_:
			var state := "pending" if answer == "pending" else "purchased"
			var purchase := {"id": "tx%d" % _count, "productId": sku, "purchaseState": state}
			owned.append(purchase)
			_deliver_later(purchase)
	return null


func restore_purchases() -> Variant:
	await get_tree().process_frame
	return {"success": true, "code": ""}


func _deliver_later(purchase: Dictionary) -> void:
	await get_tree().process_frame
	flow.deliver(purchase)
