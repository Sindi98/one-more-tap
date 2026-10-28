class_name WorldView
extends Node2D
## Draws the playfield in world space: background grid, neon track, ball, trail,
## particles, floating labels and the "you should have turned here" marker.
## Pure presentation: it reads the Track, never changes it.

const TRAIL_LEN := 20
const BALL_RADIUS := 7.5  ## px at 390 wide, scaled by track.unit
const HOT := Color(1.0, 0.3, 0.42)
const FLOAT_TIME := 0.8

var track: Track
var hue := 188.0
var view_rect := Rect2()  ## visible world area, set by Main every frame

var _font: Font
var _ball_offset := Vector2.ZERO  ## visual only: smooths the perfect-turn snap
var _trail := PackedVector2Array()
var _particles: Array[Dictionary] = []
var _floaters: Array[Dictionary] = []
var _dying := false
var _death_t := 0.0
var _fall_pos := Vector2.ZERO
var _fall_vel := Vector2.ZERO


func _ready() -> void:
	_font = load("res://assets/fonts/Bungee-Regular.ttf")
	if _font == null:
		_font = ThemeDB.fallback_font


func reset(t: Track) -> void:
	track = t
	_ball_offset = Vector2.ZERO
	_trail.clear()
	_particles.clear()
	_floaters.clear()
	_dying = false
	_death_t = 0.0
	queue_redraw()


## The logic snapped the ball onto the centre line: keep the visual where it was
## and let it glide there over a few frames.
func snap_ball(snap: Vector2) -> void:
	_ball_offset -= snap


func start_fall() -> void:
	_dying = true
	_death_t = 0.0
	_fall_pos = track.ball + _ball_offset
	var d: Vector2 = Track.DIRS[track.ball_dir]
	_fall_vel = d * track.speed * 0.35
	burst(_fall_pos, 28, HOT, 1.5)


func burst(at: Vector2, count: int, color: Color, power := 1.0) -> void:
	var u := track.unit
	for _i in count:
		var ang := randf() * TAU
		var spd := randf_range(40.0, 170.0) * power * u
		var life := randf_range(0.35, 0.7)
		var particle := {
			"p": at,
			"v": Vector2.from_angle(ang) * spd,
			"life": life,
			"max": life,
			"size": randf_range(1.5, 3.2) * u,
			"color": color,
		}
		_particles.append(particle)


func float_text(text: String, at: Vector2, color: Color) -> void:
	_floaters.append({"text": text, "p": at, "t": 0.0, "color": color})


func tick(delta: float) -> void:
	if track == null:
		return
	_ball_offset = _ball_offset.lerp(Vector2.ZERO, minf(1.0, delta * 18.0))
	if track.started and track.alive:
		_trail.append(track.ball + _ball_offset)
		if _trail.size() > TRAIL_LEN:
			_trail.remove_at(0)
	if _dying:
		_death_t += delta
		_fall_pos += _fall_vel * delta
		_fall_vel *= pow(0.1, delta)

	var drag := pow(0.08, delta)
	for i in range(_particles.size() - 1, -1, -1):
		var q: Dictionary = _particles[i]
		q["life"] -= delta
		if q["life"] <= 0.0:
			_particles.remove_at(i)
			continue
		q["p"] += q["v"] * delta
		q["v"] *= drag

	for i in range(_floaters.size() - 1, -1, -1):
		var f: Dictionary = _floaters[i]
		f["t"] += delta
		if f["t"] >= FLOAT_TIME:
			_floaters.remove_at(i)

	queue_redraw()


func _draw() -> void:
	if track == null:
		return
	var h := hue / 360.0
	var neon := Color.from_hsv(h, 0.78, 1.0)
	var bg := Color.from_hsv(h, 0.6, 0.04)
	var inner := Color.from_hsv(h, 0.55, 0.12)
	_draw_background(bg, neon)
	_draw_track(neon, inner)
	if _dying:
		_draw_miss_marker()
	_draw_ball(neon)
	_draw_particles()
	_draw_floaters()


func _draw_background(bg: Color, neon: Color) -> void:
	var r := view_rect.grow(64.0)
	draw_rect(r, bg)
	# Diagonal grid along the two directions of play. It scrolls at 55% of the
	# track speed, which gives depth and a sense of speed.
	var sp := 46.0 * track.unit
	var p := view_rect.position.y * 0.45
	var x0 := r.position.x
	var y0 := r.position.y
	var x1 := r.end.x
	var y1 := r.end.y
	var pts := PackedVector2Array()
	var shift_a := fposmod(-p, sp)
	var c := floorf((x0 - y1) / sp) * sp - sp
	while c <= x1 - y0 + sp:
		var ca := c + shift_a
		pts.append(Vector2(ca + y0, y0))
		pts.append(Vector2(ca + y1, y1))
		c += sp
	var shift_b := fposmod(p, sp)
	c = floorf((x0 + y0) / sp) * sp - sp
	while c <= x1 + y1 + sp:
		var cb := c + shift_b
		pts.append(Vector2(cb - y0, y0))
		pts.append(Vector2(cb - y1, y1))
		c += sp
	if pts.size() >= 2:
		draw_multiline(pts, Color(neon, 0.045), 1.5)


func _visible_segs() -> Array:
	var out := []
	var top := view_rect.position.y - 80.0
	var bottom := view_rect.end.y + 80.0
	for i in range(maxi(0, track.seg - 24), track.segs.size()):
		var s := track.segs[i]
		if s.end_point().y - s.w > bottom:
			continue  # entirely below the screen
		if s.a.y + s.w < top:
			break  # entirely above: every later platform is higher still
		out.append(s)
	return out


func _seg_poly(s: Track.Seg, grow: float) -> PackedVector2Array:
	var n := Vector2(-s.d.y, s.d.x)
	var hw := s.w * 0.5 + grow
	var a := s.a - s.d * hw
	var b := s.a + s.d * (s.length + hw)
	return PackedVector2Array([a + n * hw, b + n * hw, b - n * hw, a - n * hw])


func _draw_track(neon: Color, inner: Color) -> void:
	var vis := _visible_segs()
	var u := track.unit
	# Two soft glow passes, then the neon rim, then the dark inside. Drawing every
	# rim before every inside leaves the outline only on the outer edge of the path.
	for s in vis:
		draw_colored_polygon(_seg_poly(s, 16.0 * u), Color(neon, 0.05))
	for s in vis:
		draw_colored_polygon(_seg_poly(s, 7.0 * u), Color(neon, 0.09))
	for s in vis:
		draw_colored_polygon(_seg_poly(s, 0.0), neon)
	# Filled polygons have hard edges; an antialiased outline in the same colour
	# smooths them. Where an outline crosses another platform it is drawn over
	# the same colour, or covered by the next pass, so only the real edge shows.
	for s in vis:
		_outline(_seg_poly(s, 0.0), neon, 1.0 * u)
	for s in vis:
		draw_colored_polygon(_seg_poly(s, -2.6 * u), inner)
	for s in vis:
		_outline(_seg_poly(s, -2.6 * u), inner, 1.0 * u)
	# Faint centre guide: turning on it is what makes a "perfect".
	for s in vis:
		draw_dashed_line(s.a, s.end_point(), Color(neon, 0.16), 1.5 * u, 6.0 * u)


func _outline(poly: PackedVector2Array, color: Color, width: float) -> void:
	var closed := poly.duplicate()
	closed.append(poly[0])
	draw_polyline(closed, color, width, true)


func _draw_ball(neon: Color) -> void:
	var u := track.unit
	var r := BALL_RADIUS * u
	var trail_alpha := 1.0
	if _dying:
		trail_alpha = clampf(1.0 - _death_t * 2.5, 0.0, 1.0)
	var n := _trail.size()
	for i in n:
		var k := float(i + 1) / n
		draw_circle(_trail[i], r * (0.25 + 0.6 * k), Color(neon, 0.35 * k * trail_alpha))

	var pos := track.ball + _ball_offset
	var alpha := 1.0
	if _dying:
		pos = _fall_pos
		var t := clampf(_death_t / 0.5, 0.0, 1.0)
		r *= 1.0 - t * 0.85  # falling off the track: shrink away
		alpha = 1.0 - t * 0.6
	draw_circle(pos, r * 3.0, Color(neon, 0.07 * alpha))
	draw_circle(pos, r * 2.0, Color(neon, 0.16 * alpha))
	draw_circle(pos, r * 1.35, Color(neon, 0.45 * alpha))
	draw_circle(pos, r, Color(1, 1, 1, alpha))


## Ring on the corner where the player should have turned, plus an arrow showing
## the direction the ball should have taken: the reason for losing at a glance.
func _draw_miss_marker() -> void:
	if _death_t < 0.12:
		return
	var u := track.unit
	var t := _death_t - 0.12
	var c := track.corner
	var pulse := 0.5 + 0.5 * sin(t * 9.0)
	var rad := track.current().w * 0.62
	draw_arc(c, rad + pulse * 4.0 * u, 0.0, TAU, 48, Color(HOT, 0.9), 3.0 * u, true)
	draw_arc(c, rad + (10.0 + pulse * 6.0) * u, 0.0, TAU, 48, Color(HOT, 0.25), 2.0 * u, true)
	var d: Vector2 = Track.DIRS[track.corner_dir]
	var side := Vector2(-d.y, d.x)
	var base := c + d * (rad + 8.0 * u)
	var tip := c + d * (rad + 34.0 * u)
	draw_line(base, tip, HOT, 3.0 * u, true)
	var head := PackedVector2Array(
		[
			tip - d * 10.0 * u + side * 8.0 * u,
			tip,
			tip - d * 10.0 * u - side * 8.0 * u,
		]
	)
	draw_polyline(head, HOT, 3.0 * u, true)


func _draw_particles() -> void:
	for q in _particles:
		var k: float = q["life"] / q["max"]
		var col: Color = q["color"]
		var size: float = q["size"]
		draw_circle(q["p"], size * (0.4 + 0.6 * k), Color(col, k))


func _draw_floaters() -> void:
	var size := int(17.0 * track.unit)
	for f in _floaters:
		var t: float = f["t"] / FLOAT_TIME
		var col: Color = f["color"]
		var at: Vector2 = f["p"]
		var p := at + Vector2(0.0, -64.0 * track.unit * ease(t, 0.4))
		draw_string(
			_font,
			p - Vector2(220.0, 0.0),
			f["text"],
			HORIZONTAL_ALIGNMENT_CENTER,
			440.0,
			size,
			Color(col, 1.0 - t)
		)
