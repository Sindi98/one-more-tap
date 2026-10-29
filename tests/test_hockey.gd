extends SceneTree
## Headless tests for the AIR HOCKEY rules. Run from the project folder:
##   godot --headless --path . --script res://tests/test_hockey.gd
## Exit code 0 = all passed.

const HockeyScript := preload("res://scripts/hockey.gd")
const DT := 1.0 / 60.0

var _fails := 0


func _init() -> void:
	_test_mallets_stay_in_their_half()
	_test_mallet_speed_is_limited()
	_test_goal_and_serve()
	_test_end_wall_beside_the_goal()
	_test_posts()
	_test_no_tunnelling()
	_test_swing_never_misses()
	_test_win_ends_the_match()
	_test_seven_seconds()
	_test_guests_leave_goals_to_the_host()
	_test_snapshot_round_trip()
	_test_bad_snapshots_are_ignored()
	_test_bot_can_be_beaten()
	_test_bots_finish_a_match()
	print("all tests passed" if _fails == 0 else "%d failures" % _fails)
	quit(1 if _fails > 0 else 0)


func _check(cond: bool, msg: String) -> void:
	if not cond:
		_fails += 1
		print("FAIL ", msg)


## A match with the puck in play at once, the mallets out of the way in
## opposite corners.
func _open_match(size := 1):
	var h = HockeyScript.new(size, 5, 7)
	h.serve = 0.0
	for m in h.mallets:
		var corner := Vector2(556.0, 44.0) if m.team == 1 else Vector2(44.0, 1036.0)
		m.pos = corner
		m.target = corner
	return h


func _run(h, seconds: float) -> void:
	var t := 0.0
	while t < seconds and not h.is_over():
		h.update(DT)
		t += DT


## On the table or in a goal mouth, never inside a wall.
func _puck_inside(h) -> bool:
	var p: Vector2 = h.puck
	var r: float = HockeyScript.PUCK_RADIUS
	var mid: float = HockeyScript.WIDTH * 0.5
	var half_goal: float = HockeyScript.GOAL_WIDTH * 0.5
	if p.y >= 0.0 and p.y <= HockeyScript.HEIGHT:
		var in_x: bool = p.x >= r - 0.01 and p.x <= HockeyScript.WIDTH - r + 0.01
		var in_y: bool = p.y >= r - 0.01 and p.y <= HockeyScript.HEIGHT - r + 0.01
		return in_x and (absf(p.x - mid) <= half_goal or in_y)
	return absf(p.x - mid) <= half_goal - r + 0.01


func _test_mallets_stay_in_their_half() -> void:
	var h = HockeyScript.new(2)
	for i in h.mallets.size():
		h.set_target(i, Vector2(-500.0, 5000.0) if i % 2 == 0 else Vector2(900.0, -900.0))
	_run(h, 2.0)
	var r: float = HockeyScript.MALLET_RADIUS
	for m in h.mallets:
		var lo: float = HockeyScript.HEIGHT * 0.5 + r if m.team == 0 else r
		var hi: float = HockeyScript.HEIGHT - r if m.team == 0 else HockeyScript.HEIGHT * 0.5 - r
		_check(m.pos.y >= lo - 0.01 and m.pos.y <= hi + 0.01, "mallet left its half: %s" % m.pos)
		_check(
			m.pos.x >= r - 0.01 and m.pos.x <= HockeyScript.WIDTH - r + 0.01, "mallet off the table"
		)
	h.set_target(0, Vector2(NAN, 900.0))
	_check(h.mallets[0].target.is_finite(), "a NaN target is ignored")


func _test_mallet_speed_is_limited() -> void:
	var h = _open_match()
	var m = h.mallets[0]
	var from: Vector2 = m.pos
	h.set_target(0, Vector2(556.0, 600.0))
	h.update(0.05)
	var moved: float = m.pos.distance_to(from)
	_check(moved <= HockeyScript.MALLET_SPEED * 0.05 + 0.5, "mallet too fast: %f px" % moved)
	_check(moved > HockeyScript.MALLET_SPEED * 0.05 * 0.9, "mallet too slow: %f px" % moved)


func _test_goal_and_serve() -> void:
	var h = _open_match()
	var goals := []
	h.goal.connect(func(team: int) -> void: goals.append(team))
	h.puck = Vector2(300.0, 540.0)
	h.puck_vel = Vector2(0.0, -1500.0)
	_run(h, 1.0)
	_check(goals == [0], "a straight shot up scores for the bottom team: %s" % [goals])
	_check(h.score == [1, 0], "score after the goal: %s" % [h.score])
	_check(h.puck.distance_to(Vector2(300.0, 270.0)) < 1.0, "the top team serves: %s" % h.puck)
	_check(h.side == 1 and h.held_for < 0.5, "the top team's seven seconds start")
	h.puck = Vector2(300.0, 540.0)
	h.puck_vel = Vector2(0.0, 1500.0)
	h.serve = 0.0
	_run(h, 1.0)
	_check(h.score == [1, 1], "and the top team scores down: %s" % [h.score])


func _test_end_wall_beside_the_goal() -> void:
	var h = _open_match()
	h.puck = Vector2(80.0, 540.0)
	h.puck_vel = Vector2(0.0, -1500.0)
	var bounces := [0]
	h.bounced.connect(func(_s: float) -> void: bounces[0] += 1)
	_run(h, 0.4)
	_check(h.score == [0, 0], "beside the goal: no goal")
	_check(h.puck_vel.y > 0.0 and bounces[0] > 0, "beside the goal: the puck comes back")


func _test_posts() -> void:
	var h = _open_match()
	var post := Vector2(HockeyScript.WIDTH * 0.5 - HockeyScript.GOAL_WIDTH * 0.5, 0.0)
	h.puck = post + Vector2(0.0, 300.0)
	h.puck_vel = Vector2(0.0, -1200.0)
	_run(h, 0.5)
	_check(h.score == [0, 0], "straight at the post: no goal")
	_check(h.puck_vel.y > 0.0, "straight at the post: it bounces back")
	_check(_puck_inside(h), "the post never lets the puck into the wall")


func _test_no_tunnelling() -> void:
	for off in range(-35, 36, 5):
		var h = _open_match()
		var m = h.mallets[0]
		m.pos = Vector2(300.0 + off, 900.0)
		m.target = m.pos
		h.puck = Vector2(300.0, 600.0)
		h.puck_vel = Vector2(0.0, HockeyScript.PUCK_MAX)
		_run(h, 0.5)
		_check(h.puck.y < m.pos.y, "a puck at full speed went through a mallet, offset %d" % off)


func _test_swing_never_misses() -> void:
	for x in range(100, 501, 50):
		var h = _open_match()
		var hits := [0]
		h.hit.connect(func(_s: float) -> void: hits[0] += 1)
		h.mallets[0].pos = Vector2(x, 1000.0)
		h.puck = Vector2(300.0, 700.0)
		h.set_target(0, Vector2(300.0, 560.0))
		_run(h, 0.3)
		_check(hits[0] > 0 and h.puck.y < 700.0, "a fast swing from x %d went through the puck" % x)


func _test_win_ends_the_match() -> void:
	var h = HockeyScript.new(1, 3, 7)
	var won := [-1]
	h.won.connect(func(team: int) -> void: won[0] = team)
	for k in 3:
		h.serve = 0.0
		h.puck = Vector2(300.0, 540.0)
		h.puck_vel = Vector2(0.0, 1800.0)
		h.mallets[0].pos = Vector2(44.0, 1036.0)
		h.mallets[0].target = h.mallets[0].pos
		_run(h, 1.0)
	_check(h.is_over() and h.winner == 1 and won[0] == 1, "three goals win: %s" % [h.score])
	var puck: Vector2 = h.puck
	h.puck_vel = Vector2(500.0, 500.0)
	h.update(0.5)
	_check(h.puck == puck and h.score == [0, 3], "nothing moves after the end")


func _test_seven_seconds() -> void:
	var h = _open_match()
	var held := []
	h.held.connect(func(team: int) -> void: held.append(team))
	h.puck = Vector2(300.0, 800.0)
	h.puck_vel = Vector2.ZERO
	_run(h, HockeyScript.HOLD_LIMIT - 0.5)
	_check(held.is_empty(), "the bottom team still has the puck")
	_run(h, 1.0)
	_check(held == [0], "seven seconds in a half: the puck goes to the other team")
	_check(h.puck.y < HockeyScript.HEIGHT * 0.5 and h.serve > 0.0, "served in the top half")


func _test_guests_leave_goals_to_the_host() -> void:
	var h = _open_match()
	h.scoring = false
	h.puck = Vector2(300.0, 540.0)
	h.puck_vel = Vector2(0.0, -1500.0)
	_run(h, 2.0)
	_check(h.score == [0, 0], "a guest never scores by itself")
	_check(h.puck.y < 0.0 and h.puck_vel == Vector2.ZERO, "the puck rests in the goal")
	h.puck = Vector2(300.0, 800.0)
	h.puck_vel = Vector2.ZERO
	_run(h, HockeyScript.HOLD_LIMIT + 1.0)
	_check(h.puck.y > HockeyScript.HEIGHT * 0.5, "a guest never serves by itself")


func _test_snapshot_round_trip() -> void:
	var host = _open_match(2)
	host.puck = Vector2(210.0, 333.0)
	host.puck_vel = Vector2(-400.0, 250.0)
	host.score.assign([2, 1])
	host.mallets[2].pos = Vector2(150.0, 120.0)
	var guest = HockeyScript.new(2)
	guest.scoring = false
	var goals := []
	guest.goal.connect(func(team: int) -> void: goals.append(team))
	guest.apply_snapshot(host.snapshot(), 1)
	_check(guest.puck.distance_to(host.puck) < 0.01, "puck from the snapshot")
	_check(guest.puck_vel.distance_to(host.puck_vel) < 0.01, "puck speed from the snapshot")
	_check(guest.score == [2, 1] and goals == [0, 1], "score and goals from the snapshot")
	_check(guest.mallets[2].pos.distance_to(Vector2(150.0, 120.0)) < 0.01, "a far mallet jumps")
	_check(
		guest.mallets[1].pos == HockeyScript.home(0, 1, 2),
		"the guest's own mallet stays where its finger put it"
	)


func _test_bad_snapshots_are_ignored() -> void:
	var guest = HockeyScript.new(1)
	var puck: Vector2 = guest.puck
	guest.apply_snapshot(PackedFloat32Array([1.0, 2.0, 3.0]))
	var s: PackedFloat32Array = guest.snapshot()
	s[0] = NAN
	guest.apply_snapshot(s)
	_check(guest.puck == puck, "short or broken snapshots change nothing")


## Fast shots well placed, straight or off a side wall: a bot keeps out
## most of them, not all.
func _test_bot_can_be_beaten() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var saved := 0
	var total := 200
	for k in total:
		var h = _open_match()
		h.mallets[0].bot = true
		h.mallets[0].pos = Vector2(300.0, 930.0)
		h.mallets[0].target = h.mallets[0].pos
		h.puck = Vector2(rng.randf_range(60.0, 540.0), rng.randf_range(300.0, 520.0))
		h._seen = h.puck
		var room: float = HockeyScript.GOAL_WIDTH * 0.5 - HockeyScript.PUCK_RADIUS
		var side := -1.0 if rng.randf() < 0.5 else 1.0
		var x: float = 300.0 + side * rng.randf_range(room * 0.5, room * 0.95)
		if rng.randf() < 0.3:
			var r: float = HockeyScript.PUCK_RADIUS
			var wall: float = r if rng.randf() < 0.5 else HockeyScript.WIDTH - r
			x = 2.0 * wall - x
		var aim: Vector2 = Vector2(x, HockeyScript.HEIGHT) - h.puck
		h.puck_vel = aim.normalized() * rng.randf_range(1400.0, 2000.0)
		_run(h, 3.0)
		if h.score[1] == 0:
			saved += 1
	_check(saved > total * 0.4, "the bot keeps out too few: %d of %d" % [saved, total])
	_check(saved < total * 0.95, "the bot keeps out too many: %d of %d" % [saved, total])


## Bots against bots: someone always wins, the puck never leaves the table
## and never sits still for long.
func _test_bots_finish_a_match() -> void:
	for size in [1, 2]:
		for sd in range(1, 11):
			var h = HockeyScript.new(size, 5, sd)
			for m in h.mallets:
				m.bot = true
			var t := 0.0
			var still := 0.0
			var worst := 0.0
			var inside := true
			while not h.is_over() and t < 600.0:
				h.update(DT)
				t += DT
				inside = inside and _puck_inside(h)
				if h.serve <= 0.0 and h.puck_vel.length() < 15.0:
					still += DT
					worst = maxf(worst, still)
				else:
					still = 0.0
			var what := "%d vs %d seed %d" % [size, size, sd]
			_check(h.is_over(), "%s: no winner after 10 minutes, %s" % [what, h.score])
			_check(inside, "%s: the puck left the table" % what)
			_check(
				worst < HockeyScript.HOLD_LIMIT + 1.5, "%s: puck still for %.1f s" % [what, worst]
			)
