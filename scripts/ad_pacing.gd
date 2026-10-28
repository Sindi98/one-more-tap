class_name AdPacing
extends RefCounted
## When to show a full-screen ad between runs. Pure logic: the caller passes
## the clock, so it is testable headless.
##
## An interstitial only ever appears on "retry", never during a run, and at most
## once every few runs and every few minutes. A rewarded ad the player chose to
## watch counts as an ad too, so the two never come back to back.

const RUNS_BETWEEN := 3  ## runs finished before the next interstitial
const MIN_SECONDS := 90.0  ## and at least this long since the last ad (or launch)

var _runs := 0  ## runs finished since the last ad
var _last_ad := 0.0  ## time of the last ad, starts at the launch time


func _init(now: float = 0.0) -> void:
	_last_ad = now


func run_finished() -> void:
	_runs += 1


func should_show_interstitial(now: float) -> bool:
	return _runs >= RUNS_BETWEEN and now - _last_ad >= MIN_SECONDS


## Call whenever a full-screen ad (interstitial or rewarded) was shown.
func ad_shown(now: float) -> void:
	_runs = 0
	_last_ad = now
