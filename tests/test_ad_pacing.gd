extends SceneTree
## Headless tests for when full-screen ads may appear. Run from the project folder:
##   godot --headless --path . --script res://tests/test_ad_pacing.gd
## Exit code 0 = all passed.

const AdPacingScript := preload("res://scripts/ad_pacing.gd")

var _fails := 0


func _init() -> void:
	_test_no_ad_right_after_launch()
	_test_needs_runs_and_time()
	_test_rewarded_resets()
	print("all tests passed" if _fails == 0 else "%d failures" % _fails)
	quit(1 if _fails > 0 else 0)


func _check(cond: bool, msg: String) -> void:
	if not cond:
		_fails += 1
		print("FAIL ", msg)


func _test_no_ad_right_after_launch() -> void:
	var p = AdPacingScript.new(100.0)
	for i in 10:
		p.run_finished()
	_check(not p.should_show_interstitial(130.0), "no interstitial in the first seconds")
	_check(
		p.should_show_interstitial(100.0 + AdPacingScript.MIN_SECONDS),
		"interstitial allowed once enough time passed"
	)


func _test_needs_runs_and_time() -> void:
	var p = AdPacingScript.new(0.0)
	var now := 1000.0
	for i in AdPacingScript.RUNS_BETWEEN - 1:
		p.run_finished()
	_check(not p.should_show_interstitial(now), "not before enough runs")
	p.run_finished()
	_check(p.should_show_interstitial(now), "after enough runs and time")
	p.ad_shown(now)
	_check(not p.should_show_interstitial(now), "never twice in a row")
	for i in 20:
		p.run_finished()
	_check(not p.should_show_interstitial(now + 30.0), "not too soon after the last ad")
	_check(p.should_show_interstitial(now + AdPacingScript.MIN_SECONDS), "again later")


func _test_rewarded_resets() -> void:
	var p = AdPacingScript.new(0.0)
	for i in 5:
		p.run_finished()
	p.ad_shown(500.0)  # the player watched a video to continue
	p.run_finished()
	_check(not p.should_show_interstitial(510.0), "no interstitial right after a rewarded ad")
