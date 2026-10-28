extends Node2D
## ONE MORE TAP — game flow: input, states, camera, feedback, saving.
## Rules live in Track, drawing in WorldView, UI in Hud, sounds in Sfx.

enum State { READY, PLAYING, DYING, OVER, PAUSED }

const PLAYFIELD_WIDTH := 720.0
const BALL_SCREEN_Y := 0.66  ## the ball sits at 66% of the screen height
const MISS_SCREEN_Y := 0.74  ## after a fall, the missed corner is shown here
const THEME_HUES := [188.0, 318.0, 42.0, 268.0, 150.0, 8.0]
const POINTS_PER_THEME := 12
const DEATH_PAUSE := 0.6  ## seconds of slow fall before the game over panel
const RESTART_LOCK := 0.35  ## ignore taps right after game over (no accidental restarts)
const SAVE_PATH := "user://save.cfg"

var track: Track
var state := State.READY
var best := 0
var muted := false

var _state_time := 0.0
var _shake := 0.0
var _cam_y := 0.0
var _hue: float = THEME_HUES[0]

@onready var camera: Camera2D = $Camera2D
@onready var world: WorldView = $World
@onready var sfx: Sfx = $Sfx
@onready var hud: Hud = $HUD


func _ready() -> void:
	camera.make_current()
	_load_save()
	sfx.muted = muted
	hud.set_muted(muted)
	hud.set_best(best)
	hud.retry_pressed.connect(_on_retry_pressed)
	hud.mute_pressed.connect(_on_mute_pressed)
	_new_track()
	hud.show_start(best)


func _process(delta: float) -> void:
	delta = minf(delta, 1.0 / 30.0)  # a hitch must never teleport the ball off the track
	_state_time += delta

	match state:
		State.PLAYING:
			track.update(delta)
		State.DYING:
			if _state_time >= DEATH_PAUSE:
				_show_over()

	var view := get_viewport_rect().size
	if state == State.PLAYING or state == State.READY:
		# Vertical speed is constant, so a hard follow is perfectly smooth.
		_cam_y = track.ball.y - view.y * (BALL_SCREEN_Y - 0.5)
	elif state == State.DYING or state == State.OVER:
		# Glide to the missed corner, low on screen, below the game over text.
		var target := track.corner.y - view.y * (MISS_SCREEN_Y - 0.5)
		_cam_y = lerpf(_cam_y, target, minf(1.0, delta * 5.0))
	camera.position = Vector2(PLAYFIELD_WIDTH * 0.5, _cam_y)

	var shake_offset := Vector2.ZERO
	if _shake > 0.0:
		_shake = maxf(0.0, _shake - delta)
		var m := 9.0 * track.unit * (_shake / 0.35)
		shake_offset = Vector2(randf_range(-m, m), randf_range(-m, m))
	camera.offset = shake_offset

	@warning_ignore("integer_division")
	var band: int = (track.score / POINTS_PER_THEME) % THEME_HUES.size()
	_hue = _lerp_hue(_hue, THEME_HUES[band], minf(1.0, delta * 3.0))
	world.hue = _hue
	hud.set_hue(_hue)

	world.view_rect = Rect2(camera.position + shake_offset - view * 0.5, view)
	world.tick(delta)


func _unhandled_input(event: InputEvent) -> void:
	if _is_tap(event):
		get_viewport().set_input_as_handled()
		_press()


func _notification(what: int) -> void:
	# Phone call, notification shade, app switch: pause instead of losing the run.
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		if state == State.PLAYING:
			_set_state(State.PAUSED)
			hud.show_pause()


# --- flow ------------------------------------------------------------------


func _press() -> void:
	match state:
		State.READY:
			_start_run()
		State.PLAYING:
			track.tap()
		State.PAUSED:
			_set_state(State.PLAYING)
			hud.show_playing()
		State.OVER:
			if _state_time >= RESTART_LOCK:
				_restart()


func _new_track() -> void:
	var view := get_viewport_rect().size
	track = Track.new(PLAYFIELD_WIDTH, view.y, 0)
	track.scored.connect(_on_scored)
	track.turned.connect(_on_turned)
	track.died.connect(_on_died)
	world.reset(track)
	_cam_y = track.ball.y - view.y * (BALL_SCREEN_Y - 0.5)
	hud.set_score(0)
	hud.hide_combo()


func _start_run() -> void:
	track.start()
	_set_state(State.PLAYING)
	hud.show_playing()


func _restart() -> void:
	_new_track()
	_start_run()


func _show_over() -> void:
	_set_state(State.OVER)
	var new_record := track.score > best
	if new_record:
		best = track.score
		_save()
		sfx.record()
	hud.set_best(best)
	hud.show_over(
		track.score, best, new_record, track.reason, track.seg, track.perfects, track.best_combo
	)


func _set_state(s: State) -> void:
	state = s
	_state_time = 0.0


# --- track events ----------------------------------------------------------


func _on_scored(score: int) -> void:
	hud.set_score(score, true)


func _on_turned(perfect: bool, combo: int, snap: Vector2) -> void:
	var neon := Color.from_hsv(_hue / 360.0, 0.78, 1.0)
	if perfect:
		world.snap_ball(snap)
		world.burst(track.ball, 12, neon, 1.0)
		var label := "PERFETTO" if combo < 2 else "PERFETTO ×%d" % combo
		world.float_text(label, track.ball + Vector2(0.0, -26.0 * track.unit), neon)
		hud.show_combo(combo)
		sfx.perfect(combo)
		_vibrate(14)
	else:
		world.burst(track.ball, 4, neon, 0.5)
		hud.hide_combo()
		sfx.tick()
		_vibrate(8)


func _on_died(_reason: String) -> void:
	_set_state(State.DYING)
	world.start_fall()
	_shake = 0.35
	sfx.die()
	_vibrate(45)


func _on_retry_pressed() -> void:
	if state == State.OVER and _state_time >= RESTART_LOCK:
		_restart()


func _on_mute_pressed() -> void:
	muted = not muted
	sfx.muted = muted
	hud.set_muted(muted)
	_save()


# --- helpers ---------------------------------------------------------------


func _is_tap(event: InputEvent) -> bool:
	# Count every finger, so a tap still works while another finger rests on the
	# glass. The left click that Godot emulates from the first touch (device -1)
	# is skipped: that touch was already counted. Real mouse clicks still count.
	var st := event as InputEventScreenTouch
	if st:
		return st.pressed
	var mb := event as InputEventMouseButton
	if mb:
		return mb.device != -1 and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT
	var key := event as InputEventKey
	if key:
		return key.pressed and not key.echo and key.keycode in [KEY_SPACE, KEY_ENTER, KEY_UP]
	return false


func _vibrate(ms: int) -> void:
	if OS.has_feature("mobile"):
		Input.vibrate_handheld(ms)


func _lerp_hue(from: float, to: float, t: float) -> float:
	var d := fposmod(to - from + 180.0, 360.0) - 180.0
	return fposmod(from + d * t, 360.0)


func _load_save() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		best = int(cfg.get_value("score", "best", 0))
		muted = bool(cfg.get_value("settings", "muted", false))


func _save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("score", "best", best)
	cfg.set_value("settings", "muted", muted)
	cfg.save(SAVE_PATH)
