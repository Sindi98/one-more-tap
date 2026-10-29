class_name RunRules
extends RefCounted
## What the rules of every game mode share, so the game flow can drive any of
## them: one tap, a score, a fall with a reason, one continue per run.
## Pure logic, no nodes: each mode (Track, Tower, Runner) is testable headless.

signal scored(score: int)
signal died(reason: String)

var unit := 1.0  ## screen pixels per design unit (design width: 390)
var score := 0
var started := false
var alive := true
var revived := false  ## a continue was used in this run (only one allowed)
var reason := ""  ## why the run ended, set when it does


func start() -> void:
	started = true


## The one control. Returns what happened, or {} when it had no effect.
func tap() -> Dictionary:
	return {}


## The finger was lifted. Only modes with a "hold" use it.
func release() -> void:
	pass


func update(_delta: float) -> void:
	pass


func can_revive() -> bool:
	return started and not alive and not revived


## Second chance after a rewarded video: back in a safe spot, slowed down for
## a moment, score unchanged. Once per run. Returns false if not allowed.
func revive() -> bool:
	return false
