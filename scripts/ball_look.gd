class_name BallLook
extends RefCounted
## How each ball look draws its trail and itself, in ZIGZAG, in TORRE and on
## the shop's cards. Static helpers that draw on any CanvasItem; the moving
## looks read the clock themselves.


## trail: oldest point first. strength: how bright the trail is in this mode.
static func draw_trail(
	ci: CanvasItem, look: String, trail: PackedVector2Array, r: float, neon: Color, strength: float
) -> void:
	var n := trail.size()
	if look == "cometa":
		_comet_tail(ci, trail, r, neon, strength)
		return
	var t := _now()
	for i in n:
		var k := float(i + 1) / n
		var c := Color(neon, strength * k)
		var size := r * (0.25 + 0.6 * k)
		var p := trail[i]
		match look:
			"anello":
				ci.draw_arc(p, size, 0.0, TAU, 12, c, maxf(1.0, size * 0.4), true)
			"diamante":
				_diamond(ci, p, size * 1.25, t * 2.0, c)
			"pixel":
				var step := r * 1.4  # the trail snaps to a coarse grid: steps, not a line
				var q := (p / step).round() * step
				ci.draw_rect(Rect2(q - Vector2(size, size), Vector2(size, size) * 2.0), c)
			"supernova":
				if i % 2 == 0:
					var twinkle := 0.6 + 0.4 * sin(t * 15.0 + i * 1.7)
					var col := (
						Color(1, 1, 1, strength * 2.0 * k)
						if i % 4 == 0
						else Color(neon, strength * 2.2 * k)
					)
					_star(ci, p, size * 1.6 * twinkle, size * 0.35, t * 3.0 + i, col)
			_:
				ci.draw_circle(p, size, c)


## The ball at `pos`, radius r. alpha fades it (e.g. while it falls).
static func draw_ball(
	ci: CanvasItem, look: String, pos: Vector2, r: float, neon: Color, alpha: float
) -> void:
	var t := _now()
	var white := Color(1, 1, 1, alpha)
	if look == "pixel":
		for g in [[3.0, 0.07], [2.0, 0.16], [1.35, 0.45]]:
			var s: float = r * g[0]
			ci.draw_rect(Rect2(pos - Vector2(s, s), Vector2(s, s) * 2.0), Color(neon, g[1] * alpha))
		ci.draw_rect(Rect2(pos - Vector2(r, r) * 0.9, Vector2(r, r) * 1.8), white)
		return
	var glow := 1.0
	if look == "cometa" or look == "supernova":
		glow = 1.0 + 0.25 * sin(t * 5.0)  # the brighter looks breathe
	ci.draw_circle(pos, r * 3.0 * glow, Color(neon, 0.07 * alpha))
	ci.draw_circle(pos, r * 2.0 * glow, Color(neon, 0.16 * alpha))
	ci.draw_circle(pos, r * 1.35, Color(neon, 0.45 * alpha))
	match look:
		"anello":
			ci.draw_arc(pos, r * 0.8, 0.0, TAU, 32, white, r * 0.45, true)
		"diamante":
			_diamond(ci, pos, r * 1.45, t * 2.0, white)
		"cometa":
			ci.draw_circle(pos, r * 1.1, white)
		"supernova":
			var halo := r * (2.1 + 0.35 * sin(t * 4.0))
			ci.draw_arc(pos, halo, 0.0, TAU, 40, Color(neon, 0.7 * alpha), r * 0.22, true)
			var rays := r * (2.6 + 0.6 * sin(t * 6.0))
			_star(ci, pos, rays, r * 0.3, t * 1.5, white)
			_star(
				ci, pos, rays * 0.6, r * 0.22, t * 1.5 + PI / 4.0, Color(neon.lightened(0.5), alpha)
			)
			ci.draw_circle(pos, r, white)
		_:
			ci.draw_circle(pos, r, white)


## How much bigger a PERFETTO bursts with this ball: the rarer, the bigger.
static func perfect_boost(look: String) -> float:
	match Catalog.LOOKS.get(look, {}).get("rarity", ""):
		"epic":
			return 1.7
		"legendary":
			return 2.6
	return 1.0


## A tapered ribbon of light along the trail, with sparks flickering on it.
static func _comet_tail(
	ci: CanvasItem, trail: PackedVector2Array, r: float, neon: Color, strength: float
) -> void:
	var n := trail.size()
	if n < 2:
		return
	var t := _now()
	var sides: Array[Vector2] = []
	for i in n:
		var d := trail[mini(i + 1, n - 1)] - trail[maxi(i - 1, 0)]
		sides.append(Vector2(-d.y, d.x).normalized())
	for i in range(1, n):
		if trail[i].distance_squared_to(trail[i - 1]) < 0.01:
			continue  # the ball is standing still
		var k0 := float(i) / n
		var k1 := float(i + 1) / n
		var w0 := r * 1.3 * k0
		var w1 := r * 1.3 * k1
		var quad := PackedVector2Array(
			[
				trail[i - 1] + sides[i - 1] * w0,
				trail[i] + sides[i] * w1,
				trail[i] - sides[i] * w1,
				trail[i - 1] - sides[i - 1] * w0,
			]
		)
		var c0 := Color(neon, strength * 1.6 * k0)
		var c1 := Color(neon, strength * 1.6 * k1)
		# A primitive is drawn as is: a quad folded on a sharp turn is still fine.
		ci.draw_primitive(quad, PackedColorArray([c0, c1, c1, c0]), PackedVector2Array())
	for i in range(0, n, 2):
		var k := float(i + 1) / n
		var flick := 0.5 + 0.5 * sin(t * 23.0 + i * 2.7)
		var off := sides[i] * sin(i * 12.9898 + t * 7.0) * r * 1.5
		ci.draw_circle(trail[i] + off, r * 0.25 * flick + 0.5, Color(1, 1, 1, 0.9 * k * flick))


static func _diamond(ci: CanvasItem, at: Vector2, size: float, angle: float, color: Color) -> void:
	var pts := PackedVector2Array()
	for i in 4:
		pts.append(at + Vector2.from_angle(angle + i * PI * 0.5) * size)
	ci.draw_colored_polygon(pts, color)


## Four-pointed star: long rays `size`, waist `waist`.
static func _star(
	ci: CanvasItem, at: Vector2, size: float, waist: float, angle: float, color: Color
) -> void:
	var pts := PackedVector2Array()
	for i in 8:
		var reach := size if i % 2 == 0 else waist
		pts.append(at + Vector2.from_angle(angle + i * PI * 0.25) * reach)
	ci.draw_colored_polygon(pts, color)


static func _now() -> float:
	return Time.get_ticks_msec() / 1000.0
