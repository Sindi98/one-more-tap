extends SceneTree
## Headless tests for the store connection (iap_backend.gd), against a fake of
## the godot-iap plugin: prices, purchases, cancel, errors, payments approved
## later, products already owned, restore. Run from the project folder:
##   godot --headless --path . --script res://tests/test_iap_backend.gd
## Exit code 0 = all passed.

const BackendScript := preload("res://scripts/iap_backend.gd")
const FakeStore := preload("res://tests/fake_iap.gd")
const FakeTypes := preload("res://tests/fake_iap_types.gd")
const FRAMES := 10  ## enough for the fake store to answer

var _fails := 0
var _store
var _backend
var _events: Array = []  ## [product, outcome] of every finished()
var _grants: Array = []  ## [product, purchase id] of every granted()


func _init() -> void:
	_store = FakeStore.new()
	root.add_child(_store)
	_store.prices = {
		"onemoretap.no_ads": "2,99 €",
		"onemoretap.tokens_10": "0,99 €",
		"onemoretap.tramonto": "0,99 €",
	}
	_store.owned = [{"id": "prev1", "productId": "onemoretap.pixel", "purchaseState": "purchased"}]
	_backend = BackendScript.new()
	root.add_child(_backend)
	_backend.granted.connect(
		func(id: String, purchase: String) -> void: _grants.append([id, purchase])
	)
	_backend.finished.connect(
		func(id: String, outcome: String) -> void: _events.append([id, outcome])
	)
	await process_frame  # nodes enter the tree
	_backend.start(_store, Catalog.product_ids(), FakeTypes)
	await _wait()

	_test_launch()
	await _test_purchase()
	await _test_cancel_and_fail()
	await _test_pending_then_paid()
	await _test_already_owned()
	await _test_restore()
	print("all tests passed" if _fails == 0 else "%d failures" % _fails)
	quit(1 if _fails > 0 else 0)


func _check(cond: bool, msg: String) -> void:
	if not cond:
		_fails += 1
		print("FAIL ", msg)


func _wait() -> void:
	for i in FRAMES:
		await process_frame


func _clear() -> void:
	_events.clear()
	_grants.clear()


func _test_launch() -> void:
	_check(_backend.connected(), "connected")
	_check(_backend.price("no_ads") == "2,99 €", "prices come from the store")
	_check(_backend.price("oro") == "", "no price for a product the store does not have")
	_check(_grants == [["pixel", "prev1"]], "what was bought before comes back at launch")
	_check(_events.is_empty(), "silently: no message for the launch recovery")


func _test_purchase() -> void:
	_clear()
	_store.answer = "ok"
	_backend.buy("tokens_10")
	await _wait()
	_check(_grants.size() == 1 and _grants[0][0] == "tokens_10", "token pack granted")
	_check(_events == [["tokens_10", "ok"]], "purchase ok")
	_check(
		not _store.owned.any(func(p: Dictionary) -> bool: return p.id == _grants[0][1]), "consumed"
	)


func _test_cancel_and_fail() -> void:
	_clear()
	_store.answer = "cancel"
	_backend.buy("tramonto")
	await _wait()
	_check(_events == [["tramonto", "cancelled"]], "cancelled")
	_clear()
	_store.answer = "fail"
	_backend.buy("tramonto")
	await _wait()
	_check(_events == [["tramonto", "failed"]], "failed")
	_check(_grants.is_empty(), "nothing granted")


func _test_pending_then_paid() -> void:
	_clear()
	_store.answer = "pending"
	_backend.buy("no_ads")
	await _wait()
	_check(_events == [["no_ads", "pending"]], "payment pending")
	_check(_grants.is_empty(), "nothing granted while pending")
	var purchase: Dictionary = _store.owned.back()
	purchase["purchaseState"] = "purchased"  # paid later, while the game runs
	_store.flow.deliver(purchase)
	await _wait()
	_check(_grants.size() == 1 and _grants[0][0] == "no_ads", "granted once paid")
	_check(_events.back() == ["no_ads", "ok"], "and the player is told")


func _test_already_owned() -> void:
	_clear()
	_store.answer = "owned"
	_backend.buy("tramonto")
	await _wait()
	_check(_events.back() == ["tramonto", "ok"], "bought before (other device): ends ok")
	_check(_grants.any(func(g: Array) -> bool: return g[0] == "tramonto"), "and is granted")


func _test_restore() -> void:
	_clear()
	_backend.restore()
	await _wait()
	_check(_events == [["restore", "ok"]], "restore finds what was bought")
	_store.owned.clear()
	_clear()
	_backend.restore()
	await _wait()
	_check(_events == [["restore", "nothing"]], "nothing to restore")
