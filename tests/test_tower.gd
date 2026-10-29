extends SceneTree
## Headless tests for the TORRE rules. Run from the project folder:
##   godot --headless --path . --script res://tests/test_tower.gd
## Exit code 0 = all passed.

const TowerScript := preload("res://scripts/tower.gd")
const DT := 1.0 / 120.0

var _fails := 0


func _init() -> void:
	_test_perfect_bot_survives_and_geometry()
	_test_no_tap_is_late()
	_test_early_jump_is_early()
	_test_hop_before_the_hole_is_safe()
	_test_no_jump_in_the_air()
	_test_perfect_detection_and_score()
	_test_difficulty_ramps()
	_test_never_stops_getting_harder()
	_test_chains()
	_test_late_game_stays_fair()
	_test_revive_after_late()
	_test_revive_after_early()
	_test_revive_slows_then_recovers()
	print("all tests passed" if _fails == 0 else "%d failures" % _fails)
	quit(1 if _fails > 0 else 0)


func _check(cond: bool, msg: String) -> void:
	if not cond:
		_fails += 1
		print("FAIL ", msg)


## Jumps on the last frame before the edge.
func _perfect_bot(t) -> void:
	if not t.jumping and t.pos + t.speed * DT > t.current().start:
		t.tap()


## Jumps when the ball is `before` px from the edge.
func _bot_at(before: float) -> Callable:
	return func(t) -> void:
		if not t.jumping and t.current().start - t.pos <= before:
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
			var t = TowerScript.new(width, sd)
			_run(t, _perfect_bot, 120.0)
			_check(
				t.alive,
				"perfect bot fell: width %d seed %d hole %d (%s)" % [width, sd, t.next, t.reason]
			)
			_check(t.cleared > 40, "width %d seed %d: only %d holes" % [width, sd, t.cleared])
			_check_fair(t, "width %d seed %d" % [width, sd])


## Every hole leaves a take-off window of at least WINDOW_END seconds, and a
## jump from the very edge of the previous one lands with time to tap again.
func _check_fair(t, what: String) -> void:
	for k in range(1, t.holes.size()):
		var prev = t.holes[k - 1]
		var h = t.holes[k]
		var v: float = t.speed_for(k)
		_check(
			(t.jump_len - h.length()) / v >= TowerScript.WINDOW_END - 0.0001,
			"hole too long: %s hole %d" % [what, k]
		)
		var landing: float = prev.start + t.jump_len
		var react: float = TowerScript.CHAIN_REACT_END if h.chained else TowerScript.REACT_END
		_check(
			h.start - landing >= v * react - 0.01, "no room after landing: %s hole %d" % [what, k]
		)


func _test_no_tap_is_late() -> void:
	var t = TowerScript.new(720.0, 3)
	_run(t, func(_t) -> void: pass, 10.0)
	_check(
		not t.alive and t.reason == "late" and t.miss == 0,
		"no tap: expected late on hole 0, got %s on %d" % [t.reason, t.miss]
	)


func _test_early_jump_is_early() -> void:
	var t = TowerScript.new(720.0, 3)
	# Take off a jump minus half a hole before the edge: land in the middle of it.
	var h = t.holes[0]
	_run(t, _bot_at(t.jump_len - h.length() * 0.5), 10.0)
	_check(
		not t.alive and t.reason == "early" and t.miss == 0,
		"early jump: expected early on hole 0, got %s on %d" % [t.reason, t.miss]
	)


func _test_hop_before_the_hole_is_safe() -> void:
	var t = TowerScript.new(720.0, 4)
	var hops := [0]
	var bot := func(tt) -> void:
		# One hop far from the edge, then a perfect jump.
		if hops[0] == 0 and not tt.jumping and tt.current().start - tt.pos <= tt.jump_len * 2.5:
			tt.tap()
			hops[0] = 1
		elif hops[0] == 1:
			_perfect_bot(tt)
	_run(t, bot, 8.0)
	_check(t.alive and t.cleared >= 1, "a hop that lands before the hole is harmless")


func _test_no_jump_in_the_air() -> void:
	var t = TowerScript.new(720.0, 5)
	t.start()
	t.update(0.1)
	_check(not t.tap().is_empty(), "first tap jumps")
	t.update(0.05)
	_check(t.tap().is_empty() and t.jumps == 1, "a tap in the air does nothing")


func _test_perfect_detection_and_score() -> void:
	var t = TowerScript.new(720.0, 7)
	var counts := {"perfect": 0, "normal": 0, "n": 0}
	var bot := func(tt) -> void:
		if tt.jumping:
			return
		var h = tt.current()
		# alternate: on the edge, then 70% of the run-up early (valid, not perfect)
		var before := 0.0
		if counts["n"] % 2 == 1:
			before = (tt.jump_len - h.length()) * 0.7
		if tt.pos + tt.speed * DT > h.start - before:
			var r: Dictionary = tt.tap()
			counts["n"] += 1
			counts["perfect" if r["perfect"] else "normal"] += 1
	_run(t, bot, 60.0)
	_check(t.alive, "mixed bot fell on hole %d (%s)" % [t.next, t.reason])
	_check(counts["perfect"] > 5 and counts["normal"] > 5, "perfect/normal mix: %s" % counts)
	_check(
		t.score == t.cleared + t.bonus and t.bonus == t.perfects,
		"score must be holes + perfect bonus"
	)


func _test_difficulty_ramps() -> void:
	var t = TowerScript.new(720.0, 9)
	var start_speed: float = t.speed
	_run(t, _perfect_bot, 120.0)
	_check(t.current().length() > t.holes[0].length(), "holes should get longer")
	_check(t.speed > start_speed, "ball should get faster")


func _test_never_stops_getting_harder() -> void:
	var t = TowerScript.new(720.0, 1)
	# Strictly for the first 300 holes (minutes of flawless play); after that
	# the values are at their limits within float precision.
	for k in 1000:
		var faster: bool = t.speed_for(k + 1) > t.speed_for(k)
		var tighter: bool = t.window_for(k + 1) < t.window_for(k)
		if k >= 300:
			faster = t.speed_for(k + 1) >= t.speed_for(k)
			tighter = t.window_for(k + 1) <= t.window_for(k)
		_check(faster, "speed stops growing at hole %d" % k)
		_check(tighter, "window stops shrinking at hole %d" % k)
	_check(t.speed_for(5000) <= TowerScript.V_END * t.unit, "speed stays below its limit")
	_check(t.window_for(5000) >= TowerScript.WINDOW_END, "window stays above its limit")
	# Never easier than before the endless ramp: 3.2 px/s more per hole up to
	# 330, and holes 0.8% of a jump longer per hole up to 72%.
	for k in 200:
		var old_v := minf(330.0, 150.0 + 3.2 * k)
		var old_hole := minf(0.72, 0.4 + 0.008 * k)
		var old_window := (1.0 - old_hole) * TowerScript.JUMP_LEN / old_v
		_check(t.speed_for(k) >= old_v * t.unit - 0.01, "slower than before at hole %d" % k)
		_check(
			t.window_for(k) <= old_window + 0.015, "window much wider than before at hole %d" % k
		)
	# On the ramp itself: later stretches are shorter and holes longer.
	var u = TowerScript.new(720.0, 4)
	while u.holes.size() < 400:
		u.pos += 10000.0
		u._ensure_ahead()
	_check(_mean_gap(u, 150, 250) < _mean_gap(u, 20, 70), "ramp between holes should shrink")
	_check(u.holes[300].length() > u.holes[60].length(), "holes keep getting longer")


func _mean_gap(t, from: int, to: int) -> float:
	var sum := 0.0
	for k in range(from, to):
		sum += (t.holes[k].start - t.holes[k - 1].end) / t.speed_for(k)
	return sum / (to - from)


func _test_chains() -> void:
	var chains := 0
	for sd in range(1, 11):
		var t = TowerScript.new(720.0, sd)
		while t.holes.size() < 300:
			t.pos += 10000.0
			t._ensure_ahead()
		var run := 1
		for h in t.holes:
			if h.chained:
				chains += 1
				run += 1
				_check(h.index >= TowerScript.CHAIN_FROM, "chain too early (seed %d)" % sd)
				_check(run <= TowerScript.CHAIN_MAX, "chain too long (seed %d)" % sd)
			else:
				run = 1
	_check(chains > 100, "chains should be common higher up: %d" % chains)


## A frame-perfect player far up the tower, where every value is near its limit.
func _test_late_game_stays_fair() -> void:
	for sd in range(1, 6):
		var t = TowerScript.new(720.0, sd)
		_run(t, _perfect_bot, 400.0)
		_check(t.alive, "late game: perfect bot fell, seed %d hole %d" % [sd, t.next])
		_check(t.cleared > 300, "late game: only %d holes (seed %d)" % [t.cleared, sd])
		_check_fair(t, "late game seed %d" % sd)


## Perfect bot that stops jumping once it reaches hole `stop_at`.
func _bot_until(stop_at: int) -> Callable:
	return func(tt) -> void:
		if tt.next < stop_at:
			_perfect_bot(tt)


func _test_revive_after_late() -> void:
	for sd in range(1, 11):
		var t = TowerScript.new(720.0, sd)
		_check(not t.can_revive(), "no revive before the run starts (seed %d)" % sd)
		_run(t, _bot_until(15), 120.0)
		_check(not t.alive and t.reason == "late", "seed %d: expected late death" % sd)
		var next_before: int = t.next
		var score_before: int = t.score
		_check(t.revive(), "seed %d: first revive must be allowed" % sd)
		_check(t.alive and t.reason == "" and t.miss == -1, "seed %d: alive again" % sd)
		_check(
			t.next == next_before and t.score == score_before,
			"seed %d: revive must keep hole and score" % sd
		)
		_check(t.pos == t.holes[t.next - 1].end, "seed %d: back after the last hole jumped" % sd)
		_run(t, _perfect_bot, 60.0)
		_check(t.alive, "seed %d: perfect bot fell after revive on hole %d" % [sd, t.next])
		_run(t, func(_t) -> void: pass, 20.0)
		_check(not t.alive, "seed %d: should fall without taps" % sd)
		_check(not t.can_revive() and not t.revive(), "seed %d: only one revive per run" % sd)


func _test_revive_after_early() -> void:
	var t = TowerScript.new(720.0, 11)
	var bot := func(tt) -> void:
		if tt.next < 8:
			_perfect_bot(tt)
		elif (
			not tt.jumping
			and tt.current().start - tt.pos <= tt.jump_len - tt.current().length() * 0.5
		):
			tt.tap()  # lands in the middle of the hole
	_run(t, bot, 120.0)
	_check(not t.alive and t.reason == "early", "early: expected early death, got %s" % t.reason)
	_check(t.revive(), "early: revive must be allowed")
	_check(not t.jumping and t.height == 0.0, "early: back on the ramp after revive")
	_run(t, _perfect_bot, 60.0)
	_check(t.alive, "early: perfect bot fell after revive on hole %d" % t.next)


func _test_revive_slows_then_recovers() -> void:
	var t = TowerScript.new(720.0, 13)
	_run(t, _bot_until(30), 200.0)
	t.revive()
	t.update(DT)
	_check(t.speed < t.speed_for(t.cleared) * 0.5, "revive: ball should start slow")
	_run(t, _perfect_bot, TowerScript.REVIVE_RECOVER + 0.1)
	_check(
		absf(t.speed - t.speed_for(t.cleared)) < 0.01,
		"revive: back to full speed after the recovery time"
	)
