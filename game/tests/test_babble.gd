extends "res://tests/test_case.gd"
## Babble: element tones follow the Wu Yin correspondence; blips are audible and short.


func test_element_tones_match_the_regions() -> void:
	# GDD: wood/jue, water/yu, fire/zhi, metal/shang, earth/gong.
	assert_eq(Babble.ELEMENT_TONE["wood"], "jue")
	assert_eq(Babble.ELEMENT_TONE["water"], "yu")
	assert_eq(Babble.ELEMENT_TONE["fire"], "zhi")
	assert_eq(Babble.ELEMENT_TONE["metal"], "shang")
	assert_eq(Babble.ELEMENT_TONE["earth"], "gong")


func test_scale_is_pentatonic() -> void:
	assert_almost_eq(Babble.frequency("gong"), 261.63, 0.01)
	assert_almost_eq(Babble.frequency("zhi") / Babble.frequency("gong"), pow(2.0, 7.0 / 12.0), 0.0001, "fifth")
	assert_almost_eq(Babble.frequency("gong", 5), Babble.frequency("gong") * 2.0, 0.01, "five steps = one octave")
	assert_almost_eq(Babble.frequency("yu", 1), Babble.frequency("gong", 0, 1), 0.01, "wraps into next octave")


func test_blip_is_short_and_audible() -> void:
	var b := Babble.new()
	for wave in ["square", "triangle", "pluck", "sine"]:
		var s := b.blip(440.0, wave, 0.06)
		assert_eq(s.data.size(), int(Babble.MIX_RATE * 0.06) * 2, wave)
		var peak := 0
		for i in range(0, s.data.size(), 2):
			peak = maxi(peak, absi(s.data.decode_s16(i)))
		assert_true(peak > 5000, "%s audible (peak %d)" % [wave, peak])
	b.free()


func test_same_text_same_melody() -> void:
	var b := Babble.new()
	b.set_speaker(BattleUnit.create("nebelaffe", 5))
	var a: Array[int] = []
	var c: Array[int] = []
	for ch in "Kuckuck":
		a.append(b.note_for(ch.unicode_at(0)))
	for ch in "Kuckuck":
		c.append(b.note_for(ch.unicode_at(0)))
	assert_eq(a, c)
	b.free()
