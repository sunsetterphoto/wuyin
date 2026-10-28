class_name Babble
extends Node
## Syllable blips for Lingshou speech (no voice acting, GDD "Stimmen"). Each
## element sings in its tone of the Wu Yin pentatonic scale; temperament shapes
## timbre and tempo. Feeding streamed text plays one blip per syllable, which
## also hides model latency.
##
##   babble.set_speaker(unit)
##   babble.feed("I-ich versuch's")   # call again with each new chunk

## Wu Yin: gong, shang, jue, zhi, yu as semitones above gong (C pentatonic).
const SCALE := {"gong": 0, "shang": 2, "jue": 4, "zhi": 7, "yu": 9}
const SCALE_ORDER: Array[String] = ["gong", "shang", "jue", "zhi", "yu"]
## Element -> tone, after the classical correspondence used for the regions.
const ELEMENT_TONE := {"earth": "gong", "metal": "shang", "wood": "jue", "fire": "zhi", "water": "yu"}
const BASE_HZ := 261.63  # C4 = gong
const MIX_RATE := 22050

## Temperament -> wave shape, blip length (s), volume (dB), syllable spacing (chars), pitch jitter (scale steps)
const STYLE := {
	"brave": {"wave": "square", "len": 0.055, "db": -8.0, "every": 2, "jump": 1},
	"anxious": {"wave": "sine", "len": 0.05, "db": -16.0, "every": 2, "jump": 1, "octave": 1},
	"stubborn": {"wave": "square", "len": 0.07, "db": -12.0, "every": 3, "jump": 0, "octave": -1},
	"playful": {"wave": "triangle", "len": 0.045, "db": -11.0, "every": 2, "jump": 3},
	"gentle": {"wave": "pluck", "len": 0.09, "db": -12.0, "every": 3, "jump": 1},
	"moody": {"wave": "triangle", "len": 0.06, "db": -12.0, "every": 2, "jump": 2},
}

var _players: Array[AudioStreamPlayer] = []
var _next_player := 0
var _cache := {}
var _style: Dictionary = STYLE["gentle"]
var _tone := "gong"
var _counter := 0


func _ready() -> void:
	for i in 4:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)


func set_speaker(unit: BattleUnit) -> void:
	_tone = ELEMENT_TONE.get(unit.element(), "gong")
	_style = STYLE.get(unit.species.get("temperaments", ["gentle"])[0], STYLE["gentle"])
	_counter = 0


## For people and Jinli: a tone of the scale plus a temperament-like style.
func set_voice(tone: String, style: String, octave := 0) -> void:
	_tone = tone
	_style = STYLE.get(style, STYLE["gentle"]).duplicate()
	_style["octave"] = int(_style.get("octave", 0)) + octave
	_counter = 0


## Plays blips for the characters in `chunk` (letters and Han characters only).
func feed(chunk: String) -> void:
	for i in chunk.length():
		var c := chunk.unicode_at(i)
		if not _is_syllable_char(c):
			continue
		_counter += 1
		if _counter % int(_style["every"]) != 0 and c < 0x4E00:
			continue
		_play(note_for(c))


## Scale step relative to the speaker's tone for a character (deterministic,
## so the same words always sound the same).
func note_for(codepoint: int) -> int:
	var jump := int(_style["jump"])
	return 0 if jump == 0 else (codepoint * 7919) % (jump * 2 + 1) - jump


static func frequency(tone: String, step := 0, octave := 0) -> float:
	var idx := SCALE_ORDER.find(tone) + step
	var oct := octave + floori(float(idx) / SCALE_ORDER.size())
	idx = posmod(idx, SCALE_ORDER.size())
	return BASE_HZ * pow(2.0, (SCALE[SCALE_ORDER[idx]] + 12 * oct) / 12.0)


func _play(step: int) -> void:
	if _players.is_empty():
		return
	var hz := frequency(_tone, step, int(_style.get("octave", 0)))
	var p := _players[_next_player]
	_next_player = (_next_player + 1) % _players.size()
	p.stream = blip(hz, _style["wave"], _style["len"])
	p.volume_db = _style["db"]
	p.play()


## Cached short tone with a click-free envelope.
func blip(hz: float, wave: String, length: float) -> AudioStreamWAV:
	var key := "%s:%.1f:%.3f" % [wave, hz, length]
	if _cache.has(key):
		return _cache[key]
	var n := int(MIX_RATE * length)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		var t := float(i) / MIX_RATE
		var phase := fmod(t * hz, 1.0)
		var v := 0.0
		match wave:
			"square":
				v = 0.6 if phase < 0.5 else -0.6
			"triangle":
				v = 4.0 * absf(phase - 0.5) - 1.0
			"pluck":
				# Guzheng-like: sine with a quick decay and a faint octave.
				v = (sin(TAU * phase) + 0.3 * sin(TAU * fmod(t * hz * 2.0, 1.0))) * exp(-t * 28.0)
			_:
				v = sin(TAU * phase)
		var env := minf(1.0, i / (MIX_RATE * 0.004)) * minf(1.0, (n - i) / (MIX_RATE * 0.012))
		data.encode_s16(i * 2, int(clampf(v * env, -1.0, 1.0) * 30000))
	var s := AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = MIX_RATE
	s.stereo = false
	s.data = data
	_cache[key] = s
	return s


static func _is_syllable_char(c: int) -> bool:
	return (c >= 0x41 and c <= 0x5A) or (c >= 0x61 and c <= 0x7A) or (c >= 0xC0 and c <= 0x24F) \
		or (c >= 0x4E00 and c <= 0x9FFF)
