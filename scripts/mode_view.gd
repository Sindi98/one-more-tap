class_name ModeView
extends Node2D
## What the drawing of every game mode shares: theme colour, visible area, the
## effects layer and where the camera should look. Each mode (WorldView,
## TowerView, RunnerView) reads its rules and never changes them.

const HOT := Color(1.0, 0.3, 0.42)

var hue := 188.0
var view_rect := Rect2()  ## visible world area, set by Main every frame
var fx: Fx  ## sparks and labels, set by Main


func reset(_rules: RunRules) -> void:
	pass


func tick(_delta: float) -> void:
	pass


## Camera centre for a screen of size `view`. After a fall it frames the spot
## where the run was lost.
func camera_target(_view: Vector2, _after_fall: bool) -> Vector2:
	return Vector2.ZERO


## Where the player is, in world space: feedback (sparks, labels) goes there.
func ball_position() -> Vector2:
	return Vector2.ZERO


func start_fall() -> void:
	pass


## Continue after the video: the player is back, alive.
func revive() -> void:
	pass
