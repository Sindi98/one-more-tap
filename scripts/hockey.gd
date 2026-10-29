class_name Hockey
extends RefCounted
## Rules for AIR HOCKEY. Pure logic: no nodes, no network, testable headless.
##
## Two teams of one or two mallets: team 0 (BLUE) defends the goal at the
## bottom of the table, team 1 (RED) the one at the top. Each mallet follows
## its target (where its player's finger is, or what the bot standing in for a
## missing player decides) without leaving its half. The puck glides, bounces
## off the walls and the mallets, and a goal serves it back to the team that
## let it in. A team that keeps the puck in its half for seven seconds loses
## it to the other, as in the real game. The first team to `goals_to_win` wins.
##
## The host runs the real match and sends snapshots; each guest runs a copy
## that the snapshots keep in step, and leaves the goals to the host.

signal goal(team: int)  ## `team` scored
signal hit(strength: float)  ## a mallet struck the puck, 0..1
signal bounced(strength: float)  ## the puck hit a wall or a post, 0..1
signal held(team: int)  ## `team` kept the puck in its half too long: it goes to the other
signal won(team: int)

## The table, in world pixels: the same on every phone.
const WIDTH := 600.0
const HEIGHT := 1080.0
const GOAL_WIDTH := 240.0
const GOAL_DEPTH := 64.0  ## how far the goal goes in behind the end wall
const PUCK_RADIUS := 26.0
const MALLET_RADIUS := 42.0
const MALLET_SPEED := 2400.0  ## px/s: the fastest a mallet follows a finger
const PUCK_MAX := 2000.0  ## px/s
const PUCK_DRAG := 0.22  ## share of its speed the puck loses in a second, about
const WALL_BOUNCE := 0.88
const MALLET_BOUNCE := 0.9
const STEP := 1.0 / 240.0  ## physics substep: the puck never goes through a mallet
const KICKOFF := 1.6  ## seconds the puck waits at the start of a match
const SERVE := 1.0  ## seconds the puck waits after a goal
const HOLD_LIMIT := 7.0  ## seconds a team may keep the puck in its half
const GOALS_TO_WIN := 5
const SNAPSHOT_HEAD := 7  ## numbers before the mallets in a snapshot
## Bots can be beaten: they move slower than a finger (faster when they
## strike), decide a few times a second and see the puck a moment late.
const BOT_SPEED := 700.0
const BOT_STRIKE := 1300.0  ## px/s, close to the puck
const BOT_THINK := 0.12  ## seconds between a bot's decisions
const BOT_EYES := 6.0  ## how fast what bots see catches up with the puck, per second


## A player's mallet, or a bot's.
class Mallet:
	var team: int
	var pos: Vector2
	var vel := Vector2.ZERO
	var target: Vector2
	var bot := false
	var back := false  ## the second of a team: as a bot, it guards the goal
	var think := 0.0  ## a bot's time to its next decision
	var aim := 0.0  ## a bot's shot: x on the far end line, seen from its goal


var team_size: int
var goals_to_win: int
var mallets: Array[Mallet] = []  ## team 0 first, then team 1: see index()
var puck := Vector2(WIDTH * 0.5, HEIGHT * 0.5)
var puck_vel := Vector2.ZERO
var score: Array[int] = [0, 0]
var serve := KICKOFF  ## seconds before the puck is in play
var winner := -1
var scoring := true  ## false on the guests: only the host decides the goals
var side := -1  ## team whose half the puck is in, -1 before the first serve
var held_for := 0.0  ## seconds the puck has been in that half

var _seen := puck  ## the puck as the bots see it: a moment late
var _seen_vel := Vector2.ZERO
var _rng := RandomNumberGenerator.new()


func _init(p_team_size: int = 1, p_goals: int = GOALS_TO_WIN, p_seed: int = 0) -> void:
	team_size = clampi(p_team_size, 1, 2)
	goals_to_win = maxi(1, p_goals)
	if p_seed == 0:
		_rng.randomize()
	else:
		_rng.seed = p_seed
	for team in 2:
		for slot in team_size:
			var m := Mallet.new()
			m.team = team
			m.back = slot == 1
			m.aim = WIDTH * 0.5
			m.pos = home(team, slot, team_size)
			m.target = m.pos
			mallets.append(m)


## Mallet of a team's player: the first one, or the second one in 2 vs 2.
func index(team: int, slot: int) -> int:
	return team * team_size + slot


func is_over() -> bool:
	return winner >= 0


## Where a player wants their mallet; it stays in its half.
func set_target(i: int, p: Vector2) -> void:
	if i < 0 or i >= mallets.size() or not p.is_finite():
		return
	mallets[i].target = clamp_to_half(mallets[i].team, p)


func update(delta: float) -> void:
	if winner >= 0 or delta <= 0.0:
		return
	for m in mallets:
		if m.bot:
			m.think -= delta
			if m.think <= 0.0:
				m.think = BOT_THINK
				m.target = clamp_to_half(m.team, _bot_target(m))
	var n := ceili(delta / STEP)
	var dt := delta / n
	for _i in n:
		_step(dt)
		if winner >= 0:
			return


## The match as numbers, for the guests: the puck, its speed, the wait
## before a serve, the score, then every mallet.
func snapshot() -> PackedFloat32Array:
	var s := PackedFloat32Array([puck.x, puck.y, puck_vel.x, puck_vel.y, serve, score[0], score[1]])
	for m in mallets:
		s.append(m.pos.x)
		s.append(m.pos.y)
	return s


## A guest takes the host's snapshot, except for its own mallet `own`: the
## finger is ahead of the host there. A goal in it is signalled like one
## scored here. A snapshot that doesn't fit this match is ignored.
func apply_snapshot(s: PackedFloat32Array, own := -1) -> void:
	if s.size() != SNAPSHOT_HEAD + mallets.size() * 2:
		return
	for x in s:
		if not is_finite(x):
			return
	puck = Vector2(s[0], s[1])
	puck_vel = Vector2(s[2], s[3])
	serve = maxf(0.0, s[4])
	if serve > 0.0:
		# Waiting to be served: the seven seconds start again, in that half.
		side = 0 if puck.y > HEIGHT * 0.5 else 1
		held_for = 0.0
	for team in 2:
		var goals := int(s[5 + team])
		var before := score[team]
		score[team] = goals
		if goals > before:
			goal.emit(team)
	for i in mallets.size():
		if i == own:
			continue
		var m := mallets[i]
		var p := Vector2(s[SNAPSHOT_HEAD + i * 2], s[SNAPSHOT_HEAD + i * 2 + 1])
		m.target = clamp_to_half(m.team, p)
		if m.pos.distance_to(m.target) > MALLET_RADIUS * 2.0:
			m.pos = m.target  # too far behind to glide there


## Where a mallet starts: in front of its goal, one ahead of the other in
## 2 vs 2. Team 1 is team 0 turned round.
static func home(team: int, slot: int, size: int) -> Vector2:
	var p := Vector2(WIDTH * 0.5, HEIGHT - 150.0)
	if size > 1:
		p = Vector2(WIDTH * 0.3, HEIGHT - 240.0)
		if slot == 1:
			p = Vector2(WIDTH * 0.7, HEIGHT - 120.0)
	return p if team == 0 else mirror(p)


## The same point seen from the other end of the table.
static func mirror(p: Vector2) -> Vector2:
	return Vector2(WIDTH, HEIGHT) - p


## The part of the table a mallet of `team` may cover: its own half.
static func clamp_to_half(team: int, p: Vector2) -> Vector2:
	var r := MALLET_RADIUS
	var x := clampf(p.x, r, WIDTH - r)
	if team == 0:
		return Vector2(x, clampf(p.y, HEIGHT * 0.5 + r, HEIGHT - r))
	return Vector2(x, clampf(p.y, r, HEIGHT * 0.5 - r))


## For a bot defending the bottom goal, at `me`: wait in front of the goal
## while the puck is away or rushing in; otherwise strike it towards `aim` on
## the far end line, going round it first if needed, or sweep it off the end
## wall. The second bot of a team always guards.
static func bot_plan(p: Vector2, v: Vector2, me: Vector2, back: bool, aim: float) -> Vector2:
	var mid := WIDTH * 0.5
	var guard_x := clampf(mid + (p.x - mid) * 0.6, mid - GOAL_WIDTH * 0.75, mid + GOAL_WIDTH * 0.75)
	var guard := Vector2(guard_x, HEIGHT - (100.0 if back else 180.0))
	if back or p.y < HEIGHT * 0.5 - PUCK_RADIUS or (v.y > 450.0 and p.y < me.y):
		return guard
	var reach := MALLET_RADIUS + PUCK_RADIUS
	if me.y > p.y + reach * 0.3:
		return p + (Vector2(aim, 0.0) - p).normalized() * reach  # behind the puck: through it
	var flank := 1.0 if me.x >= p.x else -1.0
	if p.y > HEIGHT - reach * 1.4:
		return p - Vector2(flank * reach, 0.0)  # against our end wall: sweep it out
	return p + Vector2(flank * reach * 1.1, reach * 1.2)  # go round it


func _step(dt: float) -> void:
	var reach := MALLET_RADIUS + PUCK_RADIUS
	for m in mallets:
		var top := MALLET_SPEED
		if m.bot:
			top = BOT_STRIKE if m.pos.distance_to(puck) < reach * 2.0 else BOT_SPEED
		var move := (m.target - m.pos).limit_length(top * dt)
		m.vel = move / dt
		m.pos += move
	_keep_apart()
	var k := minf(1.0, BOT_EYES * dt)
	_seen += (puck - _seen) * k
	_seen_vel += (puck_vel - _seen_vel) * k
	if serve > 0.0:
		serve = maxf(0.0, serve - dt)
		_unpin()  # waiting to be served, the puck is in the way all the same
		return
	puck += puck_vel * dt
	puck_vel *= 1.0 - PUCK_DRAG * dt
	for m in mallets:
		_hit_mallet(m)
	_hit_walls()
	_unpin()
	_check_goal()
	if winner < 0 and serve <= 0.0:
		_count_hold(dt)


## Teammates push each other aside instead of overlapping.
func _keep_apart() -> void:
	if team_size < 2:
		return
	for team in 2:
		var a := mallets[index(team, 0)]
		var b := mallets[index(team, 1)]
		var d := b.pos - a.pos
		var dist := d.length()
		var reach := MALLET_RADIUS * 2.0
		if dist >= reach:
			continue
		var n := d / dist if dist > 0.001 else Vector2.RIGHT
		var push := n * (reach - dist) * 0.5
		a.pos = clamp_to_half(team, a.pos - push)
		b.pos = clamp_to_half(team, b.pos + push)


func _hit_mallet(m: Mallet) -> void:
	var d := puck - m.pos
	var reach := MALLET_RADIUS + PUCK_RADIUS
	var dist := d.length()
	if dist >= reach:
		return
	var away := Vector2.UP if m.team == 0 else Vector2.DOWN
	var n := d / dist if dist > 0.001 else away
	puck = m.pos + n * reach
	var vn := (puck_vel - m.vel).dot(n)
	if vn < 0.0:
		puck_vel = (puck_vel - (1.0 + MALLET_BOUNCE) * vn * n).limit_length(PUCK_MAX)
		hit.emit(clampf(-vn / PUCK_MAX, 0.0, 1.0))


## Side walls, end walls beside the goals, the goal posts and, inside a goal,
## its sides.
func _hit_walls() -> void:
	var r := PUCK_RADIUS
	var half_goal := GOAL_WIDTH * 0.5
	var mid := WIDTH * 0.5
	var lo := r
	var hi := WIDTH - r
	if puck.y < 0.0 or puck.y > HEIGHT:
		lo = mid - half_goal + r
		hi = mid + half_goal - r
	if puck.x < lo:
		puck.x = lo
		_bounce(Vector2.RIGHT)
	elif puck.x > hi:
		puck.x = hi
		_bounce(Vector2.LEFT)
	if absf(puck.x - mid) > half_goal:
		if puck.y < r:
			puck.y = r
			_bounce(Vector2.DOWN)
		elif puck.y > HEIGHT - r:
			puck.y = HEIGHT - r
			_bounce(Vector2.UP)
		return
	for y: float in [0.0, HEIGHT]:
		_hit_post(Vector2(mid - half_goal, y))
		_hit_post(Vector2(mid + half_goal, y))


func _hit_post(post: Vector2) -> void:
	var d := puck - post
	var dist := d.length()
	if dist >= PUCK_RADIUS or dist < 0.001:
		return
	var n := d / dist
	puck = post + n * PUCK_RADIUS
	_bounce(n)


## The puck meets a surface facing `n`: it comes back, a little slower.
func _bounce(n: Vector2) -> void:
	var vn := puck_vel.dot(n)
	if vn >= 0.0:
		return
	puck_vel -= (1.0 + WALL_BOUNCE) * vn * n
	bounced.emit(clampf(-vn / PUCK_MAX, 0.0, 1.0))


## A mallet pressing the puck into a wall can't go through it: it backs off.
func _unpin() -> void:
	var reach := MALLET_RADIUS + PUCK_RADIUS
	for m in mallets:
		var d := m.pos - puck
		var dist := d.length()
		if dist >= reach:
			continue
		var back := Vector2.DOWN if m.team == 0 else Vector2.UP
		var n := d / dist if dist > 0.001 else back
		m.pos = clamp_to_half(m.team, puck + n * reach)


## Past the end line between the posts: a goal. Guests only let the puck
## settle in the goal, and wait for the host's snapshot.
func _check_goal() -> void:
	if puck.y >= 0.0 and puck.y <= HEIGHT:
		return
	if not scoring:
		var back := GOAL_DEPTH - PUCK_RADIUS
		if puck.y < -back or puck.y > HEIGHT + back:
			puck.y = clampf(puck.y, -back, HEIGHT + back)
			puck_vel = Vector2.ZERO
		return
	var team := 0 if puck.y < 0.0 else 1
	score[team] += 1
	goal.emit(team)
	if score[team] >= goals_to_win:
		winner = team
		won.emit(team)
		return
	_serve(1 - team)  # the team that let it in


## The puck waits in the middle of `team`'s half, for `team` to play it.
func _serve(team: int) -> void:
	var spot := Vector2(WIDTH * 0.5, HEIGHT * 0.75)
	puck = spot if team == 0 else mirror(spot)
	puck_vel = Vector2.ZERO
	serve = SERVE
	_enter(team)


## Seven seconds in a team's half and the puck goes to the other team.
## Guests only count them, to show them: the host serves.
func _count_hold(dt: float) -> void:
	var now := 0 if puck.y > HEIGHT * 0.5 else 1
	if now != side:
		_enter(now)
		return
	held_for += dt
	if held_for >= HOLD_LIMIT and scoring:
		held.emit(side)
		_serve(1 - side)


## The puck is in `team`'s half now: its seven seconds start, and its bots
## pick a new shot.
func _enter(team: int) -> void:
	side = team
	held_for = 0.0
	for m in mallets:
		if m.team == team:
			m.aim = _pick_aim()


## Where a bot shoots, on the far end line: anywhere in the goal mouth or,
## one time in four, off a side wall (the goal seen in that wall's mirror).
func _pick_aim() -> float:
	var mid := WIDTH * 0.5
	var x := mid + _rng.randf_range(-0.35, 0.35) * GOAL_WIDTH
	if _rng.randf() < 0.25:
		var wall := PUCK_RADIUS if _rng.randf() < 0.5 else WIDTH - PUCK_RADIUS
		x = 2.0 * wall - x
	return x


## A bot's idea of where to go, worked out as if it defended the bottom goal.
func _bot_target(m: Mallet) -> Vector2:
	if m.team == 0:
		return bot_plan(_seen, _seen_vel, m.pos, m.back, m.aim)
	return mirror(bot_plan(mirror(_seen), -_seen_vel, mirror(m.pos), m.back, m.aim))
