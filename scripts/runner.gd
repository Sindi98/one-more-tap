class_name Runner
extends RunRules
## Rules for DINO, a side runner in the style of the browser's offline game.
## Pure logic: no nodes, no drawing, testable headless.
##
## The dino runs on its own and a tap makes it jump. Jump the cacti and the low
## birds; the high birds fly over a dino that stays on the ground. The score is
## the distance run, and the dino keeps getting faster.
## x grows to the right; heights grow upward from the ground, in pixels.

signal jumped
signal milestone(score: int)

enum Kind { SMALL, LARGE, BIRD_LOW, BIRD_HIGH }

# Tuning, in pixels at a 390 px wide playfield (scaled to the real width).
const BASE_WIDTH := 390.0
const DINO_SIZE := Vector2(44.0, 46.0)  ## the drawing
## The part of the dino that can be hit, inside its drawing (x from the left
## edge, y up from the feet): smaller than the drawing, so hits feel fair.
const DINO_HIT := Rect2(10.0, 4.0, 24.0, 36.0)
const CACTUS_SMALL := Vector2(18.0, 34.0)
const CACTUS_LARGE := Vector2(26.0, 50.0)
const CACTUS_GAP := 2.0  ## between the cacti of a group
const BIRD := Vector2(42.0, 28.0)
const BIRD_LOW_Y := 12.0  ## the low bird: jump over it
const BIRD_HIGH_Y := 50.0  ## the high bird: it flies over a dino on the ground
const HIT_INSET := 3.0  ## obstacles can be hit a bit inside their drawing too
const GRAVITY := 2300.0
const JUMP_V := 620.0
const JUMP_BUFFER := 0.12  ## a tap this close before landing jumps on landing
const V_START := 230.0  ## starting speed, px/s
const V_MAX := 540.0
const ACCEL := 0.006  ## speed gained per pixel run
const POINTS_PER_PX := 0.04
const MILESTONE := 100  ## a "ding" every 100 points
const FIRST_OBSTACLE := 2.4  ## seconds of run before the first obstacle
const REACT := 0.36  ## seconds of run, at least, after the farthest landing
const GAP_EXTRA := 0.9  ## up to this many seconds of run added at random
const MIN_WINDOW := 0.12  ## seconds in which a take-off clears an obstacle, at least
const LARGE_CHANCE := 0.4
const BIRDS_FROM := 250  ## score after which birds can appear
const BIRD_CHANCE := 0.3
const AHEAD := 900.0  ## obstacles prepared ahead of the dino
const BEHIND := 200.0  ## passed obstacles kept while they can still be on screen
const REVIVE_SLOW := 0.4  ## speed factor right after a continue
const REVIVE_RECOVER := 2.0  ## seconds to get back to full speed after a continue


class Obstacle:
	var kind: int
	var x: float  ## left edge
	var y: float  ## bottom, above the ground
	var size: Vector2
	var count := 1  ## cacti side by side
	var index: int
	var passed := false

	func right() -> float:
		return x + size.x

	## The part that can be hit (y up). Cacti stand on the ground.
	func hitbox(inset: float) -> Rect2:
		var bottom := y + inset if y > 0.0 else 0.0
		return Rect2(x + inset, bottom, size.x - inset * 2.0, y + size.y - inset - bottom)


var obstacles: Array[Obstacle] = []
var x := 0.0  ## the dino's left edge: also the distance run
var height := 0.0  ## feet above the ground
var vy := 0.0  ## upward speed
var airborne := false
var speed := 0.0
var cleared := 0  ## obstacles passed
var jumps := 0
var hit: Obstacle  ## what ended the run

var _rng := RandomNumberGenerator.new()
var _spawned := 0
var _next_x := 0.0  ## where the next obstacle goes
var _buffer := 0.0  ## time left on a tap made in the air
var _slow := 1.0  ## speed factor, below 1 only for a moment after a continue


func _init(p_width: float = 720.0, p_seed: int = 0) -> void:
	unit = p_width / BASE_WIDTH
	if p_seed == 0:
		_rng.randomize()
	else:
		_rng.seed = p_seed
	speed = V_START * unit
	_next_x = speed * FIRST_OBSTACLE
	_ensure_ahead()


## Jump. Returns {"jumped": true}, or {} if not playing or already in the air
## (a tap just before landing is kept and jumps on landing).
func tap() -> Dictionary:
	if not started or not alive:
		return {}
	if airborne:
		_buffer = JUMP_BUFFER
		return {}
	_jump()
	return {"jumped": true}


func update(delta: float) -> void:
	if not started or not alive:
		return
	_slow = minf(1.0, _slow + delta * (1.0 - REVIVE_SLOW) / REVIVE_RECOVER)
	speed = _speed_at(x) * _slow
	var g := GRAVITY * unit
	var steps := maxi(1, ceili(speed * delta / (3.0 * unit)))
	var dt := delta / steps
	for _i in steps:
		x += speed * dt
		if airborne:
			height += vy * dt - 0.5 * g * dt * dt
			vy -= g * dt
			if height <= 0.0:
				height = 0.0
				vy = 0.0
				airborne = false
				if _buffer > 0.0:
					_jump()
		var o := _collision()
		if o != null:
			_die(o)
			return
	_buffer = maxf(0.0, _buffer - delta)
	_count_passed()
	var points := int(x / unit * POINTS_PER_PX)
	if points != score:
		@warning_ignore("integer_division")
		var crossed := points / MILESTONE > score / MILESTONE
		score = points
		scored.emit(score)
		if crossed:
			milestone.emit(score)
	_ensure_ahead()


## Back on the ground where it fell, slowed down for a moment, with the way
## cleared while it gets back to speed. Score unchanged. Once per run.
func revive() -> bool:
	if not can_revive():
		return false
	revived = true
	alive = true
	reason = ""
	hit = null
	airborne = false
	height = 0.0
	vy = 0.0
	_buffer = 0.0
	var clear_to := x + _speed_at(x) * (REVIVE_RECOVER + air_time() + REACT)
	for i in range(obstacles.size() - 1, -1, -1):
		var o := obstacles[i]
		if o.right() >= x and o.x <= clear_to:
			obstacles.remove_at(i)
	_next_x = maxf(_next_x, clear_to)
	_slow = REVIVE_SLOW
	return true


## Seconds from take-off to landing.
func air_time() -> float:
	return 2.0 * JUMP_V / GRAVITY


## The part of the dino that can be hit (y up).
func dino_box() -> Rect2:
	return Rect2(
		x + DINO_HIT.position.x * unit,
		height + DINO_HIT.position.y * unit,
		DINO_HIT.size.x * unit,
		DINO_HIT.size.y * unit
	)


## Seconds during which a take-off at speed v clears `o`: the feet must stay
## above it for as long as the two overlap. Negative: it cannot be cleared.
func window(o: Obstacle, v: float) -> float:
	var box := o.hitbox(HIT_INSET * unit)
	var need := box.end.y - DINO_HIT.position.y * unit
	var g := GRAVITY * unit
	var apex := pow(JUMP_V * unit, 2.0) / (2.0 * g)
	if need >= apex:
		return -1.0
	var above := 2.0 * sqrt(2.0 * (apex - need) / g)
	return above - (box.size.x + DINO_HIT.size.x * unit) / v


func _jump() -> void:
	airborne = true
	vy = JUMP_V * unit
	_buffer = 0.0
	jumps += 1
	jumped.emit()


func _speed_at(at: float) -> float:
	return minf(V_MAX, V_START + at / unit * ACCEL) * unit


func _collision() -> Obstacle:
	var me := dino_box()
	for o in obstacles:
		if o.x > me.end.x:
			break  # sorted by x: every later one is farther still
		if o.hitbox(HIT_INSET * unit).intersects(me):
			return o
	return null


func _count_passed() -> void:
	var left := x + DINO_HIT.position.x * unit
	for o in obstacles:
		if o.x > left:
			break
		if not o.passed and o.right() < left:
			o.passed = true
			cleared += 1
	while not obstacles.is_empty() and obstacles[0].right() < x - BEHIND * unit:
		obstacles.remove_at(0)


func _ensure_ahead() -> void:
	while _next_x < x + AHEAD * unit:
		_add_obstacle()


func _add_obstacle() -> void:
	var v := _speed_at(_next_x)
	var o := Obstacle.new()
	o.index = _spawned
	_spawned += 1
	o.x = _next_x
	if int(_next_x / unit * POINTS_PER_PX) >= BIRDS_FROM and _rng.randf() < BIRD_CHANCE:
		var high := _rng.randf() < 0.5
		o.kind = Kind.BIRD_HIGH if high else Kind.BIRD_LOW
		o.size = BIRD * unit
		o.y = (BIRD_HIGH_Y if high else BIRD_LOW_Y) * unit
	else:
		o.kind = Kind.LARGE if _rng.randf() < LARGE_CHANCE else Kind.SMALL
		o.count = _rng.randi_range(1, 3)
		_size_cacti(o)
		# Fewer cacti, then smaller ones, until a jump clears them with time to spare.
		while o.count > 1 and window(o, v) < MIN_WINDOW:
			o.count -= 1
			_size_cacti(o)
		if window(o, v) < MIN_WINDOW:
			o.kind = Kind.SMALL
			_size_cacti(o)
	obstacles.append(o)
	# A jump that only just clears it lands about a jump past it: from there,
	# leave time to see the next one coming.
	_next_x = o.right() + v * (air_time() + REACT + _rng.randf() * GAP_EXTRA)


func _size_cacti(o: Obstacle) -> void:
	var one := CACTUS_LARGE if o.kind == Kind.LARGE else CACTUS_SMALL
	o.size = Vector2(one.x * o.count + CACTUS_GAP * (o.count - 1), one.y) * unit
	o.y = 0.0


func _die(o: Obstacle) -> void:
	alive = false
	hit = o
	if o.kind == Kind.BIRD_HIGH:
		reason = "high"  # it flies over a dino that stays on the ground
	elif airborne and vy < 0.0:
		reason = "early"  # came down on it: jumped too soon
	else:
		reason = "late"
	died.emit(reason)
