extends "res://tests/test_case.gd"


func test_all_data_valid() -> void:
	GameData.reload()
	var errors := GameData.validate()
	assert_true(errors.is_empty(), "\n      ".join(errors))


func test_vertical_slice_examples_present() -> void:
	for id in ["wawalurch", "bambaer", "glutfasan", "rollschupp", "zirpo", "nebelaffe", "firnleopard", "silberkranich"]:
		assert_true(id in GameData.lingshou_ids(), id)


func test_every_element_has_a_lingshou() -> void:
	var seen := {}
	for id in GameData.lingshou_ids():
		seen[GameData.lingshou(id)["element"]] = true
	for e in WuXing.ELEMENTS:
		assert_true(seen.has(e), e)


func test_all_texts_translated() -> void:
	var keys: Array[String] = []
	for id in GameData.lingshou_ids():
		keys.append(GameData.lingshou(id)["name"])
	for id in GameData.move_ids():
		keys.append(GameData.move(id)["name"])
	for locale in ["en", "de", "zh_Hans"]:
		TranslationServer.set_locale(locale)
		for k in keys:
			assert_ne(TranslationServer.translate(k), StringName(k), "%s missing in %s" % [k, locale])
	TranslationServer.set_locale("en")


func test_no_forbidden_vocabulary() -> void:
	# Rule 5: no Pokemon vocabulary in data or texts.
	var forbidden := ["pokeball", "pokéball", "pokedex", "pokédex", "trainer", "arenaleiter", "gym leader"]
	var files: Array[String] = []
	for dir in ["res://data/lingshou", "res://data/moves", "res://data/i18n"]:
		for f in DirAccess.get_files_at(dir):
			if f.ends_with(".json") or f.ends_with(".csv"):
				files.append(dir.path_join(f))
	for path in files:
		var text := FileAccess.get_file_as_string(path).to_lower()
		for word in forbidden:
			assert_false(word in text, "%s contains '%s'" % [path, word])
		for line in text.split("\n"):
			for token in line.split(","):
				assert_false(token.strip_edges().ends_with("mon"), "%s: name ending in -mon: %s" % [path, token])
