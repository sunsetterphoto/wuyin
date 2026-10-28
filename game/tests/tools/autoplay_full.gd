extends SceneTree
## Plays the whole game without a human, from the Lantern Festival to the
## phoenix's rebirth: interacts with people, steps on triggers and warps in
## story order, grinds a little where a player would, lets the autopilot
## fight, befriend, free and persuade. Fails (exit 1) when a story flag is
## missing afterwards.
##
##   godot --headless --path game -s res://tests/tools/autoplay_full.gd
##   ... -- --ending=victory   (bad answers to Wusheng)
##   ... -- --ending=bitter    (never talks to silenced Lingshou)
##   ... -- --transcript       (prints every line of dialog)

var world
var ok := true
var grind_battles := 0
var section_start := 0.0
var report := []


func _initialize() -> void:
	create_timer(3000.0, true, false, true).timeout.connect(func(): printerr("AUTOPLAY timeout"); quit(2))
	_run.call_deferred()


func _idle() -> void:
	var calm := 0
	while calm < 3:
		await process_frame
		calm = calm + 1 if not world.busy and not world.events.running else 0


func _step(x: int, z: int) -> void:
	world.teleport_player(Vector2(x, z))
	world._on_new_tile(Vector2i(x, z))
	await _idle()


func _event(id: String, actor := "") -> void:
	world.events.run(id, actor)
	await _idle()


func _go(map_id: String, spawn := "inn") -> void:
	await world.enter_map(map_id, spawn)
	await _idle()


func _expect(flag: String) -> void:
	if not GameState.current.flag(flag):
		ok = false
		printerr("AUTOPLAY missing flag: ", flag, " (map ", world.map.id, ")")
	else:
		print("  ✓ ", flag)


func _expect_map(id: String) -> void:
	if world.map.id != id:
		ok = false
		printerr("AUTOPLAY expected map ", id, ", got ", world.map.id)


func _arg(name: String, default: String) -> String:
	for a in OS.get_cmdline_user_args():
		if a.begins_with(name + "="):
			return a.split("=")[1]
	return default


func _avg_level() -> float:
	var avg := 0.0
	for r in GameState.current.party:
		avg += r["level"]
	return avg / maxf(1, GameState.current.party.size())


func _levels() -> String:
	return ", ".join(GameState.current.party.map(func(r): return "%s %d" % [r["species"], r["level"]]))


## Fights random encounters of the current map until the party's average level is reached.
func _grind(until_level: float, max_battles := 60) -> void:
	var map_id: String = world.map.id
	var table: Array = world.map.def["encounters"]["table"].filter(func(e): return not e.get("night", false))
	var rng := RandomNumberGenerator.new()
	rng.seed = 7 + grind_battles
	var n := 0
	while n < max_battles and _avg_level() < until_level:
		var e: Dictionary = table[rng.randi_range(0, table.size() - 1)]
		# Like a player: fill a free bell by befriending, otherwise fight.
		BattleView.autopilot_fight = GameState.current.party.size() >= GameState.current.bells
		world.start_wild_battle(e["species"], rng.randi_range(int(e["levels"][0]), int(e["levels"][1])), null)
		await _idle()
		n += 1
		grind_battles += 1
		if world.map.id != map_id:
			await world.enter_map(map_id, "", Vector2(-1, -1), false)
		GameState.current.heal_party()
	BattleView.autopilot_fight = false


## Runs a boss event, retrying after a defeat like a player would (heal, try again).
func _boss(event_id: String, flag: String, back_map: String, back_spawn: String, tries := 4) -> void:
	for i in tries:
		await _event(event_id)
		if GameState.current.flag(flag):
			return
		print("  lost against ", event_id, " (try ", i + 1, "), party: ", _levels())
		await _go(back_map, back_spawn)
		if world.map.def.has("encounters"):
			await _grind(_avg_level() + 1.0, 8)
		GameState.current.heal_party()


func _section(name: String) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	if section_start > 0.0:
		report[-1]["s"] = roundi(now - section_start)
	section_start = now
	report.append({"name": name, "battles": int(GameState.current.stats["battles"]), "level": snappedf(_avg_level(), 0.1)})
	print("== ", name, "   party: ", _levels(), "   bells ", GameState.current.bells)


func _run() -> void:
	var ending := _arg("--ending", "reconcile")
	DialogBox.autopilot = true
	DialogBox.autopilot_last_choice = ending != "reconcile"
	BattleView.autopilot = true
	BattleView.autopilot_no_free = ending == "bitter"
	BefriendView.autopilot = true
	PersuadeView.autopilot = true
	PlaytestLog.path = "user://autoplay_playtest.jsonl"
	GameState.delete_save(0)
	GameState.current = GameState.new_game("Auto")
	GameState.current.seed = 42
	world = load("res://scenes/world/world.tscn").instantiate()
	root.add_child(world)
	await _idle()
	var st: GameState = GameState.current

	_section("prologue")
	_expect("intro_done")
	await _event("meister_gift", "meister")
	await _step(15, 10)
	_expect("silence_fell")
	await _step(31, 14)
	_expect_map("flussufer")
	await _event("prolog_wawalurch")
	_expect("yao_battle1")
	await _event("prolog_nebelaffe")
	_expect("prologue_tamed")
	await _step(0, 7)
	await _step(27, 14)
	_expect("prologue_done")

	_section("bamboo sea")
	await _step(28, 0)
	_expect_map("bambuspfad")
	await _event("chest_bamboo")
	await _grind(float(_arg("bamboo_level", "6")), 30)
	await _step(29, 5)
	_expect("yao_battle2")
	await _step(35, 5)
	_expect_map("teeufer")
	await _event("stille_frau", "stille_frau")
	await _step(26, 0)
	await _grind(float(_arg("terrace_level", "9")), 60)
	await _event("moth_a")
	await _event("silent_leopard")
	await _step(14, 0)
	_expect_map("drachenschrein")
	await _event("moench")
	await _boss("boss_qinglong", "tone_jue", "drachenschrein", "from_terraces")
	_expect("tone_jue")
	_expect("lesson_bamboo")

	_section("farm")
	await _go("weidendorf", "home")
	await _step(0, 10)
	_expect_map("hof")
	_expect("hof_arrived")
	# Give the farm a pair and let a few nights pass (breeding is part of the game).
	st.give_item("bambus", 4)
	st.coins += 300
	if Farm.upgrade(st):
		print("  farm upgraded to stage ", Farm.stage(st))
	var a := st.add_lingshou("bambaer", 8)
	var b := st.add_lingshou("bambaer", 8)
	for rec in [a, b]:
		if st.party.has(rec):
			st.move_to_farm(st.party.find(rec))
	a["sex"] = "f"
	b["sex"] = "m"
	Farm.assign(st, st.farm.find(a), 1)
	Farm.assign(st, st.farm.find(b), 1)
	a["happy"] = 90
	b["happy"] = 90
	for night in 5:
		var diary := st.sleep()
		for e in diary:
			if e["type"] in ["egg", "hatched"]:
				print("  night ", st.day, ": ", e)
	if st.stats.get("hatched", 0) < 1:
		ok = false
		printerr("AUTOPLAY: no egg hatched on the farm")

	_section("crossroads")
	await _go("teeufer", "inn")
	await _step(9, 21)
	_expect_map("kreuzweg")
	_expect("kreuzweg_arrived")

	_section("misty river")
	await _step(5, 0)
	_expect_map("karstufer")
	await _grind(float(_arg("river_level", "14")), 40)
	await _step(29, 0)
	_expect_map("nebelhafen")
	await _event("fischer", "fischer")
	_expect("quest_kormoran")
	await _go("karstufer", "from_harbour")
	await _event("silent_kormoran")
	_expect("kormoran_done")
	await _go("nebelhafen", "from_route")
	await _event("fischer", "fischer")
	_expect("has_boat")
	await _step(16, 1)
	_expect_map("schildkroetenbucht")
	await _event("order_bucht")
	_expect("order_bucht_done")
	await _event("muschelfrau")
	await _boss("boss_xuanwu", "tone_yu", "schildkroetenbucht", "from_boat")
	_expect("tone_yu")
	_expect("lesson_water")

	_section("rainbow ridge")
	await _go("kreuzweg", "inn")
	await _step(17, 25)
	_expect_map("danxiapfad")
	await _event("foerster", "foerster")
	await _event("chest_danxia")
	await _grind(float(_arg("ridge_level", "17")), 40)
	await _step(19, 21)
	_expect_map("rotfels")
	await _event("buergermeisterin", "buergermeisterin")
	await _event("toepfer", "toepfer")
	await _step(16, 21)
	_expect_map("feuergipfel")
	await _event("order_gipfel")
	await _event("einsiedler")
	await _boss("boss_bifang", "tone_zhi", "feuergipfel", "from_town")
	_expect("tone_zhi")
	_expect("three_tones")

	_section("nian")
	await _go("weidendorf", "home")
	_expect("meister_spoke")
	await _event("kind_nian", "kind_nian")
	await _event("oma_nian", "oma_nian")
	await _boss("nian_battle", "nian_driven", "weidendorf", "home")
	_expect("nian_driven")
	_expect("order_left")

	_section("singing dunes")
	await _go("kreuzweg", "inn")
	await _step(0, 12)
	_expect_map("duenenweg")
	await _grind(float(_arg("dunes_level", "27")), 70)
	await _step(0, 10)
	_expect_map("mondquell")
	await _boss("halle_tuer", "yao_hall_done", "mondquell", "inn")
	await _step(17, 0)
	_expect_map("singender_kamm")
	await _event("order_kamm")
	await _event("karawanenaelteste")
	await _boss("boss_baihu", "tone_shang", "singender_kamm", "from_town")
	_expect("tone_shang")

	_section("cloud pillars")
	await _go("kreuzweg", "inn")
	await _step(17, 0)
	_expect_map("saeulenpfad")
	await _grind(float(_arg("pillars_level", "30")), 50)
	await _step(19, 0)
	_expect_map("kiefernhang")
	await _step(33, 10)
	_expect_map("qilin_plateau")
	await _event("order_plateau")
	await _event("eremitin")
	await _boss("boss_qilin", "tone_gong", "qilin_plateau", "from_town")
	_expect("tone_gong")
	_expect("five_tones")

	_section("phoenix temple")
	await _go("saeulenpfad", "from_town")
	await _grind(float(_arg("final_level", "34")), 60)
	await _go("kiefernhang", "inn")
	await _step(15, 0)
	_expect_map("phoenixtempel")
	_expect("temple_arrived")
	await _boss("finale", "finale_done", "phoenixtempel", "from_town", 5)
	_expect("finale_done")
	_expect("phoenix_reborn")
	_expect("ending_" + ending)
	_section("end")

	print("== stats ", st.stats, " coins ", st.coins, " day ", st.day, " lexicon ", st.seen.size(), "/", GameData.lingshou_ids().size())
	print("== ending ", st.flag("ending", "?"), "  yao back ", st.flag("yao_returned"), "  crane sings ", st.flag("crane_sings"))
	for r in report:
		print("   %-16s battles %3d   level %5.1f   %s s" % [r["name"], r["battles"], r["level"], r.get("s", "-")])
	if "--transcript" in OS.get_cmdline_user_args():
		for line in DialogBox.transcript:
			print(line)
	GameState.delete_save(0)
	print("AUTOPLAY ", "OK" if ok else "FAILED")
	quit(0 if ok else 1)
