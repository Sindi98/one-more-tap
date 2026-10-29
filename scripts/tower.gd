class_name Tower
extends RunRules
## Rules for TORRE. Pure logic: no nodes, no drawing, testable headless.
##
## The ball rolls on its own up a spiral ramp around a tower, and a tap makes it
## jump. The ramp has holes: jump before the edge and land past the hole.
## Everything is measured along the ramp, in pixels: TowerView wraps that line
## around the tower.

signal jumped(perfect: bool, combo: int)

# Tuning, in pixels at a 390 px wide playfield (scaled to the real width).
const BASE_WIDTH := 390.0
const JUMP_LEN := 118.0  ## ramp covered by a jump, whatever the speed
const JUMP_H := 44.0  ## height of the jump at its top
const HOLE_START := 0.4  ## first holes: 40% of a jump long
const HOLE_MAX := 0.72  ## longest holes: 72% of a jump
const HOLE_STEP := 0.008  ## added per hole
const V_START := 150.0  ## starting speed, px/s
const V_MAX := 330.0
const V_STEP := 3.2  ## speed gained per hole
## Perfect: taking off in the last 30% of the useful run-up, next to the edge.
const PERFECT_FRAC := 0.3
const FIRST_HOLE := 2.4  ## seconds of ramp before the first hole
const REACT := 0.45  ## seconds of ramp, at least, after the farthest landing
const GROUND_EXTRA := 0.8  ## up to this many seconds of ramp added at random
const LONG_CHANCE := 0.14  ## chance of a long stretch (a breather)
const AHEAD := 5000.0  ## ramp prepared ahead of the ball: it shows several turns up
const REVIVE_SLOW := 0.4  ## speed factor right after a continue
const REVIVE_RECOVER := 2.0  ## seconds to get back to full speed after a continue


## A gap in the ramp, between two distances along it.
class Hole:
	var start: float
	var end: float
	var index: int

	func length() -> float:
		return end - start


var width: float
var holes: Array[Hole] = []
var pos := 0.0  ## distance rolled along the ramp
var height := 0.0  ## above the ramp, while jumping
var jumping := false
var jump_from := 0.0
var jump_len: float
var next := 0  ## index of the first hole not yet behind the ball
var cleared := 0  ## holes jumped
var bonus := 0  ## points earned with perfect jumps
var combo := 0
var best_combo := 0
var perfects := 0
var jumps := 0
var speed := 0.0
var miss := -1  ## index of the hole the ball fell into

var _rng := RandomNumberGenerator.new()
var _slow := 1.0  ## speed factor, below 1 only for a moment after a continue


func _init(p_width: float = 720.0, p_seed: int = 0) -> void:
	width = p_width
	unit = width / BASE_WIDTH
	jump_len = JUMP_LEN * unit
	if p_seed == 0:
		_rng.randomize()
	else:
		_rng.seed = p_seed
	speed = V_START * unit
	_ensure_ahead()


func current() -> Hole:
	return holes[next]


## Jump. Returns {"perfect": bool, "combo": int}, or {} if not playing or
## already in the air.
func tap() -> Dictionary:
	if not started or not alive or jumping:
		return {}
	var h := holes[next]
	# Take-off spots that clear the hole: from the edge back to a jump minus the hole.
	var run_up := jump_len - h.length()
	var perfect := h.start - pos <= run_up * PERFECT_FRAC
	jumping = true
	jump_from = pos
	jumps += 1
	if perfect:
		combo += 1
		perfects += 1
		bonus += 1
		best_combo = maxi(best_combo, combo)
	else:
		combo = 0
	score = cleared + bonus
	jumped.emit(perfect, combo)
	return {"perfect": perfect, "combo": combo}


func update(delta: float) -> void:
	if not started or not alive:
		return
	_slow = minf(1.0, _slow + delta * (1.0 - REVIVE_SLOW) / REVIVE_RECOVER)
	speed = _speed_for(cleared) * _slow
	pos += speed * delta
	if jumping:
		var t := (pos - jump_from) / jump_len
		if t < 1.0:
			height = 4.0 * JUMP_H * unit * t * (1.0 - t)
			return
		_land()
		if not alive:
			return
	if pos > holes[next].start:
		_die("late")


## Back on the ramp at the start of the stretch before the missed hole, slowed
## down for a moment, with score and holes unchanged. Once per run.
func revive() -> bool:
	if not can_revive():
		return false
	revived = true
	alive = true
	reason = ""
	combo = 0
	miss = -1
	jumping = false
	height = 0.0
	pos = holes[next - 1].end if next > 0 else 0.0
	_slow = REVIVE_SLOW
	return true


func _land() -> void:
	jumping = false
	height = 0.0
	var at := jump_from + jump_len
	var h := holes[next]
	if at > h.start and at < h.end:
		_die("early")
		return
	if at >= h.end:
		next += 1
		cleared += 1
		score = cleared + bonus
		_ensure_ahead()
		scored.emit(score)


func _speed_for(holes_cleared: int) -> float:
	return minf(V_MAX, V_START + holes_cleared * V_STEP) * unit


func _hole_length(k: int) -> float:
	return jump_len * minf(HOLE_MAX, HOLE_START + k * HOLE_STEP)


func _add_hole() -> void:
	var k := holes.size()
	var v := _speed_for(k)
	var h := Hole.new()
	h.index = k
	if k == 0:
		h.start = v * FIRST_HOLE
	else:
		var prev := holes[k - 1]
		# A jump from the very edge lands this far past the hole: from there,
		# leave time to see the next one coming.
		var overshoot := jump_len - prev.length()
		var extra := _rng.randf() * GROUND_EXTRA
		if _rng.randf() < LONG_CHANCE:
			extra += 1.0 + _rng.randf() * 1.5
		h.start = prev.end + overshoot + v * (REACT + extra)
	h.end = h.start + _hole_length(k)
	holes.append(h)


func _ensure_ahead() -> void:
	while holes.is_empty() or holes[holes.size() - 1].start < pos + AHEAD * unit:
		_add_hole()


func _die(why: String) -> void:
	alive = false
	reason = why
	miss = next
	died.emit(reason)
