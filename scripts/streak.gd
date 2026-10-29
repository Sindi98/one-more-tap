class_name Streak
extends RefCounted
## Days in a row the game was opened. DINO opens on the third day, for good.
## Pure logic: the caller passes the day, so it is testable headless.

const DAYS_TO_UNLOCK := 3

var last_day := -1  ## the last day the game was opened (see day_number)
var days := 0  ## days in a row, up to last_day
var unlocked := false


## Calendar day as a number (days since 1970-01-01), from a date in the
## player's time zone such as Time.get_date_dict_from_system().
static func day_number(date: Dictionary) -> int:
	var midnight := {"year": date["year"], "month": date["month"], "day": date["day"]}
	@warning_ignore("integer_division")
	return int(Time.get_unix_time_from_datetime_dict(midnight)) / 86400


## The game was opened on `today`. Returns true when this visit unlocks DINO.
func visit(today: int) -> bool:
	if today <= last_day:
		return false  # same day, or the clock went back: nothing changes
	days = days + 1 if today == last_day + 1 else 1
	last_day = today
	if unlocked or days < DAYS_TO_UNLOCK:
		return false
	unlocked = true
	return true


## Days still to come back, 0 once DINO is open.
func days_left() -> int:
	return 0 if unlocked else DAYS_TO_UNLOCK - days


func save_to(cfg: ConfigFile) -> void:
	cfg.set_value("streak", "last_day", last_day)
	cfg.set_value("streak", "days", days)
	cfg.set_value("streak", "dino", unlocked)


func load_from(cfg: ConfigFile) -> void:
	last_day = int(cfg.get_value("streak", "last_day", -1))
	days = int(cfg.get_value("streak", "days", 0))
	unlocked = bool(cfg.get_value("streak", "dino", false))
