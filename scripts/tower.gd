class_name Tower
extends RunRules
## Rules for TORRE. Pure logic: no nodes, no drawing, testable headless.
##
## The ball rolls on its own up a spiral ramp around a tower, and a tap makes it
## jump. The ramp has holes: jump before the edge and land past the hole.
## Everything is measured along the ramp, in pixels: TowerView wraps that line
## around the tower.
##
## It never stops getting harder: with every hole the ball speeds up, the time
## to take off shrinks and the ramp between holes gets shorter, more and more
## slowly, towards limits that stay playable. Further up come chains: two or
## three holes in a row, to clear in rhythm.

signal jumped(perfect: bool, combo: int)

# Tuning, in pixels at a 390 px wide playfield (scaled to the real width).
const BASE_WIDTH := 390.0
const JUMP_LEN := 118.0  ## ramp covered by a jump, whatever the speed
const JUMP_H := 44.0  ## height of the jump at its top
## Each value below goes from its start to its end (never reached) as holes go
## by: about two thirds of the way after the given number of holes, see _toward().
const V_START := 150.0  ## speed, px/s
const V_END := 430.0
const V_HOLES := 50.0
## Window to take off and clear a hole, in seconds: the hole is a jump minus
## this much run-up at the speed it is reached.
const WINDOW_START := 0.47
const WINDOW_END := 0.065
const WINDOW_HOLES := 22.0
const HOLE_MIN := 0.4  ## a hole is never shorter than 40% of a jump
## Seconds of ramp, at least, after the farthest landing, to see the next hole.
const REACT_START := 0.45
const REACT_END := 0.26
const GROUND_EXTRA_START := 0.8  ## up to this many seconds of ramp added at random
const GROUND_EXTRA_END := 0.3
const LONG_START := 0.14  ## chance of a long stretch (a breather)
const LONG_END := 0.04
const GROUND_HOLES := 60.0
## Chains: from this hole on, the next hole may come right after a landing, to
## clear in rhythm, up to three holes in a row.
const CHAIN_FROM := 12
const CHAIN_CHANCE_END := 0.45
const CHAIN_HOLES := 40.0
const CHAIN_REACT_START := 0.32  ## seconds of ramp after the farthest landing in a chain
const CHAIN_REACT_END := 0.2
const CHAIN_MAX := 3
## Perfect: taking off in the last 30% of the useful run-up, next to the edge.
const PERFECT_FRAC := 0.3
const FIRST_HOLE := 2.4  ## seconds of ramp before the first hole
const AHEAD := 5000.0  ## ramp prepared ahead of the ball: it shows several turns up
const REVIVE_SLOW := 0.4  ## speed factor right after a continue
const REVIVE_RECOVER := 2.0  ## seconds to get back to full speed after a continue


## A gap in the ramp, between two distances along it.
class Hole:
	var start: float
	var end: float
	var index: int
	var chained := false  ## comes right after the previous one: part of a chain

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
var _chain := 1  ## holes in the chain the last hole belongs to


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
	speed = speed_for(cleared) * _slow
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


## Full speed (px/s) with `holes_cleared` holes behind.
func speed_for(holes_cleared: int) -> float:
	return _toward(V_START, V_END, holes_cleared, V_HOLES) * unit


## Seconds in which a take-off clears hole `k`, at full speed.
func window_for(k: int) -> float:
	return _toward(WINDOW_START, WINDOW_END, k, WINDOW_HOLES)


## From `start` towards `end` as holes go by: two thirds of the way after
## `holes` holes, then ever more slowly. It always moves on, never arrives.
static func _toward(start: float, end: float, k: float, holes: float) -> float:
	return end + (start - end) * exp(-maxf(0.0, k) / holes)


func _add_hole() -> void:
	var k := holes.size()
	var v := speed_for(k)
	var h := Hole.new()
	h.index = k
	if k == 0:
		h.start = v * FIRST_HOLE
	else:
		var prev := holes[k - 1]
		# A jump from the very edge lands this far past the hole: from there,
		# leave time to see the next one coming.
		var overshoot := jump_len - prev.length()
		var chain_chance := _toward(0.0, CHAIN_CHANCE_END, k - CHAIN_FROM, CHAIN_HOLES)
		if k >= CHAIN_FROM and _chain < CHAIN_MAX and _rng.randf() < chain_chance:
			# In rhythm: just enough ramp after landing to tap again.
			h.chained = true
			_chain += 1
			var react := _toward(CHAIN_REACT_START, CHAIN_REACT_END, k, GROUND_HOLES)
			h.start = prev.end + overshoot + v * react
		else:
			_chain = 1
			var extra := (
				_rng.randf() * _toward(GROUND_EXTRA_START, GROUND_EXTRA_END, k, GROUND_HOLES)
			)
			if _rng.randf() < _toward(LONG_START, LONG_END, k, GROUND_HOLES):
				extra += 1.0 + _rng.randf() * 1.5
			var react := _toward(REACT_START, REACT_END, k, GROUND_HOLES)
			h.start = prev.end + overshoot + v * (react + extra)
	var length := jump_len - window_for(k) * v
	h.end = h.start + maxf(length, jump_len * HOLE_MIN)
	holes.append(h)


func _ensure_ahead() -> void:
	while holes.is_empty() or holes[holes.size() - 1].start < pos + AHEAD * unit:
		_add_hole()


func _die(why: String) -> void:
	alive = false
	reason = why
	miss = next
	died.emit(reason)
