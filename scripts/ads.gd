class_name Ads
extends Node
## What the game knows about ads: "is there a video?", "show the video", "a run
## ended: interstitial if it is time", the banner of the start screen and the
## privacy entry points.
## Ads are optional: where the AdMob plugin cannot run (desktop builds, headless
## tests), and for players who bought the ad-free pass, every call is a no-op
## and the game plays as if ads did not exist.

signal changed  ## an ad became ready or was used, or consent options changed

## Your ad unit IDs from the AdMob console (they contain a "/"). While empty,
## and in every debug build, Google's test ads are used: never tap your own
## real ads, AdMob may suspend the account for it.
const LIVE_IDS := {
	"Android": {"interstitial": "", "rewarded": "", "banner": ""},
	"iOS": {"interstitial": "", "rewarded": "", "banner": ""},
}
const TEST_IDS := {
	"Android":
	{
		"interstitial": "ca-app-pub-3940256099942544/1033173712",
		"rewarded": "ca-app-pub-3940256099942544/5224354917",
		"banner": "ca-app-pub-3940256099942544/9214589741",
	},
	"iOS":
	{
		"interstitial": "ca-app-pub-3940256099942544/4411468910",
		"rewarded": "ca-app-pub-3940256099942544/1712485313",
		"banner": "ca-app-pub-3940256099942544/2435281174",
	},
}
## Public page with the privacy policy (stores require one, linked in the app).
const PRIVACY_URL := "https://sindi98.github.io/one-more-tap/privacy.html"

const BACKEND_PATH := "res://scripts/admob_backend.gd"
const PLUGIN_PATH := "res://addons/admob/gdscript/src/api/MobileAds.gd"

var pacing: AdPacing

## admob_backend.gd, loaded by path only where the plugin can run, so that
## desktop and test runs never load the plugin's scripts.
var _backend: Node
var _showing := false
var _off := false  ## the ad-free pass was bought


func _ready() -> void:
	pacing = AdPacing.new(_now())


## Called once the save is loaded, unless the player has the ad-free pass: then
## the ad SDK never starts (no consent form, nothing sent to Google).
func start() -> void:
	if _backend != null or _off or not _plugin_can_run():
		return
	_backend = (load(BACKEND_PATH) as GDScript).new()
	add_child(_backend)
	_backend.connect("changed", func() -> void: changed.emit())
	_backend.call("start", _unit_ids())


## False where the plugin cannot run (desktop builds, headless tests) and for
## players with the ad-free pass: the game then plays as if ads did not exist.
func available() -> bool:
	return _backend != null and not _off


## The ad-free pass was bought: no ad shows from now on, in this session too.
func turn_off() -> void:
	if _off:
		return
	_off = true
	set_banner_visible(false)
	changed.emit()


func rewarded_ready() -> bool:
	return _backend != null and not _off and not _showing and _backend.call("rewarded_ready")


## Plays the rewarded video. done.call(earned: bool) when it is closed.
func show_rewarded(done: Callable) -> void:
	if not rewarded_ready():
		done.call(false)
		return
	_showing = true
	_backend.call(
		"show_rewarded",
		func(earned: bool) -> void:
			_showing = false
			pacing.ad_shown(_now())
			done.call(earned)
	)


func run_finished() -> void:
	pacing.run_finished()


## Shows an interstitial if one is due and loaded, and returns true; done.call()
## runs when it is closed. Returns false (and does nothing) otherwise.
func show_interstitial_if_due(done: Callable) -> bool:
	if _backend == null or _off or _showing or not pacing.should_show_interstitial(_now()):
		return false
	if not _backend.call("interstitial_ready"):
		return false
	_showing = true
	_backend.call(
		"show_interstitial",
		func() -> void:
			_showing = false
			pacing.ad_shown(_now())
			done.call()
	)
	return true


## The banner shows on the start screen only, never while playing.
func set_banner_visible(on: bool) -> void:
	if _backend != null:
		_backend.call("set_banner_visible", on and not _off)


## Height of the banner on screen, in viewport units (0 when hidden or not loaded).
func banner_height() -> float:
	if _backend == null or _off:
		return 0.0
	var px: int = _backend.call("banner_height_px")
	var win := float(DisplayServer.window_get_size().y)
	if px <= 0 or win <= 0.0:
		return 0.0
	return px * get_viewport().get_visible_rect().size.y / win


## GDPR (EEA/UK): the player must be able to change the ad consent at any time.
func consent_options_required() -> bool:
	return _backend != null and _backend.call("privacy_options_required")


func show_consent_options() -> void:
	if _backend != null:
		_backend.call("show_privacy_options")


func open_privacy_policy() -> void:
	OS.shell_open(PRIVACY_URL)


func _plugin_can_run() -> bool:
	if not ResourceLoader.exists(PLUGIN_PATH):
		return false  # plugin removed: an ad-free build
	if Engine.has_singleton("PoingGodotAdMob"):
		return true  # Android / iOS export with the native plugin
	# Run from the editor (F5): the plugin shows mock ads. Headless runs: none.
	return OS.has_feature("editor") and DisplayServer.get_name() != "headless"


func _unit_ids() -> Dictionary:
	var platform := "iOS" if OS.get_name() == "iOS" else "Android"
	var live: Dictionary = LIVE_IDS[platform]
	if OS.is_debug_build() or "" in live.values():
		if not OS.is_debug_build():
			push_warning("Ads: release build with Google test ads, set LIVE_IDS in ads.gd")
		return TEST_IDS[platform]
	return live


func _now() -> float:
	return Time.get_ticks_msec() / 1000.0
