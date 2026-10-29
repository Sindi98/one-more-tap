class_name Music
extends Node
## Background music from Pixabay (Pixabay Content License: free in games, no
## credit required; titles and authors in README.md). Each mode plays a
## playlist, one track after the other. Full volume during a run, softer on
## the start screen and the panels, paused during an ad and while the game is
## in the background.

enum Mood { RUN, MENU, AD }

const FOLDER := "res://assets/music/"
## The bass tracks go with the neon modes, the 8-bit ones with DINO's pixel art.
const PLAYLISTS := {
	"neon":
	[
		"speed_racing_bass",
		"bass_heavy_deep_drop",
		"electronic_future_beats",
		"arcade_game",
		"spaceship_arcade_shooter",
	],
	"retro": ["retro_old_school", "retro_casual"],
}
const RUN_DB := -6.0  ## the files are levelled to -14 LUFS: under the sound effects
const MENU_DB := -12.0
const FADE := 0.5  ## seconds to move between the two volumes
const QUIT_DELAY := 0.1  ## seconds between stopping the music and quitting

var muted := false:
	set(value):
		muted = value
		_apply()

var _player := AudioStreamPlayer.new()
var _playlist := ""
var _next := {}  ## playlist -> index of its next track; each starts at a random one
var _mood := Mood.MENU
var _away := false  ## app in the background, browser tab hidden
var _fade: Tween


func _ready() -> void:
	_player.volume_db = MENU_DB
	# The web plays sounds as samples by default: fine for the short effects,
	# not for minutes of music.
	_player.playback_type = AudioServer.PLAYBACK_TYPE_STREAM
	_player.finished.connect(_play_next)
	add_child(_player)
	for list in PLAYLISTS:
		_next[list] = randi() % PLAYLISTS[list].size()
	get_tree().auto_accept_quit = false  # closing the window goes through _quit()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_APPLICATION_PAUSED:
			_away = true
			_apply()
		NOTIFICATION_APPLICATION_FOCUS_IN, NOTIFICATION_APPLICATION_RESUMED:
			_away = false
			_apply()
		NOTIFICATION_WM_CLOSE_REQUEST:
			_quit()


## A mode with the same playlist lets the track go on.
func set_playlist(list: String) -> void:
	if list == _playlist:
		return
	_playlist = list
	_play_next()


func set_mood(mood: Mood) -> void:
	_mood = mood
	_apply()


func _play_next() -> void:
	var tracks: Array = PLAYLISTS[_playlist]
	var i: int = _next[_playlist]
	_next[_playlist] = (i + 1) % tracks.size()
	_player.stream = load(FOLDER + tracks[i] + ".ogg")
	_apply()


## Paused, not stopped: the track goes on from where it was.
func _apply() -> void:
	if _player.stream == null:
		return
	var on := not (muted or _away or _mood == Mood.AD)
	if on and not _player.has_stream_playback():
		_player.play()
	_player.stream_paused = not on
	if _fade:
		_fade.kill()
	_fade = create_tween()
	_fade.tween_property(_player, "volume_db", RUN_DB if _mood == Mood.RUN else MENU_DB, FADE)


## The audio server frees a stopped track over the next frames, and leaves a
## playing one behind when the game quits (a leak warning in the terminal):
## stop first, quit a moment later.
func _quit() -> void:
	_player.stop()
	await get_tree().create_timer(QUIT_DELAY).timeout
	get_tree().quit()
