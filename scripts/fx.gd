class_name Fx
extends Node2D
## Sparks and floating labels, in world space, drawn over whichever mode is on
## screen. Pure presentation.

const FLOAT_TIME := 0.8

var unit := 1.0
var view_rect := Rect2()  ## visible world area, set by Main every frame

var _font: Font
var _particles: Array[Dictionary] = []
var _floaters: Array[Dictionary] = []


func _ready() -> void:
	_font = load("res://assets/fonts/Bungee-Regular.ttf")
	if _font == null:
		_font = ThemeDB.fallback_font


func reset(p_unit: float) -> void:
	unit = p_unit
	_particles.clear()
	_floaters.clear()
	queue_redraw()


func burst(at: Vector2, count: int, color: Color, power := 1.0) -> void:
	for _i in count:
		var ang := randf() * TAU
		var spd := randf_range(40.0, 170.0) * power * unit
		var life := randf_range(0.35, 0.7)
		var particle := {
			"p": at,
			"v": Vector2.from_angle(ang) * spd,
			"life": life,
			"max": life,
			"size": randf_range(1.5, 3.2) * unit,
			"color": color,
		}
		_particles.append(particle)


func float_text(text: String, at: Vector2, color: Color) -> void:
	_floaters.append({"text": text, "p": at, "t": 0.0, "color": color})


func tick(delta: float) -> void:
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
	_draw_particles()
	_draw_floaters()


func _draw_particles() -> void:
	for q in _particles:
		var k: float = q["life"] / q["max"]
		var col: Color = q["color"]
		var size: float = q["size"]
		draw_circle(q["p"], size * (0.4 + 0.6 * k), Color(col, k))


func _draw_floaters() -> void:
	var size := int(17.0 * unit)
	var margin := 12.0 * unit
	for f in _floaters:
		var t: float = f["t"] / FLOAT_TIME
		var col: Color = f["color"]
		var text: String = f["text"]
		var at: Vector2 = f["p"]
		var p := at + Vector2(0.0, -64.0 * unit * ease(t, 0.4))
		# Near a side edge, slide the label inward so it is never cut off.
		var half := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x * 0.5
		var lo := view_rect.position.x + margin + half
		var hi := view_rect.end.x - margin - half
		p.x = clampf(p.x, lo, hi) if lo <= hi else view_rect.get_center().x
		draw_string(
			_font,
			p - Vector2(220.0, 0.0),
			text,
			HORIZONTAL_ALIGNMENT_CENTER,
			440.0,
			size,
			Color(col, 1.0 - t)
		)
