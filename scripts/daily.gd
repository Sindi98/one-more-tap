class_name Daily
extends RefCounted
## The daily challenge: one track per mode and per day, the same on every
## phone, and the best score of the day for each mode. No continue in it, so
## the scores compare. Pure logic: the caller passes the day (see
## Streak.day_number), so it is testable headless.

## The day of challenge #1. Set it to the launch day before publishing, so the
## first challenge players see is #1. 20756 is 2026-10-30.
const FIRST_DAY := 20756
const SEED_MOD := 2147483647  ## seeds stay below this, and above 0

var day := -1  ## the day the scores below belong to
var best := {}  ## mode -> best score of that day


## The challenge's number, shown and shared: #1 on FIRST_DAY.
static func number(p_day: int) -> int:
	return maxi(1, p_day - FIRST_DAY + 1)


## The seed of a mode's track on a day: the same on every phone and never 0,
## which asks the rules for a random track.
static func seed_for(mode: String, p_day: int) -> int:
	var s := posmod(p_day, SEED_MOD)
	for c in mode.to_utf8_buffer():
		s = (s * 31 + c) % SEED_MOD
	return s + 1


## The game was opened on `today`: another day is another challenge, with no
## scores yet. Returns true when the day changed.
func visit(today: int) -> bool:
	if today == day:
		return false
	day = today
	best.clear()
	return true


func best_of(mode: String) -> int:
	return int(best.get(mode, 0))


## A run of `mode`, started on `run_day`, ended with `score`. Returns true when
## it is the best of the day. A run started before midnight counts for nothing.
func record(mode: String, run_day: int, score: int) -> bool:
	if run_day != day or score <= best_of(mode):
		return false
	best[mode] = score
	return true


func save_to(cfg: ConfigFile) -> void:
	cfg.set_value("daily", "day", day)
	for mode in best:
		cfg.set_value("daily", "best_" + mode, best[mode])


func load_from(cfg: ConfigFile, modes: Array) -> void:
	day = int(cfg.get_value("daily", "day", -1))
	best.clear()
	for mode in modes:
		var score := maxi(0, int(cfg.get_value("daily", "best_" + str(mode), 0)))
		if score > 0:
			best[mode] = score
