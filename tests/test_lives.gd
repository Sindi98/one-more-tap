extends SceneTree
## Headless tests for the lives. Run from the project folder:
##   godot --headless --path . --script res://tests/test_lives.gd
## Exit code 0 = all passed.

const LivesScript := preload("res://scripts/lives.gd")
const MAX: int = LivesScript.MAX
const REFILL: float = LivesScript.REFILL_SECONDS

var _fails := 0


func _init() -> void:
	_test_each_run_costs_a_life()
	_test_lives_come_back_one_at_a_time()
	_test_waiting_never_goes_past_max()
	_test_refill()
	_test_clock_going_back()
	_test_saved_values_are_clamped()
	print("all tests passed" if _fails == 0 else "%d failures" % _fails)
	quit(1 if _fails > 0 else 0)


func _check(cond: bool, msg: String) -> void:
	if not cond:
		_fails += 1
		print("FAIL ", msg)


func _test_each_run_costs_a_life() -> void:
	var l = LivesScript.new()
	_check(l.count == MAX and l.seconds_to_next(0.0) == 0, "starts full, nothing to wait for")
	for i in MAX:
		_check(l.use(10.0 + i), "run %d allowed" % i)
	_check(l.count == 0, "all lives spent")
	_check(not l.use(20.0), "no run without lives")
	_check(l.count == 0, "a refused run costs nothing")


func _test_lives_come_back_one_at_a_time() -> void:
	var l = LivesScript.new()
	l.use(100.0)
	l.use(110.0)
	_check(
		l.seconds_to_next(100.0 + REFILL - 1.0) == 1, "the wait starts with the first life spent"
	)
	l.update(100.0 + REFILL)
	_check(l.count == MAX - 1, "one life back after one wait")
	_check(l.seconds_to_next(100.0 + REFILL) == int(REFILL), "the next one needs a full wait again")
	l.update(100.0 + REFILL * 2.0)
	_check(l.count == MAX, "both back after two waits")


func _test_waiting_never_goes_past_max() -> void:
	var l = LivesScript.new()
	for i in MAX:
		l.use(0.0)
	l.update(REFILL * 100.0)
	_check(l.count == MAX, "a long wait fills up to MAX, not beyond")
	_check(
		l.use(REFILL * 100.0) and l.seconds_to_next(REFILL * 100.0) == int(REFILL),
		"and the clock restarts"
	)


func _test_refill() -> void:
	var l = LivesScript.new()
	for i in MAX:
		l.use(0.0)
	l.refill()
	_check(l.count == MAX and l.seconds_to_next(5.0) == 0, "a video gives every life back")


func _test_clock_going_back() -> void:
	var l = LivesScript.new()
	for i in MAX:
		l.use(1000.0)
	l.update(10.0)  # the phone's clock was moved back
	_check(l.count == 0, "moving the clock back gives nothing")
	_check(l.seconds_to_next(10.0) == int(REFILL), "and the wait starts again from now")
	l.update(10.0 + REFILL)
	_check(l.count == 1, "lives still come back afterwards")


func _test_saved_values_are_clamped() -> void:
	_check(LivesScript.new(99, 0.0).count == MAX, "a broken save cannot give extra lives")
	_check(LivesScript.new(-3, 0.0).count == 0, "nor negative ones")
