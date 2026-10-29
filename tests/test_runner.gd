extends SceneTree
## Headless tests for the DINO rules. Run from the project folder:
##   godot --headless --path . --script res://tests/test_runner.gd
## Exit code 0 = all passed.

const RunnerScript := preload("res://scripts/runner.gd")
const DT := 1.0 / 120.0
const OLD_V_MAX := 540.0  ## top speed before the endless ramp

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
	_test_never_stops_getting_harder()
	_test_chains_and_big_groups()
	_test_late_game_stays_fair()
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
				r.speed > OLD_V_MAX * r.unit,
				"should run faster than the old top speed (seed %d)" % sd
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
					_check(
						r.window(o, r.speed_at(o.x)) >= r.min_window_at(o.x) - 0.0001,
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
	_check(r.speed < r.speed_at(r.x) * 0.5, "revive: dino should start slow")
	_run(r, _good_bot, RunnerScript.REVIVE_RECOVER + 0.1)
	# Speed grows with distance: compare loosely, the last step moved the dino on.
	_check(r.speed > r.speed_at(r.x) * 0.998, "revive: back to full speed after the recovery time")


## Points scored at distance `at`.
func _points(r, at: float) -> float:
	return at / r.unit * RunnerScript.POINTS_PER_PX


func _test_never_stops_getting_harder() -> void:
	var r = RunnerScript.new(720.0, 1)
	var step: float = 10.0 / RunnerScript.POINTS_PER_PX * r.unit  # 10 points
	# Strictly up to 5000 points (a very long run); then within float precision.
	for i in 1000:
		var at: float = i * step
		var strict := i < 500
		var v0: float = r.speed_at(at)
		var v1: float = r.speed_at(at + step)
		_check(v1 > v0 if strict else v1 >= v0, "speed stops growing at %d points" % (i * 10))
		var a0: float = r.react_at(at)
		var a1: float = r.react_at(at + step)
		_check(a1 < a0 if strict else a1 <= a0, "reaction stops shrinking at %d points" % (i * 10))
		var w0: float = r.min_window_at(at)
		var w1: float = r.min_window_at(at + step)
		_check(w1 < w0 if strict else w1 <= w0, "window stops shrinking at %d points" % (i * 10))
		# Never easier than before the endless ramp: 0.006 px/s more per pixel
		# up to 540, 0.36 s to react, a 0.12 s window.
		var old_v := minf(OLD_V_MAX, 230.0 + at / r.unit * 0.006)
		_check(v0 >= old_v * r.unit - 0.01, "slower than before at %d points" % (i * 10))
		_check(a0 <= 0.36 and w0 <= 0.12, "more forgiving than before at %d points" % (i * 10))
	var far: float = 1e9
	_check(r.speed_at(far) <= RunnerScript.V_END * r.unit, "speed stays below its limit")
	_check(r.react_at(far) >= RunnerScript.REACT_END, "reaction stays above its limit")
	_check(r.min_window_at(far) >= RunnerScript.MIN_WINDOW_END, "window stays above its limit")


## Obstacles generated far ahead, without running.
func _layout(sd: int, count: int):
	var r = RunnerScript.new(720.0, sd)
	while r.obstacles.size() < count:
		r.x = r._next_x
		r._ensure_ahead()
	return r


func _test_chains_and_big_groups() -> void:
	var chains := 0
	var fours := 0
	var early := {"birds": 0, "all": 0}
	var late := {"birds": 0, "all": 0}
	for sd in range(1, 11):
		var r = _layout(sd, 900)
		var run := 1
		for o in r.obstacles:
			var points := _points(r, o.x)
			var bucket = early if points < 1000.0 else late
			bucket["all"] += 1
			if o.kind >= RunnerScript.Kind.BIRD_LOW:
				bucket["birds"] += 1
			if o.count == 4:
				fours += 1
				_check(points >= RunnerScript.GROUP4_FROM, "four cacti too early (seed %d)" % sd)
			if o.chained:
				chains += 1
				run += 1
				_check(points >= RunnerScript.CHAIN_FROM, "chain too early (seed %d)" % sd)
				_check(run <= RunnerScript.CHAIN_MAX, "chain too long (seed %d)" % sd)
			else:
				run = 1
	_check(chains > 300, "chains should be common higher up: %d" % chains)
	_check(fours > 50, "groups of four should appear: %d" % fours)
	_check(
		float(late["birds"]) / late["all"] > float(early["birds"]) / early["all"],
		"birds should get more frequent"
	)


## A good player far into the run, where every value is near its limit.
func _test_late_game_stays_fair() -> void:
	for sd in range(1, 6):
		var r = RunnerScript.new(720.0, sd)
		var seen: Array = []
		var watch := func(rr) -> void:
			for o in rr.obstacles:
				if seen.is_empty() or o.index > seen.back().index:
					seen.append(o)
			_good_bot(rr)
		_run(r, watch, 400.0)
		_check(r.alive, "late game: good bot hit something, seed %d score %d" % [sd, r.score])
		_check(r.score > 8000, "late game: only %d points (seed %d)" % [r.score, sd])
		for i in range(1, seen.size()):
			var prev = seen[i - 1]
			var o = seen[i]
			# The gap is fixed when `prev` is placed, at its speed.
			var v: float = r.speed_at(prev.x)
			var react: float = RunnerScript.CHAIN_REACT_END if o.chained else RunnerScript.REACT_END
			_check(
				o.x - prev.right() >= v * (r.air_time() + react) - 0.01,
				"no room after landing: seed %d obstacle %d" % [sd, o.index]
			)
			if o.kind < RunnerScript.Kind.BIRD_LOW:
				_check(
					r.window(o, r.speed_at(o.x)) >= RunnerScript.MIN_WINDOW_END,
					"cacti too wide late: seed %d obstacle %d" % [sd, o.index]
				)
