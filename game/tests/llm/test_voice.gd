extends "res://tests/test_case.gd"
## M0.5: voices stay within limits; templates step in on empty or bad output.

const FakeBackend := preload("res://tests/llm/fake_backend.gd")


func _service(tokens: Array[String]) -> LlmService:
	var s := LlmService.new()
	s.backends.clear()
	var fake := FakeBackend.new()
	fake.tokens = tokens
	s.backends.append(fake)
	return s


func test_every_lingshou_has_cards_in_all_languages() -> void:
	for id in GameData.lingshou_ids():
		var u := BattleUnit.create(id, 5)
		for loc in ["en", "de", "zh_Hans"]:
			var path := "res://data/" + String(u.species["voice_card"]).replace("{lang}", loc)
			assert_true(FileAccess.file_exists(path), path)
			var lines := FileAccess.get_file_as_string(path).strip_edges().split("\n")
			assert_true(lines.size() >= 5 and lines.size() <= 10, "%s: 5-10 lines, got %d" % [path, lines.size()])


func test_templates_cover_every_temperament_event_and_language() -> void:
	for loc in ["en", "de", "zh_Hans"]:
		for temp in GameData.TEMPERAMENTS:
			var u := BattleUnit.create("bambaer", 5)
			u.species = u.species.duplicate(true)
			u.species["temperaments"] = [temp]
			for ev in LingshouVoice.EVENTS:
				var t := LingshouVoice.template(u, ev, loc)
				assert_ne(t, "", "%s/%s/%s" % [loc, temp, ev])
				assert_true(t.length() <= LingshouVoice.MAX_CHARS["lingshou_voice"], t)


func test_model_text_is_used_when_valid() -> void:
	var u := BattleUnit.create("glutfasan", 5)
	var r := await LingshouVoice.comment(u, "attack", {"target": "Rollschupp"}, "de",
		_service(["Aus dem Weg", ", ich ", "komme!"] as Array[String]))
	assert_eq(r["source"], "model")
	assert_eq(r["text"], "Aus dem Weg, ich komme!")


func test_too_long_output_is_cut_to_limit() -> void:
	var u := BattleUnit.create("glutfasan", 5)
	var long := "Ha! " + "Ich bin der schnellste Vogel im ganzen Regenbogengrat und niemand hält mich auf. ".repeat(4)
	var r := await LingshouVoice.comment(u, "attack", {"target": "x"}, "de", _service([long] as Array[String]))
	assert_true(r["text"].length() <= LingshouVoice.MAX_CHARS["lingshou_voice"], "%d chars" % r["text"].length())
	assert_eq(r["source"], "model")


func test_empty_output_uses_template() -> void:
	var u := BattleUnit.create("wawalurch", 5)
	var r := await LingshouVoice.comment(u, "hit", {"target": "x"}, "de", _service(["  "] as Array[String]))
	assert_eq(r["source"], "template")
	assert_eq(r["text"], LingshouVoice.template(u, "hit", "de"))


func test_wrong_language_uses_template() -> void:
	var u := BattleUnit.create("wawalurch", 5)
	var r := await LingshouVoice.comment(u, "hit", {}, "zh_Hans", _service(["Ouch, that hurt."] as Array[String]))
	assert_eq(r["source"], "template", "English text in Chinese game")
	var r2 := await LingshouVoice.comment(u, "hit", {}, "de", _service(["好痛"] as Array[String]))
	assert_eq(r2["source"], "template", "Chinese text in German game")


func test_blocked_words_and_meta_talk_use_template() -> void:
	var u := BattleUnit.create("rollschupp", 5)
	for bad in ["Als Sprachmodell kann ich das nicht.", "Scheiße, das tat weh."]:
		var r := await LingshouVoice.comment(u, "hit", {}, "de", _service([bad] as Array[String]))
		assert_eq(r["source"], "template", bad)


func test_silenced_speaks_in_short_fragments() -> void:
	var u := BattleUnit.create("zirpo", 5)
	u.statuses["silenced"] = {"turns": 2, "applied_turn": 0}
	var r := await LingshouVoice.comment(u, "hit", {}, "en",
		_service(["...the song... where did the song go... I cannot find it anywhere in this grey quiet..."] as Array[String]))
	assert_true(r["text"].length() <= LingshouVoice.MAX_CHARS["silenced_voice"], r["text"])
	var t := LingshouVoice.template(u, "hit", "de", true)
	assert_true(t.begins_with("…"), "fragment template: " + t)


func test_guard_cleans_quotes_and_newlines() -> void:
	assert_eq(TextGuard.clean("„Ganz ruhig,\nich hab dich.“", "de", 140), "Ganz ruhig, ich hab dich.")
	assert_eq(TextGuard.limit("Eins zwei drei vier fünf sechs", 12), "Eins zwei…")


func test_live_voice_in_three_languages() -> void:
	var service := LlmService.instance()
	if not service.is_model_available():
		skip("no llama-server running")
		return
	var u := BattleUnit.create("wawalurch", 5)
	for loc in ["de", "en", "zh_Hans"]:
		var r := await LingshouVoice.comment(u, "hit", {"target": "Glutfasan"}, loc, service)
		print("    %s [%s, %d ms]: %s" % [loc, r["source"], r["ms"], r["text"]])
		assert_true(r["text"].length() <= LingshouVoice.MAX_CHARS["lingshou_voice"])
		assert_ne(r["text"], "")
	u.statuses["silenced"] = {"turns": 2, "applied_turn": 0}
	var s := await LingshouVoice.comment(u, "hit", {}, "de", service)
	print("    silenced [%s]: %s" % [s["source"], s["text"]])
	assert_true(s["text"].length() <= LingshouVoice.MAX_CHARS["silenced_voice"])


func test_wrong_latin_language_uses_template() -> void:
	assert_false(TextGuard.language_matches("I am sorry that it was scary. Was I good?", "de"))
	assert_true(TextGuard.language_matches("Ich versuche es. Bleib bitte in der Nähe.", "de"))
	assert_true(TextGuard.language_matches("I-I'm sorry. That was loud.", "en"))
	assert_false(TextGuard.language_matches("Das war gruselig, bitte bleib bei mir.", "en"))
	assert_true(TextGuard.language_matches("Hmpf.", "de"), "too short to judge")
	var u := BattleUnit.create("wawalurch", 5)
	var r := await LingshouVoice.comment(u, "hit", {}, "de", _service(["I am sorry that it was scary. Was I good?"] as Array[String]))
	assert_eq(r["source"], "template")
