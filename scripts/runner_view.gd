class_name RunnerView
extends ModeView
## DINO: a pixel-art runner in neon, homage to the browser's offline game:
## ground, cacti, birds, clouds and stars, the dino near the left edge.
## Pure presentation: it reads the Runner, never changes it.

const PIXEL := 2.0  ## sprite pixel, in px at 390 wide (scaled by runner.unit)
const DINO_SCREEN_X := 0.14  ## the dino's left edge at 14% of the screen width
const GROUND_SCREEN_Y := 0.72  ## the ground line at 72% of the screen height
const STRIDE := 13.0  ## px run per step of the legs
const BLINK_EVERY := 3.2  ## seconds between blinks while waiting

# Sprites: "#" is a pixel. Drawn for this game; sizes match the Runner's.
const DINO_BODY := [
	"............########..",
	"...........##########.",
	"...........##.########",
	"...........###########",
	"...........###########",
	"...........###########",
	"...........######.....",
	"...........#########..",
	"#.........######......",
	"#........#######......",
	"##......##########....",
	"###....#########.#....",
	"####..##########......",
	"################......",
	".###############......",
	"..##############......",
	"...############.......",
	"....##########........",
	".....########.........",
]
const DINO_LEGS := {
	"stand":
	[
		"......###..##.........",
		"......##....#.........",
		"......#.....#.........",
		"......##....##........",
	],
	"left":
	[
		"......###..##.........",
		"......##...##.........",
		"......#...............",
		"......##..............",
	],
	"right":
	[
		"......###..##.........",
		".......##...#.........",
		"............#.........",
		"............##........",
	],
}
const CACTUS_SMALL := [
	"....#....",
	"...###...",
	"...###...",
	"...###.#.",
	".#.###.#.",
	".#.###.#.",
	".#.###.#.",
	".#.#####.",
	".#.###...",
	".#####...",
	"...###...",
	"...###...",
	"...###...",
	"...###...",
	"...###...",
	"...###...",
	"...###...",
]
const CACTUS_LARGE := [
	"......#......",
	".....###.....",
	".....###.....",
	"....#####....",
	"....#####.#..",
	"....#####.##.",
	"....#####.##.",
	".#..#####.##.",
	"##..#####.##.",
	"##..#####.##.",
	"##..#####.##.",
	"##..########.",
	"##..#######..",
	"##..#####....",
	"#########....",
	".########....",
	"....#####....",
	"....#####....",
	"....#####....",
	"....#####....",
	"....#####....",
	"....#####....",
	"....#####....",
	"....#####....",
	"....#####....",
]
const BIRD_UP := [
	"..........#..........",
	"..........##.........",
	"..........###........",
	"..........####.......",
	"..........#####......",
	"....##....######.....",
	"...####...#######....",
	"#######..########....",
	"...#################.",
	"....###############..",
	"......##########.....",
	".........#####.......",
	".....................",
	".....................",
]
const BIRD_DOWN := [
	".....................",
	".....................",
	".....................",
	".....................",
	".....................",
	"....##...............",
	"...####..............",
	"#######..............",
	"...#################.",
	"....###############..",
	"......##########.....",
	"..........######.....",
	"..........#####......",
	"..........####.......",
]
const CLOUD := [
	".........######........",
	"........#......##......",
	"....#####........#.....",
	"...#..............###..",
	".###.................#.",
	"#.....................#",
	"#######################",
]

var runner: Runner

var _tex := {}  ## name -> ImageTexture, white pixels to tint
var _time := 0.0
var _dying := false
var _death_t := 0.0


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	for legs in DINO_LEGS:
		_tex["dino_" + legs] = _texture(DINO_BODY + DINO_LEGS[legs])
	_tex["cactus_small"] = _texture(CACTUS_SMALL)
	_tex["cactus_large"] = _texture(CACTUS_LARGE)
	_tex["bird_up"] = _texture(BIRD_UP)
	_tex["bird_down"] = _texture(BIRD_DOWN)
	_tex["cloud"] = _texture(CLOUD)


func reset(rules: RunRules) -> void:
	runner = rules as Runner
	_dying = false
	_death_t = 0.0
	queue_redraw()


func camera_target(view: Vector2, _after_fall: bool) -> Vector2:
	return Vector2(runner.x - view.x * (DINO_SCREEN_X - 0.5), -view.y * (GROUND_SCREEN_Y - 0.5))


func ball_position() -> Vector2:
	var size := Runner.DINO_SIZE * runner.unit
	return Vector2(runner.x + size.x * 0.5, -runner.height - size.y * 0.5)


func start_fall() -> void:
	_dying = true
	_death_t = 0.0
	fx.burst(ball_position(), 28, HOT, 1.5)


func revive() -> void:
	_dying = false
	_death_t = 0.0
	fx.burst(ball_position(), 18, Color.from_hsv(hue / 360.0, 0.78, 1.0), 1.2)


func tick(delta: float) -> void:
	if runner == null:
		return
	_time += delta
	if _dying:
		_death_t += delta
	queue_redraw()


func _draw() -> void:
	if runner == null:
		return
	var h := hue / 360.0
	var neon := Color.from_hsv(h, 0.78, 1.0)
	draw_rect(view_rect.grow(64.0), Color.from_hsv(h, 0.6, 0.04))
	_draw_sky(neon)
	_draw_ground(neon)
	for o in runner.obstacles:
		if o.x > view_rect.end.x or o.right() < view_rect.position.x:
			continue
		_draw_obstacle(o, neon)
	if _dying and runner.hit != null:
		_draw_miss_marker(runner.hit)
	_draw_dino(neon)


## Stars far away and clouds closer: both drift slower than the ground.
func _draw_sky(neon: Color) -> void:
	var u := runner.unit
	var r := view_rect
	var stars := PackedVector2Array()
	var sp := 34.0 * u
	var shift := r.position.x * 0.9  # the stars move at a tenth of the ground speed
	var i0 := floori((r.position.x - shift) / sp)
	var i1 := ceili((r.end.x - shift) / sp)
	for i in range(i0, i1 + 1):
		var hsh := hash(i * 7919)
		if hsh % 3 != 0:
			continue
		var x := shift + i * sp + float(hsh % 17) * u
		var y := -float(70 + (hsh >> 5) % 520) * u
		stars.append(Vector2(x, y))
		stars.append(Vector2(x + 2.0 * u, y))
	if stars.size() >= 2:
		draw_multiline(stars, Color(neon, 0.22), 2.0 * u)

	var cloud: Texture2D = _tex["cloud"]
	var size := Vector2(cloud.get_size()) * PIXEL * u
	var csp := 150.0 * u
	var cshift := r.position.x * 0.75
	for i in range(floori((r.position.x - cshift) / csp) - 1, ceili((r.end.x - cshift) / csp) + 1):
		var hsh := hash(i * 104729)
		if hsh % 2 != 0:
			continue
		var x := cshift + i * csp + float(hsh % 60) * u
		var y := -float(110 + (hsh >> 7) % 230) * u
		draw_texture_rect(cloud, Rect2(Vector2(x, y), size), false, Color(neon, 0.18))


func _draw_ground(neon: Color) -> void:
	var u := runner.unit
	var r := view_rect.grow(8.0)
	# A floor grid under the line: lines fixed to the ground scroll at full speed.
	var grid := PackedVector2Array()
	var gsp := 40.0 * u
	var x := r.position.x - fposmod(r.position.x, gsp)
	while x < r.end.x:
		grid.append(Vector2(x, 0.0))
		grid.append(Vector2(x - (x - view_rect.get_center().x) * 0.6, r.end.y))
		x += gsp
	var y := 16.0 * u
	while y < r.end.y:
		grid.append(Vector2(r.position.x, y))
		grid.append(Vector2(r.end.x, y))
		y *= 1.55
	draw_multiline(grid, Color(neon, 0.07), 1.5 * u)

	# The ground line, with bumps and pebbles like the original's sandy floor.
	draw_line(Vector2(r.position.x, 0.0), Vector2(r.end.x, 0.0), Color(neon, 0.18), 7.0 * u)
	draw_line(Vector2(r.position.x, 0.0), Vector2(r.end.x, 0.0), neon, 2.0 * u)
	var bits := PackedVector2Array()
	var sp := 9.0 * u
	for i in range(floori(r.position.x / sp), ceili(r.end.x / sp) + 1):
		var hsh := hash(i * 31337)
		var bx := i * sp
		match hsh % 7:
			0:
				bits.append(Vector2(bx, -2.0 * u))  # a bump on the line
				bits.append(Vector2(bx + 4.0 * u, -2.0 * u))
			1, 2:
				var by := float(4 + (hsh >> 4) % 10) * u  # a pebble below it
				bits.append(Vector2(bx, by))
				bits.append(Vector2(bx + float(2 + (hsh >> 9) % 4) * u, by))
	if bits.size() >= 2:
		draw_multiline(bits, Color(neon, 0.7), 2.0 * u)


func _draw_obstacle(o: Runner.Obstacle, neon: Color) -> void:
	var u := runner.unit
	if o.kind == Runner.Kind.BIRD_LOW or o.kind == Runner.Kind.BIRD_HIGH:
		var frame := "bird_up" if int(_time * 6.0) % 2 == 0 else "bird_down"
		_sprite(_tex[frame], Rect2(o.x, -o.y - o.size.y, o.size.x, o.size.y), neon)
		return
	var one := (Runner.CACTUS_LARGE if o.kind == Runner.Kind.LARGE else Runner.CACTUS_SMALL) * u
	var tex: Texture2D = _tex["cactus_large" if o.kind == Runner.Kind.LARGE else "cactus_small"]
	for i in o.count:
		var x := o.x + i * (one.x + Runner.CACTUS_GAP * u)
		_sprite(tex, Rect2(x, -one.y, one.x, one.y), neon)


func _draw_dino(neon: Color) -> void:
	var u := runner.unit
	var size := Runner.DINO_SIZE * u
	var rect := Rect2(runner.x, -runner.height - size.y, size.x, size.y)
	var legs := "stand"
	if runner.started and runner.alive and not runner.airborne:
		legs = "left" if int(runner.x / (STRIDE * u)) % 2 == 0 else "right"
	var color := HOT if _dying else neon
	_sprite(_tex["dino_" + legs], rect, color)
	# The eye: a dark pixel, closed now and then while waiting, a cross when hit.
	var px := PIXEL * u
	var eye := rect.position + Vector2(13.0, 2.0) * px
	var dark := Color.from_hsv(hue / 360.0, 0.6, 0.04)
	if _dying:
		draw_rect(Rect2(eye - Vector2(px, px), Vector2(px * 3.0, px * 3.0)), dark)
		draw_line(eye - Vector2(px, px) * 0.6, eye + Vector2(px, px) * 1.6, color, px * 0.6)
		draw_line(
			eye + Vector2(px * 1.6, -px * 0.6), eye + Vector2(-px * 0.6, px * 1.6), color, px * 0.6
		)
	elif not runner.started and fposmod(_time, BLINK_EVERY) < 0.14:
		draw_rect(Rect2(eye, Vector2(px, px)), color)


## Pulsing red frame round what hit the dino.
func _draw_miss_marker(o: Runner.Obstacle) -> void:
	if _death_t < 0.12:
		return
	var u := runner.unit
	var pulse := 0.5 + 0.5 * sin((_death_t - 0.12) * 9.0)
	var rect := Rect2(o.x, -o.y - o.size.y, o.size.x, o.size.y)
	draw_rect(rect.grow((6.0 + pulse * 4.0) * u), Color(HOT, 0.9), false, 3.0 * u)
	draw_rect(rect.grow((16.0 + pulse * 6.0) * u), Color(HOT, 0.25), false, 2.0 * u)


## A sprite in the theme colour, with a soft neon halo.
func _sprite(tex: Texture2D, rect: Rect2, color: Color) -> void:
	var g := 1.6 * runner.unit
	for off in [Vector2(-g, 0.0), Vector2(g, 0.0), Vector2(0.0, -g), Vector2(0.0, g)]:
		draw_texture_rect(tex, Rect2(rect.position + off, rect.size), false, Color(color, 0.22))
	draw_texture_rect(tex, rect, false, color.lerp(Color.WHITE, 0.2))


func _texture(rows: Array) -> ImageTexture:
	var w: int = rows[0].length()
	var img := Image.create(w, rows.size(), false, Image.FORMAT_RGBA8)
	img.fill(Color(1, 1, 1, 0))
	for y in rows.size():
		var row: String = rows[y]
		for x in w:
			if row[x] == "#":
				img.set_pixel(x, y, Color.WHITE)
	return ImageTexture.create_from_image(img)
