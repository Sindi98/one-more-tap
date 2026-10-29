class_name TowerView
extends ModeView
## TORRE: wraps the Tower's straight ramp around a cylinder seen a little from
## above. The tower turns so the ball always stays in front, and the holes come
## round from the right. Pure presentation: it reads the Tower, never changes it.

const RADIUS := 112.0  ## tower radius, px at 390 wide, scaled by tower.unit
const LEDGE := 30.0  ## how far the ramp sticks out of the wall
const THICK := 12.0  ## height of the ramp's front edge
const PITCH := 128.0  ## height the ramp gains in one turn
const TILT := 0.3  ## how much of the top of the ramp shows (0 = side view)
const BALL_ANGLE := -0.3  ## where the ball sits round the tower (0 = facing us)
const BALL_RADIUS := 7.5
const BRICK_H := 32.0
const BRICKS_PER_TURN := 14
const WALL_STRIPS := 20  ## vertical bands of shading on the wall
const STEP := 0.07  ## radians per piece of ramp
const TRAIL_LEN := 12
const BALL_SCREEN_Y := 0.66  ## the ball sits at 66% of the screen height
const MISS_SCREEN_Y := 0.72  ## after a fall, the missed hole is shown here

var tower: Tower

var _cx := 0.0  ## tower axis
var _r := 0.0  ## wall radius
var _r_out := 0.0  ## outer edge of the ramp
var _rc := 0.0  ## the ball's path, mid-ramp
var _slope := 0.0  ## height gained per pixel rolled
var _turn := 0.0  ## how far the tower has turned (radians along the ball's path)
var _trail: Array[Vector2] = []  ## recent (distance, height) of the ball
var _dying := false
var _death_t := 0.0
var _fall_pos := Vector2.ZERO
var _fall_vel := Vector2.ZERO
# Ramp mesh, rebuilt every frame: one triangle list per half of the tower.
var _pts := PackedVector2Array()
var _cols := PackedColorArray()
var _idx := PackedInt32Array()
var _rims: Array[PackedVector2Array] = []


func reset(rules: RunRules) -> void:
	tower = rules as Tower
	var u := tower.unit
	_cx = tower.width * 0.5
	_r = RADIUS * u
	_r_out = (RADIUS + LEDGE) * u
	_rc = (RADIUS + LEDGE * 0.5) * u
	_slope = PITCH / (TAU * (RADIUS + LEDGE * 0.5))
	_turn = tower.pos / _rc - BALL_ANGLE
	_trail.clear()
	_dying = false
	_death_t = 0.0
	queue_redraw()


func camera_target(view: Vector2, after_fall: bool) -> Vector2:
	# The ramp climbs at a constant rate: following it (not the jumps) is smooth.
	var y := _at(tower.pos, _rc).y - view.y * (BALL_SCREEN_Y - 0.5)
	if after_fall and tower.miss >= 0:
		y = _at(tower.holes[tower.miss].start, _rc).y - view.y * (MISS_SCREEN_Y - 0.5)
	return Vector2(_cx, y)


func ball_position() -> Vector2:
	return _at(tower.pos, _rc, tower.height + BALL_RADIUS * tower.unit)


func start_fall() -> void:
	_dying = true
	_death_t = 0.0
	_fall_pos = ball_position()
	_fall_vel = Vector2(tower.speed * 0.3, -40.0 * tower.unit)
	fx.burst(_fall_pos, 28, HOT, 1.5)


func revive() -> void:
	_dying = false
	_death_t = 0.0
	_trail.clear()
	fx.burst(ball_position(), 18, Color.from_hsv(hue / 360.0, 0.78, 1.0), 1.2)


func tick(delta: float) -> void:
	if tower == null:
		return
	_turn = tower.pos / _rc - BALL_ANGLE
	if tower.started and tower.alive:
		_trail.append(Vector2(tower.pos, tower.height))
		if _trail.size() > TRAIL_LEN:
			_trail.remove_at(0)
	if _dying:
		_death_t += delta
		_fall_vel.y += 1500.0 * tower.unit * delta
		_fall_pos += _fall_vel * delta
	queue_redraw()


## The point of the ramp `p` px along it, `r` px from the axis, lifted by `lift`.
func _at(p: float, r: float, lift := 0.0) -> Vector2:
	var a := p / _rc - _turn  # 0 = facing the viewer
	return Vector2(_cx + r * sin(a), -p * _slope + r * cos(a) * TILT - lift)


func _draw() -> void:
	if tower == null:
		return
	var h := hue / 360.0
	var neon := Color.from_hsv(h, 0.78, 1.0)
	draw_rect(view_rect.grow(64.0), Color.from_hsv(h, 0.6, 0.04))
	_draw_stars(neon)
	# Back half of the ramp first: the wall hides it except where it sticks out.
	_draw_ramp(h, neon, false)
	_draw_wall(h, neon)
	_draw_ramp(h, neon, true)
	if _dying:
		_draw_miss_marker()
	_draw_ball(neon)


## Faint dots behind the tower, drifting slower than it: depth.
func _draw_stars(neon: Color) -> void:
	var u := tower.unit
	var sp := 44.0 * u
	var r := view_rect.grow(sp)
	var shift := view_rect.position.y * 0.5
	var pts := PackedVector2Array()
	var y := r.position.y - fposmod(r.position.y - shift, sp)
	while y < r.end.y:
		var row := roundi((y - shift) / sp)
		var x := r.position.x - fposmod(r.position.x, sp) + posmod(row, 2) * sp * 0.5
		while x < r.end.x:
			pts.append(Vector2(x, y))
			pts.append(Vector2(x + 2.0 * u, y))
			x += sp
		y += sp
	if pts.size() >= 2:
		draw_multiline(pts, Color(neon, 0.1), 2.0 * u)


func _draw_wall(h: float, neon: Color) -> void:
	var u := tower.unit
	var top := view_rect.position.y - 8.0
	var bottom := view_rect.end.y + 8.0
	# Shading: bright where the wall faces us, dark towards its sides.
	for i in WALL_STRIPS:
		var a0 := -PI * 0.5 + PI * i / WALL_STRIPS
		var a1 := a0 + PI / WALL_STRIPS
		var x0 := _cx + _r * sin(a0)
		var x1 := _cx + _r * sin(a1)
		var lit := cos((a0 + a1) * 0.5)
		draw_rect(Rect2(x0, top, x1 - x0, bottom - top), Color.from_hsv(h, 0.55, 0.05 + 0.08 * lit))
	# Bricks: rings at fixed heights, joints that turn with the tower.
	var bh := BRICK_H * u
	var rings := PackedVector2Array()
	var ring_cols := PackedColorArray()
	var joints := PackedVector2Array()
	var joint_cols := PackedColorArray()
	var j0 := floori((top - _r * TILT) / bh)
	var j1 := ceili(bottom / bh)
	for j in range(j0, j1 + 1):
		var y := j * bh
		for i in 12:
			var a0 := -PI * 0.5 + PI * i / 12.0
			var a1 := a0 + PI / 12.0
			rings.append(Vector2(_cx + _r * sin(a0), y + _r * cos(a0) * TILT))
			rings.append(Vector2(_cx + _r * sin(a1), y + _r * cos(a1) * TILT))
			ring_cols.append(Color(neon, 0.1 * cos((a0 + a1) * 0.5)))
		for k in BRICKS_PER_TURN:
			var phi := (k + 0.5 * posmod(j, 2)) * TAU / BRICKS_PER_TURN
			var a := wrapf(phi - _turn, -PI, PI)
			var c := cos(a)
			if c < 0.06:
				continue
			var x := _cx + _r * sin(a)
			joints.append(Vector2(x, y + _r * c * TILT))
			joints.append(Vector2(x, y + bh + _r * c * TILT))
			joint_cols.append(Color(neon, 0.1 * c))
	if rings.size() >= 2:
		draw_multiline_colors(rings, ring_cols, 1.5 * u)
	if joints.size() >= 2:
		draw_multiline_colors(joints, joint_cols, 1.5 * u)


## Every visible piece of ramp on the front (or back) half of the tower, minus
## the holes, drawn as shaded strips with a neon rim.
func _draw_ramp(h: float, neon: Color, front: bool) -> void:
	var margin := _r_out * TILT + THICK * tower.unit + 40.0
	var p_lo := -(view_rect.end.y + margin) / _slope
	var p_hi := -(view_rect.position.y - margin) / _slope
	# Half turns centred on the side facing us (or away), one per turn.
	var centre := _turn + (0.0 if front else PI)
	var n0 := floori((p_lo / _rc - centre) / TAU) - 1
	var n1 := ceili((p_hi / _rc - centre) / TAU) + 1
	_pts.clear()
	_cols.clear()
	_idx.clear()
	_rims.clear()
	for n in range(n0, n1 + 1):
		var a0 := maxf((centre - PI * 0.5 + TAU * n) * _rc, p_lo)
		var a1 := minf((centre + PI * 0.5 + TAU * n) * _rc, p_hi)
		if a1 <= a0:
			continue
		var p := a0
		var i := _first_hole_after(a0)
		while i < tower.holes.size() and tower.holes[i].start < a1:
			var hole := tower.holes[i]
			if hole.start > p:
				_add_piece(p, hole.start, h, front)
			p = maxf(p, hole.end)
			i += 1
		if p < a1:
			_add_piece(p, a1, h, front)
	if _idx.size() > 0:
		RenderingServer.canvas_item_add_triangle_array(get_canvas_item(), _idx, _pts, _cols)
	for rim in _rims:
		draw_polyline(rim, neon, 1.6 * tower.unit, true)


## Index of the first hole that ends after `p` (holes are in order).
func _first_hole_after(p: float) -> int:
	var lo := 0
	var hi := tower.holes.size()
	while lo < hi:
		var mid := (lo + hi) >> 1
		if tower.holes[mid].end <= p:
			lo = mid + 1
		else:
			hi = mid
	return lo


## Adds the ramp from p0 to p1 to the mesh: its top and, on the front half, its
## front edge and neon rim.
func _add_piece(p0: float, p1: float, h: float, front: bool) -> void:
	var n := maxi(1, ceili((p1 - p0) / _rc / STEP))
	var thick := Vector2(0.0, THICK * tower.unit)
	var rim := PackedVector2Array()
	var base := _pts.size()
	# Per sample: inner edge, outer edge, bottom of the front edge.
	for k in n + 1:
		var p := lerpf(p0, p1, float(k) / n)
		var lit := maxf(0.0, cos(p / _rc - _turn))
		var outer := _at(p, _r_out)
		_pts.append(_at(p, _r))
		_pts.append(outer)
		_pts.append(outer + thick)
		if front:
			_cols.append(Color.from_hsv(h, 0.6, 0.1 + 0.08 * lit))
			_cols.append(Color.from_hsv(h, 0.6, 0.16 + 0.12 * lit))
			_cols.append(Color.from_hsv(h, 0.78, 0.25 + 0.6 * lit))
		else:
			_cols.append(Color.from_hsv(h, 0.6, 0.06))
			_cols.append(Color.from_hsv(h, 0.6, 0.09))
			_cols.append(Color.from_hsv(h, 0.6, 0.09))
		rim.append(outer)
	for k in n:
		var i := base + k * 3
		_quad(i, i + 3, i + 4, i + 1)  # top
		if front:
			_quad(i + 1, i + 4, i + 5, i + 2)  # front edge
	if front:
		# Close the rim down the ends of the piece, so holes have neat edges.
		rim.insert(0, _pts[base + 2])
		rim.append(_pts[_pts.size() - 1])
		_rims.append(rim)


func _quad(a: int, b: int, c: int, d: int) -> void:
	_idx.append(a)
	_idx.append(b)
	_idx.append(c)
	_idx.append(a)
	_idx.append(c)
	_idx.append(d)


func _draw_ball(neon: Color) -> void:
	var u := tower.unit
	var r := BALL_RADIUS * u
	if not _dying:
		# Shadow on the ramp while in the air: shows where the ball comes down.
		if tower.height > 0.0:
			var k := 1.0 - tower.height / (Tower.JUMP_H * u) * 0.5
			draw_set_transform(_at(tower.pos, _rc), 0.0, Vector2(1.0, 0.4))
			draw_circle(Vector2.ZERO, r * 1.2 * k, Color(0.0, 0.0, 0.0, 0.45))
			draw_set_transform(Vector2.ZERO)
		var trail := PackedVector2Array()
		for p in _trail:
			trail.append(_at(p.x, _rc, p.y + r))
		BallLook.draw_trail(self, ball_look, trail, r, neon, 0.3)

	var pos := ball_position()
	var alpha := 1.0
	if _dying:
		pos = _fall_pos
		var t := clampf(_death_t / 0.7, 0.0, 1.0)
		r *= 1.0 - t * 0.4
		alpha = 1.0 - t * 0.8
	BallLook.draw_ball(self, ball_look, pos, r, neon, alpha)


## The missed hole's edges in red, a ring where the ball should have taken off
## and the dashed arc of the jump that would have made it.
func _draw_miss_marker() -> void:
	if _death_t < 0.12 or tower.miss < 0:
		return
	var u := tower.unit
	var t := _death_t - 0.12
	var pulse := 0.5 + 0.5 * sin(t * 9.0)
	var hole := tower.holes[tower.miss]
	var thick := Vector2(0.0, THICK * u)
	for p in [hole.start, hole.end]:
		var outer := _at(p, _r_out)
		draw_polyline(PackedVector2Array([_at(p, _r), outer, outer + thick]), HOT, 3.0 * u, true)
	var run_up := tower.jump_len - hole.length()
	var from := hole.start - run_up * Tower.PERFECT_FRAC * 0.5
	var lift := BALL_RADIUS * u
	var arc := PackedVector2Array()
	for i in 21:
		var k := i / 20.0
		var p := from + tower.jump_len * k
		arc.append(_at(p, _rc, lift + 4.0 * Tower.JUMP_H * u * k * (1.0 - k)))
	for i in range(0, arc.size() - 1, 2):
		draw_line(arc[i], arc[i + 1], Color(HOT, 0.9), 3.0 * u, true)
	var tip := arc[arc.size() - 1]
	var d := (tip - arc[arc.size() - 3]).normalized()
	var side := Vector2(-d.y, d.x)
	var head := PackedVector2Array(
		[tip - d * 10.0 * u + side * 7.0 * u, tip, tip - d * 10.0 * u - side * 7.0 * u]
	)
	draw_polyline(head, HOT, 3.0 * u, true)
	var ring := (9.0 + pulse * 4.0) * u
	draw_arc(arc[0], ring, 0.0, TAU, 32, Color(HOT, 0.9), 3.0 * u, true)
	draw_arc(arc[0], ring + 8.0 * u, 0.0, TAU, 32, Color(HOT, 0.25), 2.0 * u, true)
