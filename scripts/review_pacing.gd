class_name ReviewPacing
extends RefCounted
## When to ask for a store review. Pure logic: the caller passes the clock, so
## it is testable headless.
##
## Only at a happy moment, a record that beats an earlier one (the first run of
## a mode always sets one), once the player knows the game, and rarely: the
## stores show the dialog a few times a year at most anyway, and a player
## asked too often answers with a low rating.

const MIN_RUNS := 15  ## runs finished before the first ask
const MAX_ASKS := 3
const MIN_DAYS := 30.0  ## between two asks

var runs := 0  ## runs finished since the game was installed
var asks := 0
var last_ask := 0.0  ## unix time of the last ask


func _init(p_runs := 0, p_asks := 0, p_last_ask := 0.0) -> void:
	runs = p_runs
	asks = p_asks
	last_ask = p_last_ask


func run_finished() -> void:
	runs += 1


## beat_record: the run that just ended beat an earlier record of its mode.
func should_ask(beat_record: bool, now: float) -> bool:
	if not beat_record or runs < MIN_RUNS or asks >= MAX_ASKS:
		return false
	return asks == 0 or now - last_ask >= MIN_DAYS * 86400.0


func asked(now: float) -> void:
	asks += 1
	last_ask = now
