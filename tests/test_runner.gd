extends SceneTree
## Headless tests for the DINO rules. Run from the project folder:
##   godot --headless --path . --script res://tests/test_runner.gd
## Exit code 0 = all passed.

const RunnerScript := preload("res://scripts/runner.gd")
const DT := 1.0 / 120.0

var _fails := 0


func _init() -> void:
	_test_good_bot_survives_and_layout()
	_test_no_tap_is_late()
	_test_early_jump_is_early()
	_test_jumping_into_a_high_bird()
	_test_buffered_tap_jumps_on_landing()
	_test_score_and_milestones()
	_test_revive()
	_test_revive_slows_then_recovers()
	print("all tests passed" if _fails == 0 else "%d failures" % _fails)
	quit(1 if _fails > 0 else 0)


func _check(cond: bool, msg: String) -> void:
	if not cond:
		_fails += 1
		print("FAIL ", msg)


## The next obstacle to jump: not passed yet, and not a high bird.
func _next_to_jump(r):
	var me: Rect2 = r.dino_box()
	for o in r.obstacles:
		if o.kind == RunnerScript.Kind.BIRD_HIGH:
			continue
		if o.hitbox(RunnerScript.HIT_INSET * r.unit).end.x > me.position.x:
			return o
	return null


## Seconds to wait before the middle of the take-off window for `o` (negative:
## the middle is already behind).
func _wait_for(r, o) -> float:
	var me: Rect2 = r.dino_box()
	var box: Rect2 = o.hitbox(RunnerScript.HIT_INSET * r.unit)
	var v: float = r.speed
	var g: float = RunnerScript.GRAVITY * r.unit
	var v0: float = RunnerScript.JUMP_V * r.unit
	var need: float = box.end.y - RunnerScript.DINO_HIT.position.y * r.unit
	var root := sqrt(v0 * v0 - 2.0 * g * need)
	var t1 := (v0 - root) / g  # feet rise above the obstacle
	var t2 := (v0 + root) / g  # and come back down
	var t_enter := (box.position.x - me.end.x) / v
	var t_exit := (box.end.x - me.position.x) / v
	return ((t_exit - t2) + (t_enter - t1)) * 0.5


## Jumps in the middle of each take-off window.
func _good_bot(r) -> void:
	if r.airborne:
		return
	var o = _next_to_jump(r)
	if o != null and _wait_for(r, o) <= 0.0:
		r.tap()


func _run(r, bot: Callable, seconds: float) -> void:
	r.start()
	var time := 0.0
	while time < seconds and r.alive:
		bot.call(r)
		r.update(DT)
		time += DT


func _test_good_bot_survives_and_layout() -> void:
	var kinds := {}
	for width in [320.0, 720.0]:
		for sd in range(1, 21):
			var r = RunnerScript.new(width, sd)
			var seen: Array = []
			var watch := func(rr) -> void:
				for o in rr.obstacles:
					if not seen.has(o):
						seen.append(o)
				_good_bot(rr)
			_run(r, watch, 150.0)
			_check(
				r.alive,
				(
					"good bot hit something: width %d seed %d score %d (%s)"
					% [width, sd, r.score, r.reason]
				)
			)
			_check(
				r.speed >= RunnerScript.V_MAX * r.unit - 0.01,
				"should reach top speed (seed %d)" % sd
			)
			for i in seen.size():
				var o = seen[i]
				kinds[o.kind] = true
				var points := int(o.x / r.unit * RunnerScript.POINTS_PER_PX)
				var bird: bool = o.kind >= RunnerScript.Kind.BIRD_LOW
				_check(
					not bird or points >= RunnerScript.BIRDS_FROM,
					"bird too early: width %d seed %d at %d points" % [width, sd, points]
				)
				if not bird:
					var v := minf(
						RunnerScript.V_MAX, RunnerScript.V_START + o.x / r.unit * RunnerScript.ACCEL
					)
					_check(
						r.window(o, v * r.unit) >= RunnerScript.MIN_WINDOW,
						"cacti too wide: width %d seed %d obstacle %d" % [width, sd, o.index]
					)
				if i > 0:
					_check(o.x > seen[i - 1].right(), "obstacles overlap: seed %d" % sd)
	for k in [
		RunnerScript.Kind.SMALL,
		RunnerScript.Kind.LARGE,
		RunnerScript.Kind.BIRD_LOW,
		RunnerScript.Kind.BIRD_HIGH
	]:
		_check(kinds.has(k), "obstacle kind %d never appeared" % k)


func _test_no_tap_is_late() -> void:
	var r = RunnerScript.new(720.0, 3)
	_run(r, func(_r) -> void: pass, 10.0)
	_check(
		not r.alive and r.reason == "late" and r.hit.index == 0,
		"no tap: expected late on obstacle 0, got %s" % r.reason
	)


func _test_early_jump_is_early() -> void:
	var r = RunnerScript.new(720.0, 3)
	var bot := func(rr) -> void:
		var o = rr.obstacles[0]
		# Take off when the obstacle is most of a jump away: come down on it.
		if not rr.airborne and o.x - rr.dino_box().end.x <= rr.speed * rr.air_time() * 0.85:
			rr.tap()
	_run(r, bot, 10.0)
	_check(not r.alive and r.reason == "early", "early jump: expected early, got %s" % r.reason)


func _test_jumping_into_a_high_bird() -> void:
	var found := false
	for sd in range(1, 40):
		var r = RunnerScript.new(720.0, sd)
		var bot := func(rr) -> void:
			if rr.airborne:
				return
			for o in rr.obstacles:
				if o.passed:
					continue
				if o.kind == RunnerScript.Kind.BIRD_HIGH:
					if o.x - rr.dino_box().end.x < rr.speed * 0.15:
						rr.tap()  # jump right into it
				elif _wait_for(rr, o) <= 0.0:
					rr.tap()
				return
		_run(r, bot, 150.0)
		if not r.alive and r.hit != null and r.hit.kind == RunnerScript.Kind.BIRD_HIGH:
			_check(r.reason == "high", "high bird: expected high, got %s" % r.reason)
			found = true
			break
	_check(found, "high bird: no seed produced the case")


func _test_buffered_tap_jumps_on_landing() -> void:
	var r = RunnerScript.new(720.0, 5)
	r.start()
	r.tap()
	var time := 0.0
	var tapped := false
	while r.jumps < 2 and time < 2.0:
		# Tap again shortly before landing, while still in the air.
		var t_land: float = (
			(r.vy + sqrt(r.vy * r.vy + 2.0 * RunnerScript.GRAVITY * r.unit * r.height))
			/ (RunnerScript.GRAVITY * r.unit)
		)
		if not tapped and r.airborne and r.vy < 0.0 and t_land < RunnerScript.JUMP_BUFFER * 0.5:
			_check(r.tap().is_empty(), "buffer: a tap in the air does not jump at once")
			tapped = true
		r.update(DT)
		time += DT
	_check(tapped and r.jumps == 2 and r.airborne, "buffer: the dino jumps again on landing")


func _test_score_and_milestones() -> void:
	var r = RunnerScript.new(720.0, 7)
	var marks: Array = []
	r.milestone.connect(func(s: int) -> void: marks.append(s))
	_run(r, _good_bot, 40.0)
	_check(r.score == int(r.x / r.unit * RunnerScript.POINTS_PER_PX), "score is the distance")
	@warning_ignore("integer_division")
	var expected: int = r.score / RunnerScript.MILESTONE
	_check(
		marks.size() == expected,
		"one milestone per 100 points: %d vs %d" % [marks.size(), expected]
	)
	_check(r.cleared > 10 and r.jumps >= r.cleared - 5, "obstacles passed: %d" % r.cleared)


func _test_revive() -> void:
	for sd in range(1, 11):
		var r = RunnerScript.new(720.0, sd)
		_check(not r.can_revive(), "no revive before the run starts (seed %d)" % sd)
		var bot := func(rr) -> void:
			if rr.score < 400:
				_good_bot(rr)
		_run(r, bot, 120.0)
		_check(not r.alive, "seed %d: should hit something without taps" % sd)
		var score_before: int = r.score
		var x_before: float = r.x
		_check(r.revive(), "seed %d: first revive must be allowed" % sd)
		_check(r.alive and r.reason == "" and not r.airborne, "seed %d: alive again" % sd)
		_check(r.score == score_before and r.x == x_before, "seed %d: revive keeps score" % sd)
		var me: Rect2 = r.dino_box()
		var clear := true
		for o in r.obstacles:
			if o.right() >= r.x and o.x - me.end.x < r.speed * RunnerScript.REVIVE_RECOVER:
				clear = false
		_check(clear, "seed %d: the way is clear after revive" % sd)
		_run(r, _good_bot, 60.0)
		_check(r.alive, "seed %d: good bot hit something after revive (%s)" % [sd, r.reason])
		_run(r, func(_r) -> void: pass, 20.0)
		_check(not r.alive, "seed %d: should hit something without taps" % sd)
		_check(not r.can_revive() and not r.revive(), "seed %d: only one revive per run" % sd)


func _test_revive_slows_then_recovers() -> void:
	var r = RunnerScript.new(720.0, 13)
	var bot := func(rr) -> void:
		if rr.score < 600:
			_good_bot(rr)
	_run(r, bot, 200.0)
	r.revive()
	r.update(DT)
	var full := minf(RunnerScript.V_MAX, RunnerScript.V_START + r.x / r.unit * RunnerScript.ACCEL)
	_check(r.speed < full * r.unit * 0.5, "revive: dino should start slow")
	_run(r, _good_bot, RunnerScript.REVIVE_RECOVER + 0.1)
	full = minf(RunnerScript.V_MAX, RunnerScript.V_START + r.x / r.unit * RunnerScript.ACCEL)
	# Speed grows with distance: compare loosely, the last step moved the dino on.
	_check(r.speed > full * r.unit * 0.998, "revive: back to full speed after the recovery time")
