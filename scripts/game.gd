extends Node2D
## ONE MORE TAP — game flow: modes, input, states, camera, feedback, saving.
## Each mode has its rules (Track, Tower, Runner) and its drawing (WorldView,
## TowerView, RunnerView); sparks and labels in Fx, UI in Hud, sounds in Sfx,
## ads in Ads, purchases in Shop.

## AD: a full-screen ad is on top. REVIVE: back in the game after a continue,
## waiting for a tap. SHOP: the shop is open, from the start screen or the
## game over panel.
enum State { READY, PLAYING, DYING, OVER, PAUSED, AD, REVIVE, SHOP }

## Per mode: points between colour changes, and the score that makes a run
## worth a "continue" video.
const MODES := {
	"zigzag": {"theme_every": 12, "continue_min": 5},
	"tower": {"theme_every": 12, "continue_min": 5},
	"runner": {"theme_every": 100, "continue_min": 150},
}
const LOCKED_MODE := "runner"  ## DINO opens after days in a row (see Streak)
const PLAYFIELD_WIDTH := 720.0
const SHOP_CAMERA_SHIFT := 0.2  ## shop open: the game behind slides down, below the cards
const DEATH_PAUSE := 0.6  ## seconds of slow fall before the game over panel
const RESTART_LOCK := 0.35  ## ignore taps right after game over (no accidental restarts)
const REVIVE_LOCK := 0.5  ## after the video: time for the camera to settle on the ball
const SAVE_PATH := "user://save.cfg"

var mode := "zigzag"
var run: RunRules
var state := State.READY
var best := {"zigzag": 0, "tower": 0, "runner": 0}
var muted := false
var streak := Streak.new()

var _state_time := 0.0
var _new_record := false  ## the run just lost set a new record
var _shake := 0.0
var _cam := Vector2.ZERO
var _hue := 0.0
var _preview := {}  ## kind -> look picked in the shop, shown until it closes
var _shop_from := State.READY  ## where the shop was opened, to go back there

@onready var camera: Camera2D = $Camera2D
@onready var views := {"zigzag": $World, "tower": $Tower, "runner": $Runner}
@onready var fx: Fx = $Fx
@onready var sfx: Sfx = $Sfx
@onready var hud: Hud = $HUD
@onready var ads: Ads = $Ads
@onready var shop: Shop = $Shop


func _ready() -> void:
	camera.make_current()
	_load_save()
	sfx.muted = muted
	hud.set_muted(muted)
	hud.shop_panel.setup(shop, best)
	_hue = Catalog.theme_hue(_look("colors"), 0, 1, _now())
	for m in views:
		views[m].fx = fx
	hud.retry_pressed.connect(_on_retry_pressed)
	hud.mute_pressed.connect(_on_mute_pressed)
	hud.continue_pressed.connect(_on_continue_pressed)
	hud.mode_pressed.connect(_on_mode_pressed)
	hud.menu_pressed.connect(_on_menu_pressed)
	hud.privacy_pressed.connect(ads.open_privacy_policy)
	hud.consent_pressed.connect(ads.show_consent_options)
	hud.shop_pressed.connect(_on_shop_pressed)
	hud.shop_panel.closed.connect(_on_shop_closed)
	hud.shop_panel.look_previewed.connect(_on_look_previewed)
	hud.shop_panel.wear_pressed.connect(_on_wear_pressed)
	hud.shop_panel.buy_pressed.connect(shop.buy)
	hud.shop_panel.restore_pressed.connect(shop.restore)
	ads.changed.connect(_on_ads_changed)
	shop.changed.connect(_on_shop_changed)
	shop.finished.connect(_on_shop_finished)
	shop.start()
	if not shop.inventory.no_ads():
		ads.start()
	_set_mode(mode)
	_visit_today()


func _process(delta: float) -> void:
	delta = minf(delta, 1.0 / 30.0)  # a hitch must never teleport the ball off the track
	_state_time += delta

	match state:
		State.PLAYING:
			run.update(delta)
		State.DYING:
			if _state_time >= DEATH_PAUSE:
				_show_over()

	var view: ModeView = views[mode]
	var size := get_viewport_rect().size
	var after_fall := (
		state in [State.DYING, State.OVER] or (state == State.SHOP and _shop_from == State.OVER)
	)
	var target := view.camera_target(size, after_fall)
	if state == State.SHOP:
		target.y -= size.y * SHOP_CAMERA_SHIFT
	match state:
		State.PLAYING, State.READY:
			# The views ask for a target that moves smoothly: hard follow. Back
			# from the shop, glide there first.
			if state == State.READY and _state_time < 0.5:
				_cam = _cam.lerp(target, minf(1.0, delta * 10.0))
			else:
				_cam = target
		State.DYING, State.OVER, State.SHOP:
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
	var theme := Catalog.theme_hue(_look("colors"), run.score, every, _now())
	_hue = _lerp_hue(_hue, theme, minf(1.0, delta * 3.0))
	view.hue = _hue
	view.ball_look = _look("ball")
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
	# Back after midnight, with the game left open: that is another day too.
	if what == NOTIFICATION_APPLICATION_RESUMED and is_node_ready():
		_visit_today()


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
	if not _mode_open(m):
		m = "zigzag"
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
	run.start()
	_set_state(State.PLAYING)
	hud.show_playing()


func _restart() -> void:
	ads.run_finished()
	if ads.show_interstitial_if_due(_on_interstitial_closed):
		_set_state(State.AD)
		hud.show_ad()
		return
	_new_run()
	_start_run()


func _on_interstitial_closed() -> void:
	# Back from an ad the player did not choose: let them start when ready.
	_new_run()
	_set_state(State.READY)
	hud.show_start(best[mode])


func _show_over() -> void:
	_new_record = run.score > best[mode]
	var unlocked := PackedStringArray()
	if _new_record:
		for id in Catalog.LOOKS:
			var unlock: Array = Catalog.LOOKS[id].get("unlock", [])
			if (
				not unlock.is_empty()
				and unlock[0] == mode
				and best[mode] < unlock[1]
				and run.score >= unlock[1]
			):
				unlocked.append(Catalog.LOOKS[id]["name"])
		best[mode] = run.score
		_save()
		sfx.record()
	hud.set_best(best[mode])
	_show_over_panel()
	hud.show_unlocked(unlocked)


func _show_over_panel() -> void:
	_set_state(State.OVER)
	hud.show_over(
		run.score,
		best[mode],
		_new_record,
		run.reason,
		_stats(),
		_continue_offer(),
		shop.inventory.tokens
	)


## One line about the run for the game over panel.
func _stats() -> String:
	if run is Tower:
		var t := run as Tower
		return "%d buchi  ·  %d perfetti  ·  combo max %d" % [t.cleared, t.perfects, t.best_combo]
	if run is Runner:
		var r := run as Runner
		return "%d ostacoli  ·  %d salti" % [r.cleared, r.jumps]
	var k := run as Track
	return "%d piattaforme  ·  %d perfetti  ·  combo max %d" % [k.seg, k.perfects, k.best_combo]


## One continue per run, for runs worth it. What CONTINUA does: "token"
## (spends one, no video), "video", "shop" (an ad-free player out of tokens
## buys more), or "" (no continue).
func _continue_offer() -> String:
	if not run.can_revive() or run.score < int(MODES[mode]["continue_min"]):
		return ""
	if shop.inventory.tokens > 0:
		return "token"
	if shop.inventory.no_ads():
		return "shop"
	return "video" if ads.rewarded_ready() else ""


func _set_state(s: State) -> void:
	state = s
	_state_time = 0.0


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
		var boost := BallLook.perfect_boost(_look("ball"))
		fx.burst(at, int(12 * boost), neon, boost)
		if boost > 2.0:
			fx.burst(at, 10, Color.WHITE, 1.6)
			sfx.sparkle()
		var label := "PERFETTO" if combo < 2 else "PERFETTO ×%d" % combo
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
	if not _mode_open(m):
		hud.show_mode_locked(streak.days, Streak.DAYS_TO_UNLOCK)
		return
	_set_mode(m)
	_save()


func _on_menu_pressed() -> void:
	if state != State.OVER or _state_time < RESTART_LOCK:
		return
	ads.run_finished()  # it counts towards the next interstitial, on a later RIPROVA
	_set_mode(mode)


func _on_continue_pressed() -> void:
	if state != State.OVER:
		return
	match _continue_offer():
		"token":
			if run.revive() and shop.inventory.spend_token():
				_save()
				_revived()
		"video":
			_set_state(State.AD)
			hud.show_ad()
			ads.show_rewarded(_on_rewarded_closed)
		"shop":
			_open_shop("extra", "tokens_10")


func _on_rewarded_closed(earned: bool) -> void:
	if not earned or not run.revive():
		_show_over_panel()  # closed early: no reward, back to the game over panel
		return
	_revived()


func _revived() -> void:
	views[mode].revive()
	_vibrate(20)
	_set_state(State.REVIVE)
	hud.show_revive()


func _on_ads_changed() -> void:
	hud.set_consent_available(ads.consent_options_required())
	if state == State.OVER:
		hud.set_continue_offer(_continue_offer(), shop.inventory.tokens)


# --- shop ------------------------------------------------------------------


func _on_shop_pressed() -> void:
	if state == State.READY:
		_open_shop("colors")


func _open_shop(tab: String, pick := "") -> void:
	_shop_from = state
	_set_state(State.SHOP)
	shop.refresh()
	hud.show_shop(tab, pick)


func _on_shop_closed() -> void:
	if state != State.SHOP:
		return
	_preview.clear()
	if _shop_from == State.OVER:
		_show_over_panel()
	else:
		_set_state(State.READY)
		hud.show_start(best[mode])


## A card was picked: its look shows on the game behind, owned or not.
func _on_look_previewed(id: String) -> void:
	if Catalog.LOOKS.has(id):
		_preview[Catalog.LOOKS[id]["kind"]] = id


func _on_wear_pressed(id: String) -> void:
	if shop.inventory.wear(id, best):
		sfx.buy()
		_save()
		hud.shop_panel.refresh()


func _on_shop_changed() -> void:
	_save()
	if shop.inventory.no_ads():
		ads.turn_off()
	match state:
		State.SHOP:
			hud.shop_panel.refresh()
		State.OVER:
			hud.set_continue_offer(_continue_offer(), shop.inventory.tokens)


func _on_shop_finished(id: String, outcome: String) -> void:
	if outcome == "ok" and id != "restore":
		sfx.buy()
		if Catalog.LOOKS.has(id) and shop.inventory.wear(id, best):
			_preview.erase(Catalog.LOOKS[id]["kind"])
			_save()
	if state == State.SHOP:
		hud.shop_panel.show_result(id, outcome)


# --- days in a row ---------------------------------------------------------


func _mode_open(m: String) -> bool:
	return m != LOCKED_MODE or streak.unlocked


func _visit_today() -> void:
	var opened := streak.visit(Streak.day_number(Time.get_date_dict_from_system()))
	_save()
	hud.set_mode_lock(
		LOCKED_MODE, "" if streak.unlocked else "%d/%d" % [streak.days, Streak.DAYS_TO_UNLOCK]
	)
	if opened and state == State.READY:
		sfx.record()
		hud.show_notice("DINO È APERTO!\nSalta cactus e uccelli: tocca DINO in basso")


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


## The look shown for a kind: the one picked in the shop, or the one worn.
func _look(kind: String) -> String:
	return _preview.get(kind, shop.inventory.wearing[kind])


func _now() -> float:
	return Time.get_ticks_msec() / 1000.0


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
		streak.load_from(cfg)
		shop.inventory.load_from(cfg, best)
	# Played DINO before it had to be opened: it stays open.
	if best[LOCKED_MODE] > 0:
		streak.unlocked = true


func _save() -> void:
	var cfg := ConfigFile.new()
	for m in MODES:
		cfg.set_value("score", _best_key(m), best[m])
	cfg.set_value("settings", "muted", muted)
	cfg.set_value("settings", "mode", mode)
	streak.save_to(cfg)
	shop.inventory.save_to(cfg)
	cfg.save(SAVE_PATH)
