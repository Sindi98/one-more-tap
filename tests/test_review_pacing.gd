extends SceneTree
## Headless tests for when the game asks for a store review. Run from the project folder:
##   godot --headless --path . --script res://tests/test_review_pacing.gd
## Exit code 0 = all passed.

const ReviewPacingScript := preload("res://scripts/review_pacing.gd")
const MIN_RUNS: int = ReviewPacingScript.MIN_RUNS
const DAY := 86400.0

var _fails := 0


func _init() -> void:
	_test_only_after_a_record()
	_test_not_before_enough_runs()
	_test_spaced_and_limited()
	_test_saved_values()
	print("all tests passed" if _fails == 0 else "%d failures" % _fails)
	quit(1 if _fails > 0 else 0)


func _check(cond: bool, msg: String) -> void:
	if not cond:
		_fails += 1
		print("FAIL ", msg)


func _played(runs: int):
	var p = ReviewPacingScript.new()
	for i in runs:
		p.run_finished()
	return p


func _test_only_after_a_record() -> void:
	var p = _played(MIN_RUNS + 10)
	_check(not p.should_ask(false, 1000.0), "never without a record")
	_check(p.should_ask(true, 1000.0), "after a record, once the player knows the game")


func _test_not_before_enough_runs() -> void:
	var p = _played(MIN_RUNS - 1)
	_check(not p.should_ask(true, 1000.0), "not in the first runs")
	p.run_finished()
	_check(p.should_ask(true, 1000.0), "from MIN_RUNS on")


func _test_spaced_and_limited() -> void:
	var p = _played(MIN_RUNS)
	var now := 5000.0
	for i in ReviewPacingScript.MAX_ASKS:
		_check(p.should_ask(true, now), "ask %d allowed" % i)
		p.asked(now)
		_check(not p.should_ask(true, now + DAY), "not again the next day")
		now += ReviewPacingScript.MIN_DAYS * DAY
	_check(not p.should_ask(true, now + 365.0 * DAY), "never more than MAX_ASKS times")


func _test_saved_values() -> void:
	var p = ReviewPacingScript.new(MIN_RUNS, 1, 100.0)
	_check(not p.should_ask(true, 100.0 + DAY), "the last ask is remembered")
	_check(p.should_ask(true, 100.0 + ReviewPacingScript.MIN_DAYS * DAY), "again after MIN_DAYS")
