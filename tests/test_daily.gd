extends SceneTree
## Headless tests for the daily challenge: numbers, seeds, the same track on
## every phone, the best of the day and saving. Run from the project folder:
##   godot --headless --path . --script res://tests/test_daily.gd
## Exit code 0 = all passed.

const DailyScript := preload("res://scripts/daily.gd")
const TrackScript := preload("res://scripts/track.gd")
const TowerScript := preload("res://scripts/tower.gd")
const RunnerScript := preload("res://scripts/runner.gd")

const MODES := ["zigzag", "tower", "runner"]

var _fails := 0


func _init() -> void:
	_test_numbers()
	_test_seeds()
	_test_same_zigzag_on_every_phone()
	_test_same_tower_and_dino()
	_test_best_of_the_day()
	_test_save_roundtrip()
	print("all tests passed" if _fails == 0 else "%d failures" % _fails)
	quit(1 if _fails > 0 else 0)


func _check(cond: bool, msg: String) -> void:
	if not cond:
		_fails += 1
		print("FAIL ", msg)


func _test_numbers() -> void:
	var first: int = DailyScript.FIRST_DAY
	_check(DailyScript.number(first) == 1, "the first challenge is #1")
	_check(DailyScript.number(first + 9) == 10, "one more every day")
	_check(DailyScript.number(first - 5) == 1, "never below #1, even with the clock back")


func _test_seeds() -> void:
	var seen := {}
	var day: int = DailyScript.FIRST_DAY
	for d in range(day, day + 400):
		for mode in MODES:
			var s: int = DailyScript.seed_for(mode, d)
			_check(s > 0, "seed %s day %d is never 0 (0 would be a random track)" % [mode, d])
			_check(s == DailyScript.seed_for(mode, d), "seed %s day %d is stable" % [mode, d])
			seen[s] = true
	_check(seen.size() == 400 * MODES.size(), "every mode and day has a track of its own")
	_check(DailyScript.seed_for("zigzag", -3) > 0, "a clock before 1970 still gives a seed")


## Two phones with different screens, same day: the same platforms.
func _test_same_zigzag_on_every_phone() -> void:
	var s: int = DailyScript.seed_for("zigzag", DailyScript.FIRST_DAY)
	var short = TrackScript.new(720.0, 1280.0, s)
	var tall = TrackScript.new(720.0, 1560.0, s)
	var n := mini(short.segs.size(), tall.segs.size())
	_check(n >= 5, "platforms are ready ahead (%d)" % n)
	var same := true
	for i in n:
		var a = short.segs[i]
		var b = tall.segs[i]
		same = same and a.dir == b.dir and a.a.is_equal_approx(b.a)
		same = same and is_equal_approx(a.length, b.length) and is_equal_approx(a.w, b.w)
	_check(same, "the same platforms on a short and a tall screen")
	var next_day: int = DailyScript.FIRST_DAY + 1
	var tomorrow = TrackScript.new(720.0, 1280.0, DailyScript.seed_for("zigzag", next_day))
	var differ := false
	for i in mini(n, tomorrow.segs.size()):
		differ = differ or not is_equal_approx(short.segs[i].length, tomorrow.segs[i].length)
	_check(differ, "another day, another track")


func _test_same_tower_and_dino() -> void:
	var day: int = DailyScript.FIRST_DAY + 3
	var t1 = TowerScript.new(720.0, DailyScript.seed_for("tower", day))
	var t2 = TowerScript.new(720.0, DailyScript.seed_for("tower", day))
	var same: bool = t1.holes.size() == t2.holes.size() and t1.holes.size() > 3
	for i in mini(t1.holes.size(), t2.holes.size()):
		var a = t1.holes[i]
		var b = t2.holes[i]
		same = same and a.start == b.start and a.end == b.end and a.chained == b.chained
	_check(same, "TORRE: the same holes for everyone")

	var r1 = RunnerScript.new(720.0, DailyScript.seed_for("runner", day))
	var r2 = RunnerScript.new(720.0, DailyScript.seed_for("runner", day))
	same = r1.obstacles.size() == r2.obstacles.size() and r1.obstacles.size() > 1
	for i in mini(r1.obstacles.size(), r2.obstacles.size()):
		var a = r1.obstacles[i]
		var b = r2.obstacles[i]
		same = same and a.x == b.x and a.kind == b.kind and a.count == b.count
	_check(same, "DINO: the same obstacles for everyone")


func _test_best_of_the_day() -> void:
	var d = DailyScript.new()
	_check(d.visit(100), "the first visit starts a day")
	_check(not d.visit(100), "opening again the same day changes nothing")
	_check(d.best_of("zigzag") == 0, "no score yet")
	_check(not d.record("zigzag", 100, 0), "a zero is no record")
	_check(d.record("zigzag", 100, 12), "the first score is the best of the day")
	_check(not d.record("zigzag", 100, 9), "a lower one is not")
	_check(not d.record("zigzag", 100, 12), "nor the same one")
	_check(d.record("zigzag", 100, 15), "a higher one is")
	_check(d.best_of("zigzag") == 15 and d.best_of("tower") == 0, "each mode has its own")
	_check(not d.record("tower", 99, 50), "a run started yesterday counts for nothing")
	_check(d.best_of("tower") == 0, "and changes nothing")
	_check(d.visit(101), "a new day")
	_check(d.best_of("zigzag") == 0, "starts with no scores")


func _test_save_roundtrip() -> void:
	var d = DailyScript.new()
	d.visit(200)
	d.record("tower", 200, 31)
	d.record("runner", 200, 640)
	var cfg := ConfigFile.new()
	d.save_to(cfg)
	var back = DailyScript.new()
	back.load_from(cfg, MODES)
	_check(back.day == 200, "the day is saved")
	_check(back.best_of("tower") == 31 and back.best_of("runner") == 640, "the scores are saved")
	_check(back.best_of("zigzag") == 0, "a mode not played stays empty")
	_check(not back.visit(200), "back on the same day, the scores stay")

	cfg.set_value("daily", "best_zigzag", -7)
	back.load_from(cfg, MODES)
	_check(back.best_of("zigzag") == 0, "a negative score is ignored")
	var fresh = DailyScript.new()
	fresh.load_from(ConfigFile.new(), MODES)
	_check(fresh.day == -1 and fresh.best.is_empty(), "nothing saved yet")
