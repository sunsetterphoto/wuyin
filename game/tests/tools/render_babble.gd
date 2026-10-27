extends SceneTree
## Renders each Lingshou babbling one template line into a WAV (for listening).
##   godot --headless --path game -s res://tests/tools/render_babble.gd -- <out.wav> [locale]


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var out: String = args[0]
	var locale: String = args[1] if args.size() > 1 else "de"
	var b := Babble.new()
	var pcm := PackedByteArray()
	var gap := PackedByteArray()
	gap.resize(int(Babble.MIX_RATE * 0.5) * 2)
	for id in ["wawalurch", "bambaer", "glutfasan", "rollschupp", "zirpo", "nebelaffe", "firnleopard", "silberkranich"]:
		var u := BattleUnit.create(id, 5)
		b.set_speaker(u)
		var line := LingshouVoice.template(u, "attack", locale) + " " + LingshouVoice.template(u, "win", locale)
		print("%s (%s, %s): %s" % [id, u.element(), u.species["temperaments"][0], line])
		var counter := 0
		for i in line.length():
			var c := line.unicode_at(i)
			if not Babble._is_syllable_char(c):
				if line[i] in [" ", ",", "."]:
					pcm.append_array(_silence(0.05))
				continue
			counter += 1
			if counter % int(b._style["every"]) != 0 and c < 0x4E00:
				continue
			var hz := Babble.frequency(b._tone, b.note_for(c), int(b._style.get("octave", 0)))
			var s := b.blip(hz, b._style["wave"], b._style["len"])
			var gain := db_to_linear(b._style["db"] + 8.0)
			for j in range(0, s.data.size(), 2):
				pcm.append_array(_s16(int(s.data.decode_s16(j) * gain)))
			pcm.append_array(_silence(0.03))
		pcm.append_array(gap)
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = Babble.MIX_RATE
	wav.data = pcm
	wav.save_to_wav(out)
	b.free()
	print("WROTE ", out)
	quit()


func _silence(seconds: float) -> PackedByteArray:
	var p := PackedByteArray()
	p.resize(int(Babble.MIX_RATE * seconds) * 2)
	return p


func _s16(v: int) -> PackedByteArray:
	var p := PackedByteArray()
	p.resize(2)
	p.encode_s16(0, clampi(v, -32768, 32767))
	return p
