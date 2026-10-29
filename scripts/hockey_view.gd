class_name HockeyView
extends Node2D
## AIR HOCKEY: draws the table, the goals, the score, the mallets and the
## puck. Every player sees their own goal at the bottom: for the top team the
## whole table is turned round, texts stay upright. Pure presentation: it
## reads the Hockey, never changes it.

const TEAM_HUES: Array[float] = [188.0, 345.0]  ## BLUE, RED
const TABLE := Color("0d1022")
const LINES := Color(1.0, 1.0, 1.0, 0.16)
const HOLES := 30.0  ## spacing of the air holes
const TRAIL_LEN := 10
const FLASH_TIME := 0.9  ## a goal lights up its net this long
const HOLD_WARN := 2.5  ## seconds before the 7-second rule, when the warning starts

var hockey: Hockey
var me := -1  ## the local player's mallet; -1 for the demo behind the lobby
var names := PackedStringArray()  ## per mallet, "" for a bot
var flipped := false  ## the local player defends the top goal: turn the table round
var view_rect := Rect2()  ## visible world area, set by Main every frame
var fx: Fx  ## sparks and labels, set by Main

var _font: Font
var _trail: Array[Vector2] = []  ## recent puck positions, on the table
var _puck_offset := Vector2.ZERO  ## visual only: smooths the host's corrections
var _flash: Array[float] = [0.0, 0.0]  ## per goal (by the team defending it), time left
var _time := 0.0


func _ready() -> void:
	_font = UiKit.load_font(UiKit.DISPLAY_FONT)


## A new match to show. p_me: the local player's mallet (-1: nobody's).
func reset(rules: Hockey, p_me := -1, p_names := PackedStringArray()) -> void:
	hockey = rules
	me = p_me
	names = p_names
	flipped = me >= 0 and hockey.mallets[me].team == 1
	_trail.clear()
	_puck_offset = Vector2.ZERO
	_flash = [0.0, 0.0]
	queue_redraw()


static func team_color(team: int) -> Color:
	return Color.from_hsv(TEAM_HUES[team] / 360.0, 0.78, 1.0)


## The table point under a touch (in viewport coordinates).
func table_point(screen: Vector2) -> Vector2:
	return _at(get_global_transform_with_canvas().affine_inverse() * screen)


func camera_target() -> Vector2:
	return Vector2(Hockey.WIDTH, Hockey.HEIGHT) * 0.5


## Where the puck is drawn, in world space: feedback goes there.
func puck_position() -> Vector2:
	return _at(hockey.puck + _puck_offset)


## The middle of `team`'s goal mouth, in world space.
func goal_position(team: int) -> Vector2:
	return _at(Vector2(Hockey.WIDTH * 0.5, Hockey.HEIGHT if team == 0 else 0.0))


## The host moved the puck from where this guest had it: glide there.
func nudge(offset: Vector2) -> void:
	if offset.length() < Hockey.PUCK_RADIUS * 3.0:
		_puck_offset += offset


## `scorer` scored: the other team's net lights up in the scorer's colour.
func flash_goal(scorer: int) -> void:
	_flash[1 - scorer] = FLASH_TIME
	_trail.clear()


func tick(delta: float) -> void:
	if hockey == null:
		return
	_time += delta
	_puck_offset = _puck_offset.lerp(Vector2.ZERO, minf(1.0, delta * 14.0))
	for i in 2:
		_flash[i] = maxf(0.0, _flash[i] - delta)
	if hockey.serve <= 0.0:
		_trail.append(hockey.puck + _puck_offset)
	if _trail.size() > TRAIL_LEN or (hockey.serve > 0.0 and not _trail.is_empty()):
		_trail.remove_at(0)
	queue_redraw()


## The same point on the turned table: also turns it back.
func _at(p: Vector2) -> Vector2:
	return Hockey.mirror(p) if flipped else p


func _draw() -> void:
	if hockey == null:
		return
	draw_rect(view_rect.grow(64.0), UiKit.SHADE)
	_draw_table()
	_draw_goals()
	_draw_walls()
	_draw_score()
	for i in hockey.mallets.size():
		_draw_mallet(i)
	_draw_puck()


func _draw_table() -> void:
	var w := Hockey.WIDTH
	var h := Hockey.HEIGHT
	draw_rect(Rect2(0.0, 0.0, w, h), TABLE)
	# Each half glows faintly in the colour of the team that defends it.
	for team in 2:
		var half := Rect2(0.0, h * 0.5, w, h * 0.5)
		var on_screen := half if (team == 0) != flipped else Rect2(0.0, 0.0, w, h * 0.5)
		draw_rect(on_screen, Color(team_color(team), 0.045))
	# Air holes: the grid is the same both ways round.
	var dots := PackedVector2Array()
	var y := HOLES * 0.5
	while y < h:
		var x := HOLES * 0.5
		while x < w:
			dots.append(Vector2(x, y))
			dots.append(Vector2(x + 2.0, y))
			x += HOLES
		y += HOLES
	draw_multiline(dots, Color(1.0, 1.0, 1.0, 0.06), 2.0)
	# Centre line and circle, and a crease in front of each goal.
	draw_line(Vector2(0.0, h * 0.5), Vector2(w, h * 0.5), LINES, 3.0)
	draw_arc(Vector2(w, h) * 0.5, 84.0, 0.0, TAU, 64, LINES, 3.0, true)
	draw_circle(Vector2(w, h) * 0.5, 6.0, LINES)
	for team in 2:
		var mouth := goal_position(team)
		var start := PI if mouth.y > h * 0.5 else 0.0
		var c := Color(team_color(team), 0.35)
		draw_arc(mouth, Hockey.GOAL_WIDTH * 0.55, start, start + PI, 48, c, 3.0, true)


## The net behind each end wall: dark, lit up for a moment after a goal.
func _draw_goals() -> void:
	var gw := Hockey.GOAL_WIDTH
	for team in 2:
		var mouth := goal_position(team)
		var deep := Hockey.GOAL_DEPTH if mouth.y > Hockey.HEIGHT * 0.5 else -Hockey.GOAL_DEPTH
		var net := Rect2(mouth.x - gw * 0.5, minf(mouth.y, mouth.y + deep), gw, absf(deep))
		draw_rect(net, Color("030308"))
		var k := _flash[team] / FLASH_TIME
		if k > 0.0:
			draw_rect(net, Color(team_color(1 - team), 0.55 * k))
		var c := team_color(team)
		var back := mouth + Vector2(0.0, deep)
		var outline := PackedVector2Array(
			[
				mouth - Vector2(gw * 0.5, 0.0),
				back - Vector2(gw * 0.5, 0.0),
				back + Vector2(gw * 0.5, 0.0),
				mouth + Vector2(gw * 0.5, 0.0),
			]
		)
		draw_polyline(outline, Color(c, 0.5), 3.0, true)


## The rim of the table, each half in its team's colour, open at the goals,
## with round corners that fit the puck.
func _draw_walls() -> void:
	var w := Hockey.WIDTH
	var h := Hockey.HEIGHT
	var r := Hockey.PUCK_RADIUS
	var post := Hockey.GOAL_WIDTH * 0.5
	for team in 2:
		var c := team_color(team)
		for flank: float in [-1.0, 1.0]:
			# Half of team 0's rim, from its goal post round to the centre line.
			var pts := PackedVector2Array([Vector2(w * 0.5 + post * flank, h)])
			var corner := Vector2(w * 0.5 + (w * 0.5 - r) * flank, h - r)
			for i in 9:
				var a := PI * 0.5 - PI * 0.5 * i / 8.0 * flank
				pts.append(corner + Vector2.from_angle(a) * r)
			pts.append(Vector2(w * 0.5 + w * 0.5 * flank, h * 0.5))
			for i in pts.size():
				pts[i] = _at(pts[i] if team == 0 else Hockey.mirror(pts[i]))
			draw_polyline(pts, Color(c, 0.18), 16.0, true)
			draw_polyline(pts, c, 5.0, true)
	for team in 2:
		for flank: float in [-1.0, 1.0]:
			var p := goal_position(team) + Vector2(post * flank, 0.0)
			draw_circle(p, 7.0, UiKit.INK)


## Each team's goals, big and faint, in its half; the local player's team is
## always below the centre line.
func _draw_score() -> void:
	for team in 2:
		var mid := Vector2(Hockey.WIDTH * 0.5, Hockey.HEIGHT * (0.72 if team == 0 else 0.28))
		var at := _at(mid) + Vector2(0.0, 44.0)
		var c := Color(team_color(team), 0.22)
		var text := str(hockey.score[team])
		draw_string(
			_font, at - Vector2(150.0, 0.0), text, HORIZONTAL_ALIGNMENT_CENTER, 300.0, 128, c
		)


func _draw_mallet(i: int) -> void:
	var m := hockey.mallets[i]
	var p := _at(m.pos)
	var r := Hockey.MALLET_RADIUS
	var hue := TEAM_HUES[m.team] / 360.0
	var c := team_color(m.team)
	draw_circle(p, r * 1.45, Color(c, 0.07))
	draw_circle(p, r, Color.from_hsv(hue, 0.7, 0.16))
	draw_arc(p, r - 2.5, 0.0, TAU, 48, c, 5.0, true)
	draw_circle(p, r * 0.42, Color.from_hsv(hue, 0.65, 0.34))
	draw_arc(p, r * 0.42, 0.0, TAU, 32, c, 3.0, true)
	if i == me:
		# Yours: a white knob and a slow pulse around it.
		draw_circle(p, r * 0.2, UiKit.INK)
		var pulse := 0.5 + 0.5 * sin(_time * 4.0)
		draw_arc(p, r + 6.0 + pulse * 4.0, 0.0, TAU, 48, Color(UiKit.INK, 0.35), 2.0, true)
		return
	if me < 0:
		return  # the demo behind the lobby: no names
	var label := names[i] if i < names.size() and not names[i].is_empty() else "CPU"
	var under := p + Vector2(-110.0, r + 26.0)
	draw_string(_font, under, label, HORIZONTAL_ALIGNMENT_CENTER, 220.0, 18, Color(c, 0.85))


func _draw_puck() -> void:
	var r := Hockey.PUCK_RADIUS
	for k in _trail.size():
		var t := float(k + 1) / (_trail.size() + 1)
		draw_circle(_at(_trail[k]), r * (0.3 + 0.5 * t), Color(UiKit.INK, 0.12 * t))
	var p := puck_position()
	draw_circle(p, r * 1.9, Color(UiKit.INK, 0.06))
	draw_circle(p, r * 1.35, Color(UiKit.INK, 0.12))
	draw_circle(p, r, UiKit.INK)
	draw_arc(p, r * 0.62, 0.0, TAU, 32, Color("a9b0d6"), 3.0, true)
	if hockey.serve > 0.0 and not hockey.is_over():
		# About to be served: a ring that closes in on it.
		var k := clampf(hockey.serve / Hockey.SERVE, 0.0, 1.0)
		draw_arc(
			p, r + 8.0 + 36.0 * k, 0.0, TAU, 48, Color(UiKit.INK, 0.6 * (1.0 - k * 0.5)), 3.0, true
		)
	elif hockey.held_for > Hockey.HOLD_LIMIT - HOLD_WARN and hockey.side >= 0:
		# The 7 seconds are running out for the team that has it.
		var left := clampf((Hockey.HOLD_LIMIT - hockey.held_for) / HOLD_WARN, 0.0, 1.0)
		var c := Color(UiKit.HOT, 0.9)
		draw_arc(p, r + 10.0, -PI * 0.5, -PI * 0.5 + TAU * left, 48, c, 4.0, true)
