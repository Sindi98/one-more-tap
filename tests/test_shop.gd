extends SceneTree
## Headless tests for the shop rules: catalogue, what the player owns, tokens,
## saving, and the days in a row that open DINO. Run from the project folder:
##   godot --headless --path . --script res://tests/test_shop.gd
## Exit code 0 = all passed.

const CatalogScript := preload("res://scripts/catalog.gd")
const InventoryScript := preload("res://scripts/inventory.gd")
const StreakScript := preload("res://scripts/streak.gd")

const NO_RECORDS := {"zigzag": 0, "tower": 0, "runner": 0}

var _fails := 0


func _init() -> void:
	_test_catalogue_is_consistent()
	_test_theme_hues()
	_test_free_and_record_looks()
	_test_paid_looks_and_collection()
	_test_starter_tokens_once()
	_test_token_packs_credited_once()
	_test_wearing()
	_test_inventory_save_roundtrip()
	_test_streak_three_days_in_a_row()
	_test_streak_gaps_and_clock()
	_test_day_numbers()
	print("all tests passed" if _fails == 0 else "%d failures" % _fails)
	quit(1 if _fails > 0 else 0)


func _check(cond: bool, msg: String) -> void:
	if not cond:
		_fails += 1
		print("FAIL ", msg)


func _test_catalogue_is_consistent() -> void:
	var seen := {}
	for id in CatalogScript.product_ids():
		_check(not seen.has(id), "product %s listed once" % id)
		seen[id] = true
		_check(CatalogScript.is_product(id), "%s is a product" % id)
		_check(CatalogScript.price_band(id) != "", "%s has a price band" % id)
		var sku: String = CatalogScript.PREFIX + id
		_check(
			RegEx.create_from_string("^[a-z0-9][a-z0-9_.]*$").search(sku) != null,
			"%s is a valid store id" % sku
		)
	for id in CatalogScript.LOOKS:
		var look: Dictionary = CatalogScript.LOOKS[id]
		_check(CatalogScript.RARITIES.has(look["rarity"]), "%s has a known rarity" % id)
		_check(look["kind"] in CatalogScript.DEFAULT_LOOKS, "%s has a known kind" % id)
		_check(
			(look["rarity"] == "common") != CatalogScript.is_product(id),
			"%s: free or for sale" % id
		)
		if look.has("unlock"):
			_check(look["rarity"] == "common", "%s: only common looks unlock with a record" % id)
			_check(NO_RECORDS.has(look["unlock"][0]), "%s unlocks in a real mode" % id)
		if look["kind"] == "colors":
			_check(CatalogScript.PALETTES.has(id), "%s has a palette" % id)
	for kind in CatalogScript.DEFAULT_LOOKS:
		var id: String = CatalogScript.DEFAULT_LOOKS[kind]
		_check(not CatalogScript.LOOKS[id].has("unlock"), "default %s is free from the start" % id)
		_check(CatalogScript.looks(kind)[0] == id, "default %s comes first in the shop" % id)
	_check(CatalogScript.is_consumable("tokens_10"), "token packs are consumable")
	_check(not CatalogScript.is_consumable(CatalogScript.NO_ADS), "the ad-free pass is not")
	_check(not CatalogScript.is_product("neon"), "a free look is not a product")


func _test_theme_hues() -> void:
	var neon: Array = CatalogScript.PALETTES["neon"]["hues"]
	_check(
		is_equal_approx(CatalogScript.theme_hue("neon", 0, 12, 5.0), neon[0]),
		"neon starts on its first hue"
	)
	_check(
		is_equal_approx(CatalogScript.theme_hue("neon", 12, 12, 5.0), neon[1]),
		"neon steps every few points"
	)
	_check(
		is_equal_approx(CatalogScript.theme_hue("missing", 0, 12, 0.0), neon[0]),
		"an unknown look shows neon"
	)
	var a: float = CatalogScript.theme_hue("arcobaleno", 0, 12, 0.0)
	var b: float = CatalogScript.theme_hue("arcobaleno", 0, 12, 1.0)
	_check(absf(b - a) > 10.0, "the rainbow flows with time")
	for i in 50:
		var h: float = CatalogScript.theme_hue("oro", 0, 12, i * 0.13)
		_check(h >= 36.0 and h <= 52.0, "gold shimmers around its hue (%.1f)" % h)


func _test_free_and_record_looks() -> void:
	var inv = InventoryScript.new()
	_check(inv.has_look("neon", NO_RECORDS), "neon is free")
	_check(inv.has_look("classica", NO_RECORDS), "the classic ball is free")
	_check(not inv.has_look("ghiaccio", NO_RECORDS), "ghiaccio needs a record")
	_check(not inv.has_look("ghiaccio", {"zigzag": 24}), "not one point short")
	_check(inv.has_look("ghiaccio", {"zigzag": 25}), "unlocked by the record")
	_check(not inv.has_look("anello", {"zigzag": 999}), "the record of another mode does not count")
	_check(not inv.has_look("nothing", NO_RECORDS), "unknown looks are not owned")


func _test_paid_looks_and_collection() -> void:
	var inv = InventoryScript.new()
	_check(not inv.has_look("tramonto", NO_RECORDS), "paid looks start locked")
	inv.grant("tramonto", "p1")
	_check(inv.has_look("tramonto", NO_RECORDS), "bought")
	_check(not inv.has_look("acido", NO_RECORDS), "only what was bought")
	_check(not inv.no_ads(), "a look does not remove ads")
	inv.grant("collection", "p2")
	for id in CatalogScript.LOOKS:
		if CatalogScript.LOOKS[id]["rarity"] != "common":
			_check(inv.has_look(id, NO_RECORDS), "the collection gives %s" % id)
	_check(not inv.has_look("ghiaccio", NO_RECORDS), "record looks stay earned by playing")
	_check(inv.no_ads(), "the collection removes ads")
	inv.grant("something_else", "p3")
	_check(not inv.owned.has("something_else"), "unknown products are ignored")


func _test_starter_tokens_once() -> void:
	var inv = InventoryScript.new()
	inv.grant("no_ads", "a")
	_check(inv.tokens == CatalogScript.STARTER_TOKENS, "the ad-free pass comes with tokens")
	inv.grant("no_ads", "a")  # restored, or delivered again
	inv.grant("collection", "b")
	_check(inv.tokens == CatalogScript.STARTER_TOKENS, "starter tokens only once")
	var other = InventoryScript.new()
	other.grant("collection", "c")
	_check(other.tokens == CatalogScript.STARTER_TOKENS, "the collection gives them too")


func _test_token_packs_credited_once() -> void:
	var inv = InventoryScript.new()
	inv.grant("tokens_10", "t1")
	inv.grant("tokens_10", "t1")  # same purchase delivered twice
	_check(inv.tokens == 10, "a purchase is credited once (%d)" % inv.tokens)
	inv.grant("tokens_30", "t2")
	_check(inv.tokens == 40, "a new purchase adds up")
	_check(not inv.owned.has("tokens_10"), "packs are not kept as owned")
	_check(not inv.no_ads(), "tokens do not remove ads")
	for i in 40:
		_check(inv.spend_token(), "spend token %d" % i)
	_check(inv.tokens == 0, "all spent")
	_check(not inv.spend_token(), "none left to spend")
	_check(inv.tokens == 0, "never below zero")
	for i in InventoryScript.CREDITED_KEEP + 5:
		inv.grant("tokens_10", "many%d" % i)
	inv.grant("tokens_10", "many%d" % (InventoryScript.CREDITED_KEEP + 4))
	_check(
		inv.tokens == 10 * (InventoryScript.CREDITED_KEEP + 5), "recent purchases stay remembered"
	)


func _test_wearing() -> void:
	var inv = InventoryScript.new()
	_check(inv.wearing["colors"] == "neon" and inv.wearing["ball"] == "classica", "defaults on")
	_check(not inv.wear("tramonto", NO_RECORDS), "cannot wear what is not owned")
	_check(inv.wearing["colors"] == "neon", "still neon")
	inv.grant("tramonto", "x")
	_check(inv.wear("tramonto", NO_RECORDS), "wear a bought look")
	_check(inv.wear("supernova", NO_RECORDS) == false, "a ball not owned")
	inv.grant("supernova", "y")
	_check(inv.wear("supernova", NO_RECORDS), "wear a bought ball")
	_check(inv.wearing["colors"] == "tramonto", "a ball does not change the colours")
	_check(inv.wear("ghiaccio", {"zigzag": 30}), "wear a look earned with a record")
	inv.check_wearing(NO_RECORDS)  # e.g. records reset
	_check(inv.wearing["colors"] == "neon", "back to the default when no longer owned")
	_check(inv.wearing["ball"] == "supernova", "owned looks stay on")


func _test_inventory_save_roundtrip() -> void:
	var inv = InventoryScript.new()
	inv.grant("no_ads", "a")
	inv.grant("pixel", "b")
	inv.grant("tokens_30", "c")
	inv.spend_token()
	inv.wear("pixel", NO_RECORDS)
	var cfg := ConfigFile.new()
	inv.save_to(cfg)
	var back = InventoryScript.new()
	back.load_from(cfg, NO_RECORDS)
	_check(back.no_ads(), "the pass is saved")
	_check(back.has_look("pixel", NO_RECORDS), "looks are saved")
	_check(
		back.tokens == CatalogScript.STARTER_TOKENS + 30 - 1, "tokens are saved (%d)" % back.tokens
	)
	_check(back.wearing["ball"] == "pixel", "what is worn is saved")
	back.grant("tokens_30", "c")
	_check(back.tokens == CatalogScript.STARTER_TOKENS + 29, "credited purchases are saved too")
	back.grant("no_ads", "again")
	_check(back.tokens == CatalogScript.STARTER_TOKENS + 29, "starter tokens are not given again")

	var odd := ConfigFile.new()
	odd.set_value("shop", "owned", PackedStringArray(["bogus", "tokens_10", "acido"]))
	odd.set_value("shop", "tokens", -5)
	odd.set_value("shop", "wear_colors", "tramonto")
	odd.set_value("shop", "wear_ball", "bogus")
	var fixed = InventoryScript.new()
	fixed.load_from(odd, NO_RECORDS)
	_check(fixed.owned.keys() == ["acido"], "only real one-off products are loaded")
	_check(fixed.tokens == 0, "tokens never load negative")
	_check(fixed.wearing["colors"] == "neon", "a look not owned is not worn")
	_check(fixed.wearing["ball"] == "classica", "an unknown look is not worn")

	var empty = InventoryScript.new()
	empty.load_from(ConfigFile.new(), NO_RECORDS)
	_check(empty.tokens == 0 and empty.owned.is_empty(), "a first launch owns nothing")
	_check(empty.wearing["colors"] == "neon", "and wears the defaults")


func _test_streak_three_days_in_a_row() -> void:
	var s = StreakScript.new()
	_check(s.days_left() == StreakScript.DAYS_TO_UNLOCK, "three days to go at first")
	_check(not s.visit(100), "day 1")
	_check(not s.visit(100), "day 1 again")
	_check(s.days == 1 and s.days_left() == 2, "opening twice a day counts once")
	_check(not s.visit(101), "day 2")
	_check(s.visit(102), "day 3 unlocks DINO")
	_check(s.unlocked and s.days_left() == 0, "open")
	_check(not s.visit(103), "unlocks only once")
	var cfg := ConfigFile.new()
	s.save_to(cfg)
	var back = StreakScript.new()
	back.load_from(cfg)
	_check(back.unlocked and back.last_day == 103 and back.days == 4, "saved")


func _test_streak_gaps_and_clock() -> void:
	var s = StreakScript.new()
	s.visit(10)
	s.visit(11)
	s.visit(13)  # skipped a day
	_check(s.days == 1 and not s.unlocked, "a missed day starts again")
	s.visit(12)  # clock set back
	_check(s.days == 1 and s.last_day == 13, "a clock going back changes nothing")
	s.visit(14)
	_check(s.visit(15), "three new days in a row unlock")
	s.visit(30)
	_check(s.unlocked, "once open, DINO stays open")
	var fresh = StreakScript.new()
	fresh.load_from(ConfigFile.new())
	_check(fresh.last_day == -1 and fresh.days == 0 and not fresh.unlocked, "nothing saved yet")


func _test_day_numbers() -> void:
	var d1: int = StreakScript.day_number({"year": 2026, "month": 10, "day": 31})
	var d2: int = StreakScript.day_number({"year": 2026, "month": 11, "day": 1})
	var d3: int = StreakScript.day_number({"year": 2027, "month": 1, "day": 1})
	_check(d2 == d1 + 1, "next day across a month")
	_check(d3 == d1 + 62, "and across a year")
	_check(
		StreakScript.day_number({"year": 1970, "month": 1, "day": 2, "weekday": 5}) == 1, "day one"
	)
