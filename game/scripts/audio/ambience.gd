class_name Ambience
extends Node
## Sounds of the land under the music: wind, birdsong, running water, crickets
## at night, the murmur of a town. Synthesized once into short seamless loops
## (no files). Silent regions get none of it - the world only starts to sound
## again when its tone is back (GDD "Verstummte Gebiete klingen gedämpft").

const RATE := 22050
const LOOP_S := 6.0
const LAYERS: Array[String] = ["wind", "birds", "water", "crickets", "town"]

static var _streams := {}
var _players := {}


func _ready() -> void:
	for l in LAYERS:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		p.stream = _stream(l)
		p.volume_db = -60.0
		add_child(p)
		p.play()
		_players[l] = p


## Target loudness (dB, -60 = off) per layer for a place and time.
static func mix(region: String, town: bool, indoor: bool, night: bool, silent: bool, near_water: bool, weather: String) -> Dictionary:
	var m := {"wind": -60.0, "birds": -60.0, "water": -60.0, "crickets": -60.0, "town": -60.0}
	if silent:
		return m
	if indoor:
		m["town"] = -30.0 if town else -60.0
		return m
	m["wind"] = -24.0 if region in ["pillars", "dunes", "temple"] else -32.0
	if weather in ["storm", "sandstorm"]:
		m["wind"] = -16.0
	if night:
		m["crickets"] = -22.0 if region not in ["pillars", "temple"] else -32.0
	elif region in ["bamboo", "hub", "river", "ridge", "pillars"] and weather not in ["rain", "storm"]:
		m["birds"] = -20.0
	if near_water or region == "river":
		m["water"] = -22.0
	if weather in ["rain", "storm"]:
		m["water"] = -16.0
	if town and not night:
		m["town"] = -26.0
	return m


func apply(target: Dictionary) -> void:
	for l in _players:
		var p: AudioStreamPlayer = _players[l]
		create_tween().tween_property(p, "volume_db", float(target.get(l, -60.0)), 1.5)


static func _stream(layer: String) -> AudioStreamWAV:
	if _streams.has(layer):
		return _streams[layer]
	var n := int(RATE * LOOP_S)
	var data := PackedByteArray()
	data.resize(n * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(layer)
	var buf := PackedFloat32Array()
	buf.resize(n)
	match layer:
		"wind":
			# Brown noise, slowly swelling.
			var v := 0.0
			for i in n:
				v = clampf(v + rng.randf_range(-1, 1) * 0.02, -1, 1) * 0.998
				buf[i] = v * (0.6 + 0.4 * sin(TAU * i / n))
		"water":
			# Bubbly stream: filtered noise plus little droplets.
			var lp := 0.0
			for i in n:
				lp += (rng.randf_range(-1, 1) - lp) * 0.25
				buf[i] = lp * 0.5
			for k in 60:
				var at := rng.randi_range(0, n - 2000)
				var hz := rng.randf_range(500, 1400)
				for j in 1500:
					buf[at + j] += sin(TAU * (hz + j * 0.6) * j / RATE) * exp(-j / 220.0) * 0.18
		"birds":
			# A few pentatonic chirps and trills.
			for k in 14:
				var at := rng.randi_range(0, n - 9000)
				var base: float = [1568.0, 1760.0, 2093.0, 2349.0, 2637.0][rng.randi_range(0, 4)]
				var notes := rng.randi_range(2, 5)
				for nn in notes:
					var len := rng.randi_range(900, 1800)
					var start := at + nn * (len + 300)
					var hz: float = base * (1.0 + rng.randf_range(-0.05, 0.12) * nn)
					for j in len:
						if start + j >= n:
							break
						var env := sin(PI * j / len)
						buf[start + j] += sin(TAU * hz * j / RATE + sin(j * 0.02) * 2.0) * env * 0.16
		"crickets":
			for i in n:
				var pulse := 1.0 if fmod(i / float(RATE) * 9.0, 1.0) < 0.35 else 0.0
				var group := 1.0 if fmod(i / float(RATE) * 0.7, 1.0) < 0.55 else 0.0
				buf[i] = sin(TAU * 4200.0 * i / RATE) * pulse * group * 0.1
		"town":
			# Distant murmur: band-limited noise with soft "voices".
			var lp := 0.0
			for i in n:
				lp += (rng.randf_range(-1, 1) - lp) * 0.06
				buf[i] = lp * 0.6 * (0.7 + 0.3 * sin(TAU * i / RATE * 0.8))
	# Seamless: fade the last half second into the start.
	var fade := int(RATE * 0.5)
	for i in fade:
		var t := float(i) / fade
		buf[i] = buf[i] * t + buf[n - fade + i] * (1.0 - t)
	for i in n:
		data.encode_s16(i * 2, int(clampf(buf[i], -1.0, 1.0) * 24000))
	var s := AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = RATE
	s.data = data.slice(0, (n - fade) * 2)
	s.loop_mode = AudioStreamWAV.LOOP_FORWARD
	s.loop_end = n - fade
	_streams[layer] = s
	return s
