class_name Music
extends Node
## Background music: one track, looped. Full volume during a run, softer on the
## start screen and the panels, paused during an ad and while the game is in
## the background. The track is from Pixabay (Pixabay Content License: free in
## games, no credit required); without the file the game simply has no music.

enum Mood { RUN, MENU, AD }

const TRACK := "res://assets/music/music.mp3"
const RUN_DB := -10.0  ## below the sound effects, which carry the feedback
const MENU_DB := -17.0
const FADE := 0.5  ## seconds to move between the two volumes

var muted := false:
	set(value):
		muted = value
		_apply()

var _player: AudioStreamPlayer  ## only when the track is there
var _mood := Mood.MENU
var _away := false  ## app in the background, browser tab hidden
var _fade: Tween


func _ready() -> void:
	if not ResourceLoader.exists(TRACK):
		return
	var stream := load(TRACK) as AudioStreamMP3
	stream.loop = true
	_player = AudioStreamPlayer.new()
	_player.stream = stream
	_player.volume_db = MENU_DB
	add_child(_player)


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_APPLICATION_PAUSED:
			_away = true
			_apply()
		NOTIFICATION_APPLICATION_FOCUS_IN, NOTIFICATION_APPLICATION_RESUMED:
			_away = false
			_apply()


func set_mood(mood: Mood) -> void:
	_mood = mood
	_apply()


## Paused, not stopped: the track goes on from where it was.
func _apply() -> void:
	if _player == null:
		return
	var on := not (muted or _away or _mood == Mood.AD)
	if on and not _player.has_stream_playback():
		_player.play()
	_player.stream_paused = not on
	if _fade:
		_fade.kill()
	_fade = create_tween()
	_fade.tween_property(_player, "volume_db", RUN_DB if _mood == Mood.RUN else MENU_DB, FADE)
