class_name Track
extends RefCounted
## Pure game logic for ONE MORE TAP. No nodes, no drawing: testable headless.
##
## The ball moves on its own along 45° diagonals and a tap flips its direction.
## Platforms alternate up-left / up-right and meet in square corners: tap inside
## the corner to turn, anywhere else and the ball falls off the track.

signal scored(score: int)
signal turned(perfect: bool, combo: int, snap: Vector2)
signal died(reason: String)

const S := 0.7071067811865476
## 0 = up-left, 1 = up-right (y grows downward, like the screen).
const DIRS := [Vector2(-S, -S), Vector2(S, -S)]

# Tuning, in pixels at a 390 px wide playfield (scaled to the real width).
const BASE_WIDTH := 390.0
const W_START := 76.0  ## starting platform width
const W_MIN := 34.0  ## narrowest platform
const W_STEP := 0.42  ## width lost per platform
const V_START := 175.0  ## starting speed, px/s
const V_MAX := 420.0
const V_STEP := 2.6  ## speed gained per platform
const PERFECT_FRAC := 0.16  ## perfect window: ±16% of platform width around the corner
const MIN_LEN_FACTOR := 1.3  ## shortest platform = 1.3 × its width
const LONG_CHANCE := 0.14  ## chance of a long platform (a breather)


## One straight platform. Its solid area extends w/2 past both ends, so two
## consecutive (perpendicular) platforms meet in a square corner.
class Seg:
	var a: Vector2
	var d: Vector2
	var dir: int
	var length: float
	var w: float
	var index: int

	func end_point() -> Vector2:
		return a + d * length

	func along(p: Vector2) -> float:
		return (p - a).dot(d)

	func contains(p: Vector2) -> bool:
		var r := p - a
		var t := r.dot(d)
		var perp := r.x * d.y - r.y * d.x
		var h := w * 0.5
		return t >= -h and t <= length + h and absf(perp) <= h


var width: float
var unit: float
var view_height: float
var margin: float

var segs: Array[Seg] = []
var ball := Vector2.ZERO
var ball_dir := 0
var turns := 0  ## taps made so far
var seg := 0  ## index of the platform the ball is on
var bonus := 0  ## points earned with perfect turns
var score := 0
var combo := 0
var best_combo := 0
var perfects := 0
var speed := 0.0
var started := false
var alive := true
var reason := ""  ## "early" or "late" once the ball falls
var corner := Vector2.ZERO  ## where the player should have turned
var corner_dir := 0

var _rng := RandomNumberGenerator.new()
var _w0: float
var _w_min: float


func _init(p_width: float = 720.0, p_view_height: float = 1280.0, p_seed: int = 0) -> void:
	width = p_width
	view_height = p_view_height
	unit = width / BASE_WIDTH
	_w0 = W_START * unit
	_w_min = W_MIN * unit
	margin = _w0 * 0.5 + 6.0 * unit
	if p_seed == 0:
		_rng.randomize()
	else:
		_rng.seed = p_seed
	speed = V_START * unit
	_add_seg()
	ball = Vector2(width * 0.5, 0.0)
	ball_dir = segs[0].dir
	_ensure_ahead()


func start() -> void:
	started = true


func current() -> Seg:
	return segs[seg]


## Flip direction. Returns {"perfect": bool, "combo": int} or {} if not playing.
func tap() -> Dictionary:
	if not started or not alive:
		return {}
	var cur := segs[seg]
	var perfect := false
	var snap := Vector2.ZERO
	if turns == seg:
		perfect = absf(cur.along(ball) - cur.length) <= cur.w * PERFECT_FRAC
	turns += 1
	ball_dir ^= 1
	if perfect:
		# Snap onto the next platform's centre line: rewards precision, removes drift.
		var e := cur.end_point()
		var d: Vector2 = DIRS[ball_dir]
		var target := e + d * (ball - e).dot(d)
		snap = target - ball
		ball = target
		combo += 1
		perfects += 1
		bonus += 1
		best_combo = maxi(best_combo, combo)
	else:
		combo = 0
	_try_advance()
	score = seg + bonus
	turned.emit(perfect, combo, snap)
	return {"perfect": perfect, "combo": combo}


func update(delta: float) -> void:
	if not started or not alive:
		return
	speed = minf(V_MAX, V_START + seg * V_STEP) * unit
	var dist := speed * delta
	var steps := maxi(1, ceili(dist / (2.5 * unit)))
	var step := dist / steps
	var d: Vector2 = DIRS[ball_dir]
	for _i in steps:
		ball += d * step
		_try_advance()
		if not segs[seg].contains(ball):
			_die()
			return


func _width_for(k: int) -> float:
	return maxf(_w_min, _w0 - k * W_STEP * unit)


func _add_seg() -> void:
	var k := segs.size()
	var w := _width_for(k)
	var min_len := w * MIN_LEN_FACTOR
	var min_h := min_len * S
	var next_min_h := _width_for(k + 1) * MIN_LEN_FACTOR * S
	var s := Seg.new()
	s.index = k
	s.w = w
	var target: float
	if k == 0:
		s.dir = _rng.randi_range(0, 1)
		s.d = DIRS[s.dir]
		var back := w * 1.2  # a bit of track behind the ball
		s.a = Vector2(width * 0.5, 0.0) - s.d * back
		target = back + w * 3.2  # long runway to get going
	else:
		var prev := segs[k - 1]
		s.a = prev.end_point()
		s.dir = prev.dir ^ 1
		s.d = DIRS[s.dir]
		if _rng.randf() < LONG_CHANCE:
			target = min_len + _rng.randf() * w * 3.4
		else:
			target = min_len + _rng.randf() * w * 1.9

	# Keep the corner inside the playfield and leave room for the next platform.
	var lo: float
	var hi: float
	if s.dir == 1:
		lo = maxf(min_h, margin + next_min_h - s.a.x)
		hi = width - margin - s.a.x
	else:
		lo = maxf(min_h, s.a.x - (width - margin - next_min_h))
		hi = s.a.x - margin
	var h := minf(maxf(target * S, lo), hi)
	if h < min_h:
		h = min_h
	s.length = h / S
	segs.append(s)


func _ensure_ahead() -> void:
	var need_y := ball.y - view_height * 1.6
	while segs[segs.size() - 1].end_point().y >= need_y:
		_add_seg()


func _try_advance() -> void:
	if turns != seg + 1:
		return
	if seg + 1 < segs.size() and segs[seg + 1].contains(ball):
		seg += 1
		score = seg + bonus
		_ensure_ahead()
		scored.emit(score)


func _die() -> void:
	alive = false
	# More taps than platforms reached = turned before the corner (or tapped twice).
	reason = "early" if turns > seg else "late"
	corner = segs[seg].end_point()
	corner_dir = segs[seg].dir ^ 1
	died.emit(reason)
