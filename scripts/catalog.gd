class_name Catalog
extends RefCounted
## Everything the shop sells or gives away: looks with a rarity, the ad-free
## pass, the full collection and the tokens. Pure data and rules, no nodes.
##
## Rarity is a price band and how much a look does, never luck: the player sees
## exactly what they buy. Common looks are free, some from the start, some
## once a record is reached; every other look is sold once and kept for good.

## Store product ids are PREFIX + id, the same on Google Play and the App Store.
const PREFIX := "onemoretap."

## "price": the band each product is set to in the stores. The game shows the
## store's own price, in the player's currency; this one only in the editor.
const RARITIES := {
	"common": {"name": "COMUNE", "color": Color("aab0d0"), "price": ""},
	"rare": {"name": "RARO", "color": Color("4da6ff"), "price": "0,99 €"},
	"epic": {"name": "EPICO", "color": Color("b866ff"), "price": "1,99 €"},
	"legendary": {"name": "LEGGENDARIO", "color": Color("ffc23d"), "price": "3,99 €"},
}

## Looks, in shop order. kind "colors": the neon of every mode; "ball": the ball
## of ZIGZAG and TORRE. "unlock": [mode, score] frees a common look once that
## record is reached; a common look without it is there from the start.
const LOOKS := {
	"neon": {"kind": "colors", "rarity": "common", "name": "NEON", "about": "I colori di sempre"},
	"ghiaccio":
	{
		"kind": "colors",
		"rarity": "common",
		"name": "GHIACCIO",
		"about": "Azzurri e blu freddi",
		"unlock": ["zigzag", 25],
	},
	"deserto":
	{
		"kind": "colors",
		"rarity": "common",
		"name": "DESERTO",
		"about": "Sabbia, ocra e terra",
		"unlock": ["runner", 500],
	},
	"tramonto":
	{"kind": "colors", "rarity": "rare", "name": "TRAMONTO", "about": "Rossi, rosa e arancioni"},
	"acido": {"kind": "colors", "rarity": "rare", "name": "ACIDO", "about": "Lime, giallo e verde"},
	"oro": {"kind": "colors", "rarity": "epic", "name": "ORO", "about": "Oro che luccica sempre"},
	"arcobaleno":
	{
		"kind": "colors",
		"rarity": "legendary",
		"name": "ARCOBALENO",
		"about": "Tutti i colori, che scorrono senza fermarsi",
	},
	"classica":
	{"kind": "ball", "rarity": "common", "name": "CLASSICA", "about": "La pallina di sempre"},
	"anello":
	{
		"kind": "ball",
		"rarity": "common",
		"name": "ANELLO",
		"about": "Un anello di luce",
		"unlock": ["tower", 25],
	},
	"diamante":
	{"kind": "ball", "rarity": "rare", "name": "DIAMANTE", "about": "Un diamante che gira"},
	"pixel":
	{"kind": "ball", "rarity": "rare", "name": "PIXEL", "about": "Quadrata, scia a gradini"},
	"cometa":
	{"kind": "ball", "rarity": "epic", "name": "COMETA", "about": "Lunga coda di luce e scintille"},
	"supernova":
	{
		"kind": "ball",
		"rarity": "legendary",
		"name": "SUPERNOVA",
		"about": "Una stella che pulsa, scia di stelle e PERFETTO che esplodono",
	},
}
const DEFAULT_LOOKS := {"colors": "neon", "ball": "classica"}

## Theme hues of each colour look: the run steps to the next one every few
## points. "shimmer": degrees the hue keeps swinging; "flow": degrees per
## second the hue keeps turning, plus a full turn every six steps.
const PALETTES := {
	"neon": {"hues": [188.0, 318.0, 42.0, 268.0, 150.0, 8.0]},
	"ghiaccio": {"hues": [190.0, 215.0, 175.0, 235.0, 200.0, 165.0]},
	"deserto": {"hues": [38.0, 22.0, 50.0, 12.0, 30.0, 58.0]},
	"tramonto": {"hues": [8.0, 335.0, 25.0, 310.0, 350.0, 40.0]},
	"acido": {"hues": [75.0, 105.0, 58.0, 130.0, 90.0, 160.0]},
	"oro": {"hues": [44.0, 38.0, 50.0, 34.0, 46.0, 40.0], "shimmer": 7.0},
	"arcobaleno": {"hues": [0.0], "flow": 36.0},
}

const NO_ADS := "no_ads"
const COLLECTION := "collection"
const STARTER_TOKENS := 10  ## given once with the ad-free pass (or the collection)

## On sale beside the looks. A pack with "tokens" can be bought again and again.
const EXTRAS := {
	"no_ads":
	{
		"name": "RIMUOVI ANNUNCI",
		"price": "2,99 €",
		"about": "Niente annunci. CONTINUA usa i gettoni: i primi 10 sono in regalo",
	},
	"collection":
	{
		"name": "COLLEZIONE COMPLETA",
		"price": "9,99 €",
		"about": "Tutti gli stili, anche quelli che verranno, e niente annunci",
	},
	"tokens_10": {"name": "10 GETTONI", "price": "0,99 €", "tokens": 10},
	"tokens_30": {"name": "30 GETTONI", "price": "1,99 €", "tokens": 30},
	"tokens_100": {"name": "100 GETTONI", "price": "4,99 €", "tokens": 100},
}


## Looks of one kind, in shop order.
static func looks(kind: String) -> Array[String]:
	var out: Array[String] = []
	for id in LOOKS:
		if LOOKS[id]["kind"] == kind:
			out.append(id)
	return out


## Every product in the stores (without PREFIX): the paid looks and the extras.
static func product_ids() -> Array[String]:
	var out: Array[String] = []
	for id in LOOKS:
		if LOOKS[id]["rarity"] != "common":
			out.append(id)
	for id in EXTRAS:
		out.append(id)
	return out


static func is_product(id: String) -> bool:
	return EXTRAS.has(id) or (LOOKS.has(id) and LOOKS[id]["rarity"] != "common")


static func is_consumable(id: String) -> bool:
	return EXTRAS.get(id, {}).has("tokens")


static func price_band(id: String) -> String:
	if EXTRAS.has(id):
		return EXTRAS[id]["price"]
	if LOOKS.has(id):
		return RARITIES[LOOKS[id]["rarity"]]["price"]
	return ""


## Theme hue of a colour look at `score`, stepping every `every` points;
## `time` in seconds moves the looks that shimmer or flow.
static func theme_hue(look: String, score: int, every: int, time: float) -> float:
	var p: Dictionary = PALETTES.get(look, PALETTES["neon"])
	var hues: Array = p["hues"]
	@warning_ignore("integer_division")
	var step: int = score / every
	var h: float = hues[step % hues.size()]
	var flow: float = p.get("flow", 0.0)
	if flow > 0.0:
		h += time * flow + 360.0 * score / (every * 6.0)
	h += sin(time * 2.2) * float(p.get("shimmer", 0.0))
	return fposmod(h, 360.0)
