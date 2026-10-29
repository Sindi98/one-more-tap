class_name LivesView
extends Control
## A row of hearts, full for the lives left and hollow for the spent ones, then
## the time until the next one comes back. Drawn in code: the game's fonts have
## no heart.

const HEART := 30.0  ## heart width
const GAP := 10.0
const TEXT_GAP := 18.0

var font: Font
var font_size := 26
var color := Color.WHITE
var text_color := Color.WHITE

var _left := 0
var _total := 0
var _text := ""


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER


func set_lives(left: int, total: int, wait_seconds: int) -> void:
	var text := ""
	if wait_seconds > 0:
		@warning_ignore("integer_division")
		text = "+1 tra %d:%02d" % [wait_seconds / 60, wait_seconds % 60]
	if left == _left and total == _total and text == _text:
		return
	_left = left
	_total = total
	_text = text
	var w := _total * HEART + maxf(0.0, _total - 1) * GAP
	if _text != "" and font:
		w += TEXT_GAP + font.get_string_size(_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	custom_minimum_size = Vector2(w, HEART)
	queue_redraw()


func _draw() -> void:
	var outline := _heart(Vector2.ZERO, HEART * 0.5)
	for i in _total:
		var c := Vector2(HEART * 0.5 + i * (HEART + GAP), HEART * 0.5)
		var pts := outline.duplicate()
		for k in pts.size():
			pts[k] += c
		if i < _left:
			draw_colored_polygon(pts, color)
		pts.append(pts[0])
		draw_polyline(pts, color, 2.5, true)
	if _text != "" and font:
		var x := _total * HEART + maxf(0.0, _total - 1) * GAP + TEXT_GAP
		var y := (HEART + font.get_ascent(font_size) - font.get_descent(font_size)) * 0.5
		draw_string(
			font, Vector2(x, y), _text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, text_color
		)


## The classic heart curve, scaled to `r` (half its width), point down.
func _heart(c: Vector2, r: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 32:
		var t := TAU * i / 32.0
		var x := pow(sin(t), 3.0)
		var y := (13.0 * cos(t) - 5.0 * cos(2.0 * t) - 2.0 * cos(3.0 * t) - cos(4.0 * t)) / 16.0
		pts.append(c + Vector2(x, -y - 0.1) * r)
	return pts
