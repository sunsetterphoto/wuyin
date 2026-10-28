extends Node
## Autoload "Music": background music with crossfade and short synthesized
## sound effects (pentatonic, so they fit the score). Missing music files are
## skipped silently, the game stays playable without them.

const MUSIC_DIR := "res://assets/audio/music/"
const FADE_S := 0.8
const SFX_RATE := 22050

var current := ""
var _a: AudioStreamPlayer
var _b: AudioStreamPlayer
var _sfx: Array[AudioStreamPlayer] = []
var _next_sfx := 0
var _cache := {}
var _tween: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for bus in ["Music", "SFX"]:
		if AudioServer.get_bus_index(bus) < 0:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, bus)
	var bus := AudioServer.get_bus_index("Music")
	if AudioServer.get_bus_effect_count(bus) == 0:
		var lp := AudioEffectLowPassFilter.new()
		lp.cutoff_hz = 650.0
		AudioServer.add_bus_effect(bus, lp)
		AudioServer.set_bus_effect_enabled(bus, 0, false)
	_a = _player("Music")
	_b = _player("Music")
	for i in 4:
		_sfx.append(_player("SFX"))
	Settings.apply()


func _player(bus: String) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.bus = bus
	add_child(p)
	return p


## Crossfades to track `id` (file name without extension); "" fades to silence.
func play(id: String) -> void:
	if id == current:
		return
	current = id
	var stream: AudioStream = null
	var path := MUSIC_DIR + id + ".ogg"
	if id != "" and ResourceLoader.exists(path):
		stream = load(path)
		if stream is AudioStreamOggVorbis:
			stream.loop = id not in ["victory", "tone_returns"]
	if _tween:
		_tween.kill()
	var old := _a
	_a = _b
	_b = old
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(_b, "volume_db", -40.0, FADE_S)
	_tween.chain().tween_callback(_b.stop)
	if stream:
		_a.stream = stream
		_a.volume_db = -40.0
		_a.play()
		_tween.tween_property(_a, "volume_db", 0.0, FADE_S)


func stop() -> void:
	play("")


## Silent regions: the music sounds muffled and far away (GDD "Musik").
func set_muffled(on: bool) -> void:
	var bus := AudioServer.get_bus_index("Music")
	if AudioServer.get_bus_effect_count(bus) > 0:
		AudioServer.set_bus_effect_enabled(bus, 0, on)


## Short effects: select, back, hit, heal, bell, meow, encounter, level, trust, heart, fail, coin.
func sfx(name: String) -> void:
	var p := _sfx[_next_sfx]
	_next_sfx = (_next_sfx + 1) % _sfx.size()
	p.stream = _sound(name)
	p.play()


func _sound(name: String) -> AudioStreamWAV:
	if _cache.has(name):
		return _cache[name]
	# Each effect: list of [hz, length s, wave, glide factor]
	var notes: Array = {
		"select": [[784.0, 0.05, "square", 1.0]],
		"back": [[523.0, 0.05, "square", 0.8]],
		"hit": [[180.0, 0.09, "noise", 0.5]],
		"heal": [[523.0, 0.07, "pluck", 1.0], [659.0, 0.07, "pluck", 1.0], [784.0, 0.12, "pluck", 1.0]],
		"bell": [[1046.0, 0.5, "bell", 1.0]],
		"meow": [[620.0, 0.28, "meow", 1.6]],
		"encounter": [[392.0, 0.06, "square", 1.0], [523.0, 0.06, "square", 1.0], [784.0, 0.12, "square", 1.0]],
		"level": [[523.0, 0.08, "square", 1.0], [659.0, 0.08, "square", 1.0], [784.0, 0.08, "square", 1.0], [1046.0, 0.2, "square", 1.0]],
		"trust": [[659.0, 0.08, "pluck", 1.0], [880.0, 0.14, "pluck", 1.0]],
		"heart": [[440.0, 0.1, "bell", 1.0], [523.0, 0.18, "bell", 1.0]],
		"fail": [[330.0, 0.1, "triangle", 0.8], [262.0, 0.18, "triangle", 0.8]],
		"coin": [[1318.0, 0.05, "square", 1.0], [1760.0, 0.1, "square", 1.0]],
		"step": [[120.0, 0.03, "noise", 1.0]],
	}.get(name, [[440.0, 0.05, "square", 1.0]])
	var data := PackedByteArray()
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(name)
	for note in notes:
		var hz: float = note[0]
		var n := int(SFX_RATE * float(note[1]))
		var start := data.size()
		data.resize(start + n * 2)
		var phase := 0.0
		for i in n:
			var t := float(i) / SFX_RATE
			var k := float(i) / n
			# Glide: meow rises then falls; others glide linearly to factor.
			var f: float = hz * (1.0 + (note[3] - 1.0) * (sin(k * PI) if note[2] == "meow" else k))
			phase = fmod(phase + f / SFX_RATE, 1.0)
			var v := 0.0
			match note[2]:
				"square":
					v = 0.4 if phase < 0.5 else -0.4
				"triangle":
					v = 4.0 * absf(phase - 0.5) - 1.0
				"noise":
					v = rng.randf_range(-0.8, 0.8) * (1.0 - k)
				"pluck":
					v = sin(TAU * phase) * exp(-t * 18.0)
				"bell":
					v = (sin(TAU * phase) + 0.4 * sin(TAU * fmod(phase * 2.76, 1.0))) * 0.6 * exp(-t * 6.0)
				"meow":
					v = (sin(TAU * phase) + 0.5 * sin(TAU * fmod(phase * 2.0, 1.0)) + 0.25 * sin(TAU * fmod(phase * 3.0, 1.0))) * 0.45
				_:
					v = sin(TAU * phase)
			var env := minf(1.0, i / (SFX_RATE * 0.004)) * minf(1.0, (n - i) / (SFX_RATE * 0.02))
			data.encode_s16((start / 2 + i) * 2, int(clampf(v * env, -1.0, 1.0) * 26000))
	var s := AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = SFX_RATE
	s.data = data
	_cache[name] = s
	return s
