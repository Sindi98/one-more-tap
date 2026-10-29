class_name Lives
extends RefCounted
## How many runs the player can start: each run costs a life, up to MAX are
## kept. Lives come back one at a time on their own, or all at once after a
## rewarded video. Pure logic: the caller passes the clock (Unix seconds), so
## it is testable headless.

const MAX := 5
const REFILL_SECONDS := 15 * 60  ## one life comes back every 15 minutes

var count := MAX
var since := 0.0  ## when the life on its way started coming back (below MAX only)


func _init(p_count: int = MAX, p_since: float = 0.0) -> void:
	count = clampi(p_count, 0, MAX)
	since = p_since


## Gives back the lives earned by waiting.
func update(now: float) -> void:
	if count >= MAX:
		return
	if now < since:
		since = now  # the clock went back: start the wait again, never get stuck
	var back := floori((now - since) / REFILL_SECONDS)
	if back > 0:
		count = mini(MAX, count + back)
		since += back * REFILL_SECONDS


## Spends a life to start a run. Returns false if there are none left.
func use(now: float) -> bool:
	update(now)
	if count <= 0:
		return false
	if count == MAX:
		since = now  # the first life spent starts the wait for its return
	count -= 1
	return true


## All lives back, after a rewarded video.
func refill() -> void:
	count = MAX


## Seconds until the next life comes back (0 when full).
func seconds_to_next(now: float) -> int:
	update(now)
	if count >= MAX:
		return 0
	return maxi(1, ceili(since + REFILL_SECONDS - now))
