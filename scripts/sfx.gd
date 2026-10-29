class_name Sfx
extends Node
## Procedural sound effects, synthesised once at startup: no audio files needed.
## Perfect turns climb a pentatonic scale, so a combo literally sounds better.

const MIX_RATE := 22050
const PENTATONIC := [0, 2, 4, 7, 9, 12, 14, 16, 19, 21, 24, 26, 28]
const C5 := 523.25

var muted := false

var _players: Array[AudioStreamPlayer] = []
var _next := 0
var _tick: AudioStreamWAV
var _die: AudioStreamWAV
var _record: AudioStreamWAV
var _jump: AudioStreamWAV
var _milestone: AudioStreamWAV
var _sparkle: AudioStreamWAV
var _buy: AudioStreamWAV
var _hit: AudioStreamWAV
var _goal: AudioStreamWAV
var _perfect: Array[AudioStreamWAV] = []


func _ready() -> void:
	for _i in 6:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	_tick = _make([[330.0, 0.045]], "square", 0.16)
	_die = _make([[220.0, 0.4]], "saw", 0.28, 0.25)
	_record = _make(
		[[C5, 0.08], [C5 * 1.26, 0.08], [C5 * 1.5, 0.08], [C5 * 2.0, 0.22]], "triangle", 0.32
	)
	_jump = _make([[392.0, 0.07]], "square", 0.13, 1.7)
	_milestone = _make([[C5 * 1.5, 0.07], [C5 * 2.0, 0.13]], "square", 0.14)
	_sparkle = _make([[C5 * 4.0, 0.04], [C5 * 3.0, 0.04], [C5 * 4.0, 0.09]], "triangle", 0.16)
	_buy = _make([[C5 * 2.0, 0.06], [C5 * 3.0, 0.16]], "triangle", 0.26)
	_hit = _make([[620.0, 0.03]], "square", 0.15, 0.7)
	_goal = _make([[C5, 0.07], [C5 * 1.5, 0.07], [C5 * 2.0, 0.2]], "square", 0.18)
	for n in PENTATONIC:
		_perfect.append(_make([[C5 * pow(2.0, n / 12.0), 0.13]], "triangle", 0.34))


func tick() -> void:
	_play(_tick)


func perfect(combo: int) -> void:
	_play(_perfect[clampi(combo - 1, 0, _perfect.size() - 1)])


func jump() -> void:
	_play(_jump)


## Every 100 points in DINO.
func milestone() -> void:
	_play(_milestone)


## On top of a PERFETTO, with a legendary ball.
func sparkle() -> void:
	_play(_sparkle)


## Something new in the shop: bought, put on, unlocked.
func buy() -> void:
	_play(_buy)


## AIR HOCKEY: a mallet strikes the puck.
func hit() -> void:
	_play(_hit)


## AIR HOCKEY: your team scored.
func goal() -> void:
	_play(_goal)


func die() -> void:
	_play(_die)


func record() -> void:
	_play(_record)


func _play(stream: AudioStreamWAV) -> void:
	if muted or stream == null:
		return
	var p := _players[_next]
	_next = (_next + 1) % _players.size()
	p.stream = stream
	p.play()


## notes: [[frequency, seconds], ...] played back to back.
## slide: pitch multiplier reached at the end of each note (1.0 = flat).
func _make(notes: Array, wave: String, volume: float, slide := 1.0) -> AudioStreamWAV:
	var total := 0
	for note in notes:
		total += int(note[1] * MIX_RATE)
	var data := PackedByteArray()
	data.resize(total * 2)
	var offset := 0
	var attack := 0.004 * MIX_RATE
	for note in notes:
		var freq: float = note[0]
		var n := int(note[1] * MIX_RATE)
		var phase := 0.0
		for i in n:
			var t := float(i) / n
			phase = fmod(phase + freq * pow(slide, t) / MIX_RATE, 1.0)
			var s: float
			match wave:
				"square":
					s = 1.0 if phase < 0.5 else -1.0
				"saw":
					s = phase * 2.0 - 1.0
				_:
					s = 1.0 - 4.0 * absf(phase - 0.5)
			var env := minf(1.0, i / attack) * pow(1.0 - t, 2.0)
			data.encode_s16((offset + i) * 2, int(clampf(s * env * volume, -1.0, 1.0) * 32767.0))
		offset += n
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = MIX_RATE
	wav.stereo = false
	wav.data = data
	return wav
