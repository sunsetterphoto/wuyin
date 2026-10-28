extends "res://tests/test_case.gd"
## Beta chapter: every script compiles, maps and events are consistent, all
## texts exist in all three languages, and every map loads in the world.

const LOCALES: Array[String] = ["en", "de", "zh_Hans"]
## Step keys the event runner understands (first matching key wins).
const STEP_KEYS: Array[String] = ["say", "choice", "if", "if_item", "if_party_min", "if_coins", "if_not", "set", "clear",
	"quest", "goal", "give_item", "coins", "heal", "bells", "give_lingshou", "befriend", "battle", "warp", "music", "sfx",
	"wait", "fade", "move", "teleport", "place", "refresh", "save", "set_inn", "silence", "shop", "inn", "rumor",
	"hint", "voice", "run", "end_beta", "if_tones", "if_stat", "if_any", "if_count", "if_items", "clear_region", "tone",
	"persuade", "crane", "sleep", "restaurant", "farm", "time", "take_item", "ending", "credits", "count"]


func _scripts(dir: String, out: Array[String]) -> void:
	for f in DirAccess.get_files_at(dir):
		if f.ends_with(".gd"):
			out.append(dir.path_join(f))
	for d in DirAccess.get_directories_at(dir):
		_scripts(dir.path_join(d), out)


func test_every_script_compiles() -> void:
	var files: Array[String] = []
	_scripts("res://scripts", files)
	assert_true(files.size() > 30, "found scripts")
	for f in files:
		var s: GDScript = load(f)
		assert_true(s != null and s.can_instantiate(), "compiles: " + f)


func test_maps_are_valid() -> void:
	var ids := MapData.all_ids()
	assert_true(ids.size() >= 6, "six beta maps")
	for id in ids:
		var m := MapData.load_map(id)
		assert_true(m != null, "loads " + id)
		for e in m.validate():
			failures.append(e)


func _has_text(key: String) -> bool:
	for loc in LOCALES:
		if not Texts.has(key, loc):
			return false
	return true


func _check_steps(event_id: String, steps: Array) -> void:
	for s in steps:
		var known := false
		for k in STEP_KEYS:
			if s.has(k):
				known = true
				break
		if not known:
			failures.append("%s: unknown step %s" % [event_id, s])
			continue
		if s.has("say"):
			assert_true(_has_text(s["text"]), "%s: text %s in all languages" % [event_id, s["text"]])
			var sp: String = s["say"]
			assert_true(sp in ["narrator", "player", "jinli", "self"] or sp in GameData.lingshou_ids() \
				or not EventRunner.npc(sp).is_empty(), "%s: speaker %s known" % [event_id, sp])
		if s.has("choice"):
			for k in s["choice"]:
				var key: String = k["text"] if k is Dictionary else k
				assert_true(_has_text(key), "%s: choice %s" % [event_id, key])
			for b in s.get("then", []):
				_check_steps(event_id, b)
		for branch in ["then", "else", "win", "lose", "tamed", "freed", "fled", "success", "fail", "sings", "silent"]:
			if s.has(branch) and not s.has("choice"):
				_check_steps(event_id, s[branch])
		if s.has("quest"):
			assert_true(_has_text(s["quest"]), "%s: quest %s" % [event_id, s["quest"]])
			var name: String = s["quest"].trim_prefix("QUEST_")
			for i in 3:
				assert_true(_has_text("HINT_%s_%d" % [name, i]), "%s: hint %s %d" % [event_id, name, i])
		if s.has("give_item"):
			assert_false(GameData.item(s["give_item"]).is_empty(), "%s: item %s" % [event_id, s["give_item"]])
		if s.has("shop"):
			for it in s["shop"]:
				assert_false(GameData.item(it).is_empty(), "%s: shop item %s" % [event_id, it])
		for k in ["befriend", "give_lingshou", "voice"]:
			if s.has(k):
				assert_true(s[k] in GameData.lingshou_ids(), "%s: species %s" % [event_id, s[k]])
		if s.has("battle"):
			for e in s["battle"]["enemies"]:
				assert_true(e["id"] in GameData.lingshou_ids(), "%s: enemy %s" % [event_id, e["id"]])
		if s.has("warp"):
			assert_true(MapData.exists(s["warp"]), "%s: map %s" % [event_id, s["warp"]])
		if s.has("run"):
			assert_true(EventRunner.has_event(s["run"]), "%s: runs %s" % [event_id, s["run"]])
		if s.has("goal"):
			assert_true(MapData.exists(s["goal"][0]), "%s: goal map %s" % [event_id, s["goal"][0]])
			var gm := MapData.load_map(s["goal"][0])
			assert_true(gm.walkable(int(s["goal"][1]), int(s["goal"][2])) or gm.tile(int(s["goal"][1]), int(s["goal"][2])) in ["N", "D"],
				"%s: goal tile walkable %s" % [event_id, s["goal"]])
		if s.has("persuade"):
			assert_true(_has_text(s["persuade"]["intro"]), "%s: persuade intro" % event_id)
			assert_false(EventRunner.npc(s["persuade"]["who"]).is_empty(), "%s: persuade person" % event_id)
		if s.has("restaurant"):
			for it in s["restaurant"]:
				assert_eq(GameData.item(it).get("kind"), "dish", "%s: dish %s" % [event_id, it])
		if s.has("tone"):
			assert_true(s["tone"] in GameState.TONES, "%s: tone %s" % [event_id, s["tone"]])
		if s.has("voice"):
			assert_true(_has_text("VOICE_%s_%s" % [s["voice"].to_upper(), String(s.get("event", "freed")).to_upper()]),
				"%s: voice template" % event_id)


func test_events_are_consistent() -> void:
	var ids := EventRunner.event_ids()
	assert_true(ids.size() > 30, "chapter events loaded")
	for id in ids:
		_check_steps(id, EventRunner.steps_of(id))


func test_texts_used_in_code_exist() -> void:
	var files: Array[String] = []
	_scripts("res://scripts", files)
	var re := RegEx.create_from_string("tr\\(\"([A-Z][A-Z0-9_]+)\"\\)")
	var missing: Array[String] = []
	for f in files:
		for m in re.search_all(FileAccess.get_file_as_string(f)):
			var key := m.get_string(1)
			if not _has_text(key) and key not in missing:
				missing.append(key)
	assert_eq(missing, [] as Array[String], "translation keys missing")
	for id in GameData.item_ids():
		assert_true(_has_text(GameData.item(id)["name"]) and _has_text(GameData.item(id)["desc"]), "item texts " + id)
	for id in MapData.all_ids():
		assert_true(_has_text(MapData.load_map(id).name_key()), "map name " + id)
	for t in GameData.TEMPERAMENTS:
		assert_true(_has_text("TEMPERAMENT_" + t.to_upper()), "temperament " + t)
	for tone in Taming.TONES:
		assert_true(_has_text("TONE_" + tone.to_upper()), "tone " + tone)
	for area in Feedback.AREAS:
		assert_true(_has_text("FB_" + area.to_upper()), "feedback area " + area)


func test_tame_keywords_cover_the_tones() -> void:
	assert_eq(TameJudge.from_keywords("Keine Angst, ich tu dir nichts."), "soothing")
	assert_eq(TameJudge.from_keywords("Wanna play a game?"), "playful")
	assert_eq(TameJudge.from_keywords("You're beautiful but stupid"), "rude")
	assert_eq(TameJudge.from_keywords("别怕，没事的"), "soothing")
	assert_eq(TameJudge.from_keywords("Banane"), "neutral")
	for tone in ["SOOTHING", "ENCOURAGING", "PLAYFUL", "RESPECTFUL", "PRAISING"]:
		for i in 2:
			var text := Texts.get_text("TALK_%s_%d" % [tone, i], "de")
			assert_eq(TameJudge.from_keywords(text.format({"name": "Zirpo"})), tone.to_lower(), "suggestion %s_%d" % [tone, i])


func test_every_map_loads_in_the_world() -> void:
	# Arrival scenes play by themselves (their dialog would otherwise wait for a tap).
	DialogBox.autopilot = true
	GameState.current = GameState.new_game("Test")
	GameState.current.set_flag("intro_done")
	GameState.current.set_flag("river_arrived")
	GameState.current.set_flag("teeufer_arrived")
	GameState.current.set_flag("terraces_arrived")
	GameState.current.set_flag("shrine_arrived")
	GameState.current.add_lingshou("bambaer", 5)
	var tree := Engine.get_main_loop() as SceneTree
	var world: World = load("res://scenes/world/world.tscn").instantiate()
	tree.root.add_child(world)
	await tree.process_frame
	while world.busy:
		await tree.process_frame
	for id in MapData.all_ids():
		await world.enter_map(id, "", Vector2(-1, -1), false)
		assert_eq(world.map.id, id)
		assert_true(world.map.walkable(roundi(GameState.current.pos.x), roundi(GameState.current.pos.y)), "spawn walkable on " + id)
		while world.events.running:
			await tree.process_frame
	world.queue_free()
	await tree.process_frame
	DialogBox.autopilot = false
	GameState.delete_save(World.AUTOSAVE_SLOT)
