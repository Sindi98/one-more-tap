class_name Inventory
extends RefCounted
## What the player owns and wears: looks, the ad-free pass, the collection and
## the tokens. Pure logic, no nodes: the shop grants purchases here, the game
## saves it and asks it what to show.

const CREDITED_KEEP := 50  ## token purchases remembered, so a redelivery is not counted twice

var owned := {}  ## product id -> true, for everything bought once (looks and passes)
var tokens := 0  ## one CONTINUA each, without a video
var wearing := Catalog.DEFAULT_LOOKS.duplicate()  ## kind -> look id

var _starter_given := false
var _credited: Array[String] = []  ## ids of the latest token purchases


## The ad-free pass, bought alone or with the collection.
func no_ads() -> bool:
	return owned.has(Catalog.NO_ADS) or owned.has(Catalog.COLLECTION)


## best: record per mode, for the looks a record unlocks.
func has_look(id: String, best: Dictionary) -> bool:
	if not Catalog.LOOKS.has(id):
		return false
	var look: Dictionary = Catalog.LOOKS[id]
	if look["rarity"] != "common":
		return owned.has(id) or owned.has(Catalog.COLLECTION)
	var unlock: Array = look.get("unlock", [])
	return unlock.is_empty() or int(best.get(unlock[0], 0)) >= int(unlock[1])


## Puts a look on, if the player has it. Returns false otherwise.
func wear(id: String, best: Dictionary) -> bool:
	if not has_look(id, best):
		return false
	wearing[Catalog.LOOKS[id]["kind"]] = id
	return true


## A look no longer owned (a refund, an id from an old save) falls back to the
## default of its kind.
func check_wearing(best: Dictionary) -> void:
	for kind in Catalog.DEFAULT_LOOKS:
		var id: String = wearing.get(kind, "")
		if not has_look(id, best) or Catalog.LOOKS[id]["kind"] != kind:
			wearing[kind] = Catalog.DEFAULT_LOOKS[kind]


## A purchase the store confirmed. purchase_id tells a new token pack from the
## same one delivered again (after a crash, before the store consumed it).
func grant(product: String, purchase_id: String) -> void:
	if Catalog.is_consumable(product):
		if purchase_id in _credited:
			return
		_credited.append(purchase_id)
		if _credited.size() > CREDITED_KEEP:
			_credited.remove_at(0)
		tokens += int(Catalog.EXTRAS[product]["tokens"])
		return
	if not Catalog.is_product(product):
		return
	owned[product] = true
	if no_ads() and not _starter_given:
		_starter_given = true
		tokens += Catalog.STARTER_TOKENS


func spend_token() -> bool:
	if tokens <= 0:
		return false
	tokens -= 1
	return true


func save_to(cfg: ConfigFile) -> void:
	cfg.set_value("shop", "owned", PackedStringArray(owned.keys()))
	cfg.set_value("shop", "tokens", tokens)
	cfg.set_value("shop", "starter_given", _starter_given)
	cfg.set_value("shop", "credited", PackedStringArray(_credited))
	for kind in wearing:
		cfg.set_value("shop", "wear_" + kind, wearing[kind])


func load_from(cfg: ConfigFile, best: Dictionary) -> void:
	owned.clear()
	for id in cfg.get_value("shop", "owned", PackedStringArray()):
		if Catalog.is_product(id) and not Catalog.is_consumable(id):
			owned[id] = true
	tokens = maxi(0, int(cfg.get_value("shop", "tokens", 0)))
	_starter_given = bool(cfg.get_value("shop", "starter_given", false))
	_credited.assign(cfg.get_value("shop", "credited", PackedStringArray()))
	for kind in Catalog.DEFAULT_LOOKS:
		wearing[kind] = str(cfg.get_value("shop", "wear_" + kind, Catalog.DEFAULT_LOOKS[kind]))
	check_wearing(best)
