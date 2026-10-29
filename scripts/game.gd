extends Node2D
## ONE MORE TAP — game flow: modes, input, states, camera, feedback, saving.
## Each mode has its rules (Track, Tower, Runner) and its drawing (WorldView,
## TowerView, RunnerView); sparks and labels in Fx, UI in Hud, sounds in Sfx,
## ads in Ads, sharing and store reviews in Social.

## AD: a full-screen ad is on top. REVIVE: back in the game after the
## "continue" video, waiting for a tap. NO_LIVES: a run was asked for, none left.
enum State { READY, PLAYING, DYING, OVER, PAUSED, AD, REVIVE, NO_LIVES }

## Per mode: points between colour changes, and the score that makes a run
## worth a "continue" video.
const MODES := {
	"zigzag": {"theme_every": 12, "continue_min": 5},
	"tower": {"theme_every": 12, "continue_min": 5},
	"runner": {"theme_every": 100, "continue_min": 150},
}
const PLAYFIELD_WIDTH := 720.0
const THEME_HUES := [188.0, 318.0, 42.0, 268.0, 150.0, 8.0]
const DEATH_PAUSE := 0.6  ## seconds of slow fall before the game over panel
const RESTART_LOCK := 0.35  ## ignore taps right after game over (no accidental restarts)
const REVIVE_LOCK := 0.5  ## after the video: time for the camera to settle on the ball
const REVIEW_DELAY := 1.2  ## the player sees the new record before the review dialog
const SAVE_PATH := "user://save.cfg"

var mode := "zigzag"
var run: RunRules
var state := State.READY
var best := {"zigzag": 0, "tower": 0, "runner": 0}
var muted := false
var lives := Lives.new()
var lives_on := false  ## only where ads run: the lost lives come back with a video
var reviews := ReviewPacing.new()

var _state_time := 0.0
var _new_record := false  ## the run just lost set a new record
var _shake := 0.0
var _cam := Vector2.ZERO
var _hue: float = THEME_HUES[0]
var _sharing := false  ## the picture of the run is being drawn

@onready var camera: Camera2D = $Camera2D
@onready var views := {"zigzag": $World, "tower": $Tower, "runner": $Runner}
@onready var fx: Fx = $Fx
@onready var sfx: Sfx = $Sfx
@onready var hud: Hud = $HUD
@onready var ads: Ads = $Ads
@onready var social: Social = $Social


func _ready() -> void:
	camera.make_current()
	lives_on = ads.available()
	_load_save()
	sfx.muted = muted
	hud.set_muted(muted)
	for m in views:
		views[m].fx = fx
	hud.retry_pressed.connect(_on_retry_pressed)
	hud.mute_pressed.connect(_on_mute_pressed)
	hud.continue_pressed.connect(_on_continue_pressed)
	hud.mode_pressed.connect(_on_mode_pressed)
	hud.menu_pressed.connect(_on_menu_pressed)
	hud.refill_pressed.connect(_on_refill_pressed)
	hud.privacy_pressed.connect(ads.open_privacy_policy)
	hud.consent_pressed.connect(ads.show_consent_options)
	hud.share_pressed.connect(_on_share_pressed)
	hud.app_pressed.connect(social.open_site)
	ads.changed.connect(_on_ads_changed)
	_set_mode(mode)


func _process(delta: float) -> void:
	delta = minf(delta, 1.0 / 30.0)  # a hitch must never teleport the ball off the track
	_state_time += delta

	match state:
		State.PLAYING:
			run.update(delta)
		State.DYING:
			if _state_time >= DEATH_PAUSE:
				_show_over()
		State.NO_LIVES:
			lives.update(_now())
			if lives.count > 0:
				_set_state(State.READY)  # one came back while waiting
				hud.show_start(best[mode])
	if state in [State.READY, State.OVER, State.NO_LIVES]:
		_show_lives()

	var view: ModeView = views[mode]
	var size := get_viewport_rect().size
	var target := view.camera_target(size, state == State.DYING or state == State.OVER)
	match state:
		State.PLAYING, State.READY:
			_cam = target  # the views ask for a target that moves smoothly: hard follow
		State.DYING, State.OVER:
			_cam = _cam.lerp(target, minf(1.0, delta * 5.0))
		State.REVIVE:
			_cam = _cam.lerp(target, minf(1.0, delta * 10.0))
	camera.position = _cam

	var shake_offset := Vector2.ZERO
	if _shake > 0.0:
		_shake = maxf(0.0, _shake - delta)
		var m := 9.0 * run.unit * (_shake / 0.35)
		shake_offset = Vector2(randf_range(-m, m), randf_range(-m, m))
	camera.offset = shake_offset

	var every: int = MODES[mode]["theme_every"]
	@warning_ignore("integer_division")
	var band: int = (run.score / every) % THEME_HUES.size()
	_hue = _lerp_hue(_hue, THEME_HUES[band], minf(1.0, delta * 3.0))
	view.hue = _hue
	hud.set_hue(_hue)

	view.view_rect = Rect2(camera.position + shake_offset - size * 0.5, size)
	fx.view_rect = view.view_rect
	view.tick(delta)
	fx.tick(delta)


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
			run.tap()
		State.PAUSED:
			_set_state(State.PLAYING)
			hud.show_playing()
		State.OVER:
			if _state_time >= RESTART_LOCK:
				_restart()
		State.REVIVE:
			if _state_time >= REVIVE_LOCK:
				_set_state(State.PLAYING)
				hud.show_playing()


## Shows the mode's start screen with a fresh run behind it.
func _set_mode(m: String) -> void:
	mode = m
	for k in views:
		views[k].visible = k == mode
	hud.set_mode(mode)
	hud.set_best(best[mode])
	_new_run()
	_set_state(State.READY)
	hud.show_start(best[mode])


func _new_run() -> void:
	var size := get_viewport_rect().size
	match mode:
		"tower":
			var tower := Tower.new(PLAYFIELD_WIDTH, 0)
			tower.jumped.connect(_on_jumped)
			run = tower
		"runner":
			var runner := Runner.new(PLAYFIELD_WIDTH, 0)
			runner.jumped.connect(_on_runner_jumped)
			runner.milestone.connect(_on_milestone)
			run = runner
		_:
			var track := Track.new(PLAYFIELD_WIDTH, size.y, 0)
			track.turned.connect(_on_turned)
			run = track
	run.scored.connect(_on_scored)
	run.died.connect(_on_died)
	fx.reset(run.unit)
	views[mode].reset(run)
	_cam = views[mode].camera_target(size, false)
	hud.set_score(0)
	hud.hide_combo()


func _start_run() -> void:
	if lives_on:
		if not lives.use(_now()):
			_set_state(State.NO_LIVES)
			hud.show_no_lives(ads.rewarded_ready())
			return
		_save()
	run.start()
	_set_state(State.PLAYING)
	hud.show_playing()


func _restart() -> void:
	_new_run()
	_start_run()


## The run has ended and the game is still: the only moment an interstitial
## may show (when one is due), before the results.
func _show_over() -> void:
	_new_record = run.score > best[mode]
	var beat_record: bool = _new_record and best[mode] > 0  # the first run always sets one
	if _new_record:
		best[mode] = run.score
		sfx.record()
	reviews.run_finished()
	_save()
	hud.set_best(best[mode])
	ads.run_finished()
	if ads.show_interstitial_if_due(_show_over_panel):
		_set_state(State.AD)
		hud.show_ad()
		return
	_show_over_panel()
	# A record that beats an earlier one is a good moment to ask for a review,
	# once the panel has been seen. Never right after an interstitial.
	if social.can_review() and reviews.should_ask(beat_record, _now()):
		social.prepare_review()
		get_tree().create_timer(REVIEW_DELAY).timeout.connect(_ask_review)


func _show_over_panel() -> void:
	_set_state(State.OVER)
	hud.show_over(
		run.score,
		best[mode],
		_new_record,
		run.reason,
		_stats(),
		_can_continue(),
		social.can_share()
	)


## Only while the results are still on screen: never over a run.
func _ask_review() -> void:
	if state == State.OVER and social.launch_review():
		reviews.asked(_now())
		_save()


## One line about the run for the game over panel.
func _stats() -> String:
	if run is Tower:
		var t := run as Tower
		return tr("STATS_TOWER") % [t.cleared, t.perfects, t.best_combo]
	if run is Runner:
		var r := run as Runner
		return tr("STATS_RUNNER") % [r.cleared, r.jumps]
	var k := run as Track
	return tr("STATS_ZIGZAG") % [k.seg, k.perfects, k.best_combo]


## One continue per run, for runs worth it, when a rewarded video is ready.
func _can_continue() -> bool:
	return (
		run.can_revive() and run.score >= int(MODES[mode]["continue_min"]) and ads.rewarded_ready()
	)


func _set_state(s: State) -> void:
	state = s
	_state_time = 0.0
	# The banner is for the start screen (the mode menu) only.
	ads.set_banner_visible(state == State.READY)
	hud.set_banner_height(ads.banner_height())


func _show_lives() -> void:
	if lives_on:
		hud.set_lives(lives.count, Lives.MAX, lives.seconds_to_next(_now()))
	else:
		hud.set_lives(0, 0, 0)


# --- rules events ----------------------------------------------------------


func _on_scored(score: int) -> void:
	# DINO counts every step it runs: the score only pops on each hundred.
	hud.set_score(score, not (run is Runner))


func _on_turned(perfect: bool, combo: int, snap: Vector2) -> void:
	if perfect:
		(views[mode] as WorldView).snap_ball(snap)
	_reward(perfect, combo, sfx.tick)


func _on_jumped(perfect: bool, combo: int) -> void:
	_reward(perfect, combo, sfx.jump)


## Feedback for a turn or a jump: a perfect one climbs the combo scale.
func _reward(perfect: bool, combo: int, plain_sound: Callable) -> void:
	var neon := Color.from_hsv(_hue / 360.0, 0.78, 1.0)
	var at: Vector2 = views[mode].ball_position()
	if perfect:
		fx.burst(at, 12, neon, 1.0)
		var label := tr("PERFECT") if combo < 2 else "%s ×%d" % [tr("PERFECT"), combo]
		fx.float_text(label, at + Vector2(0.0, -26.0 * run.unit), neon)
		hud.show_combo(combo)
		sfx.perfect(combo)
		_vibrate(14)
	else:
		fx.burst(at, 4, neon, 0.5)
		hud.hide_combo()
		plain_sound.call()
		_vibrate(8)


func _on_runner_jumped() -> void:
	var neon := Color.from_hsv(_hue / 360.0, 0.78, 1.0)
	var runner := run as Runner
	fx.burst(Vector2(runner.x + 18.0 * run.unit, 0.0), 5, neon, 0.4)  # dust from the feet
	sfx.jump()


func _on_milestone(score: int) -> void:
	var neon := Color.from_hsv(_hue / 360.0, 0.78, 1.0)
	var at: Vector2 = views[mode].ball_position()
	fx.float_text(str(score), at + Vector2(0.0, -40.0 * run.unit), neon)
	hud.set_score(score, true)
	sfx.milestone()
	_vibrate(10)


func _on_died(_reason: String) -> void:
	_set_state(State.DYING)
	views[mode].start_fall()
	_shake = 0.35
	sfx.die()
	_vibrate(45)


func _on_retry_pressed() -> void:
	if state == State.OVER and _state_time >= RESTART_LOCK:
		_restart()


func _on_mode_pressed(m: String) -> void:
	if state != State.READY or m == mode:
		return
	_set_mode(m)
	_save()


func _on_menu_pressed() -> void:
	if state == State.NO_LIVES or (state == State.OVER and _state_time >= RESTART_LOCK):
		_set_mode(mode)


func _on_continue_pressed() -> void:
	if state != State.OVER or not _can_continue():
		return
	_set_state(State.AD)
	hud.show_ad()
	ads.show_rewarded(_on_rewarded_closed)


func _on_rewarded_closed(earned: bool) -> void:
	if not earned or not run.revive():
		_show_over_panel()  # closed early: no reward, back to the game over panel
		return
	views[mode].revive()
	_vibrate(20)
	_set_state(State.REVIVE)
	hud.show_revive()


## Out of lives: a rewarded video gives them all back.
func _on_refill_pressed() -> void:
	if state != State.NO_LIVES or not ads.rewarded_ready():
		return
	_set_state(State.AD)
	hud.show_ad()
	ads.show_rewarded(_on_refill_closed)


func _on_refill_closed(earned: bool) -> void:
	if not earned:
		_set_state(State.NO_LIVES)  # closed early: no reward
		hud.show_no_lives(ads.rewarded_ready())
		return
	lives.refill()
	_save()
	_vibrate(20)
	_set_state(State.READY)  # the run behind the panel is fresh: start when ready
	hud.show_start(best[mode])


func _on_ads_changed() -> void:
	hud.set_consent_available(ads.consent_options_required())
	hud.set_banner_height(ads.banner_height())
	if state == State.OVER:
		hud.set_continue_available(_can_continue())
	elif state == State.NO_LIVES:
		hud.set_refill_available(ads.rewarded_ready())


## A picture of the run for a friend, with the link to the game.
func _on_share_pressed() -> void:
	if state != State.OVER or _sharing:
		return
	_sharing = true
	var image: Image = await hud.share_image(get_viewport().world_2d, camera.position)
	_sharing = false
	if state != State.OVER:
		return  # the player started again meanwhile: no share sheet over a run
	var text := tr("SHARE_TEXT") % [run.score, tr(Hud.MODE_NAMES[mode]), Social.SITE_URL]
	social.share(image, text)


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


func _now() -> float:
	return Time.get_unix_time_from_system()


func _lerp_hue(from: float, to: float, t: float) -> float:
	var d := fposmod(to - from + 180.0, 360.0) - 180.0
	return fposmod(from + d * t, 360.0)


## The first mode keeps the key it had before there were modes: old records stay.
func _best_key(m: String) -> String:
	return "best" if m == "zigzag" else "best_" + m


func _load_save() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		for m in MODES:
			best[m] = int(cfg.get_value("score", _best_key(m), 0))
		muted = bool(cfg.get_value("settings", "muted", false))
		var saved := str(cfg.get_value("settings", "mode", mode))
		if MODES.has(saved):
			mode = saved
		lives = Lives.new(
			int(cfg.get_value("lives", "count", Lives.MAX)),
			float(cfg.get_value("lives", "since", 0.0))
		)
		reviews = ReviewPacing.new(
			int(cfg.get_value("review", "runs", 0)),
			int(cfg.get_value("review", "asks", 0)),
			float(cfg.get_value("review", "last_ask", 0.0))
		)


func _save() -> void:
	var cfg := ConfigFile.new()
	for m in MODES:
		cfg.set_value("score", _best_key(m), best[m])
	cfg.set_value("settings", "muted", muted)
	cfg.set_value("settings", "mode", mode)
	cfg.set_value("lives", "count", lives.count)
	cfg.set_value("lives", "since", lives.since)
	cfg.set_value("review", "runs", reviews.runs)
	cfg.set_value("review", "asks", reviews.asks)
	cfg.set_value("review", "last_ask", reviews.last_ask)
	cfg.save(SAVE_PATH)
