extends SceneTree
## Headless tests for the game rules. Run from the project folder:
##   godot --headless --path . --script res://tests/test_track.gd
## Exit code 0 = all passed.

const TrackScript := preload("res://scripts/track.gd")
const DT := 1.0 / 120.0

var _fails := 0


func _init() -> void:
	_test_perfect_bot_survives_and_geometry()
	_test_no_tap_is_late()
	_test_early_tap_is_early()
	_test_double_tap_is_early()
	_test_perfect_detection_and_score()
	_test_difficulty_ramps()
	print("all tests passed" if _fails == 0 else "%d failures" % _fails)
	quit(1 if _fails > 0 else 0)


func _check(cond: bool, msg: String) -> void:
	if not cond:
		_fails += 1
		print("FAIL ", msg)


## Taps on the first frame the ball passes the corner.
func _perfect_bot(t) -> void:
	var s = t.current()
	if t.turns == t.seg and s.along(t.ball) >= s.length:
		t.tap()


func _run(t, bot: Callable, seconds: float) -> void:
	t.start()
	var time := 0.0
	while time < seconds and t.alive:
		bot.call(t)
		t.update(DT)
		time += DT


func _test_perfect_bot_survives_and_geometry() -> void:
	for width in [320.0, 390.0, 720.0]:
		for sd in range(1, 21):
			var t = TrackScript.new(width, 1280.0, sd)
			_run(t, _perfect_bot, 120.0)
			_check(
				t.alive,
				"perfect bot fell: width %d seed %d platform %d (%s)" % [width, sd, t.seg, t.reason]
			)
			for s in t.segs:
				var e: Vector2 = s.end_point()
				_check(
					e.x >= t.margin - 0.01 and e.x <= width - t.margin + 0.01,
					"corner off-screen: width %d seed %d platform %d" % [width, sd, s.index]
				)
				if s.index > 0:
					_check(
						s.length >= s.w * TrackScript.MIN_LEN_FACTOR - 0.01,
						"platform too short: width %d seed %d platform %d" % [width, sd, s.index]
					)


func _test_no_tap_is_late() -> void:
	var t = TrackScript.new(720.0, 1280.0, 3)
	_run(t, func(_t) -> void: pass, 10.0)
	_check(
		not t.alive and t.reason == "late" and t.seg == 0,
		"no tap: expected late on platform 0, got %s on %d" % [t.reason, t.seg]
	)


func _test_early_tap_is_early() -> void:
	var t = TrackScript.new(720.0, 1280.0, 3)
	t.start()
	t.update(0.05)
	t.tap()
	_run(t, func(_t) -> void: pass, 5.0)
	_check(not t.alive and t.reason == "early", "early tap: expected early, got %s" % t.reason)


func _test_double_tap_is_early() -> void:
	var t = TrackScript.new(720.0, 1280.0, 5)
	var done := [false]
	var bot := func(tt) -> void:
		var s = tt.current()
		if not done[0] and tt.turns == tt.seg and s.along(tt.ball) >= s.length:
			tt.tap()
			tt.tap()
			done[0] = true
	_run(t, bot, 20.0)
	_check(not t.alive and t.reason == "early", "double tap: expected early, got %s" % t.reason)


func _test_perfect_detection_and_score() -> void:
	var t = TrackScript.new(720.0, 1280.0, 7)
	var counts := {"perfect": 0, "normal": 0, "n": 0}
	var bot := func(tt) -> void:
		var s = tt.current()
		# alternate: exactly on the corner, then 30% of the width early (valid, not perfect)
		var early: float = s.w * 0.3 if counts["n"] % 2 == 1 else 0.0
		if tt.turns == tt.seg and s.along(tt.ball) >= s.length - early:
			var r: Dictionary = tt.tap()
			counts["n"] += 1
			counts["perfect" if r["perfect"] else "normal"] += 1
	_run(t, bot, 60.0)
	_check(counts["perfect"] > 5 and counts["normal"] > 5, "perfect/normal mix: %s" % counts)
	_check(
		t.score == t.seg + t.bonus and t.bonus == t.perfects,
		"score must be platforms + perfect bonus"
	)


func _test_difficulty_ramps() -> void:
	var t = TrackScript.new(720.0, 1280.0, 9)
	var start_speed: float = t.speed
	_run(t, _perfect_bot, 120.0)
	_check(t.current().w < t.segs[1].w, "platforms should get narrower")
	_check(t.speed > start_speed, "ball should get faster")
