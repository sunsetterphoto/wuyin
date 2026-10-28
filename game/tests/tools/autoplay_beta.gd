extends SceneTree
## Plays the whole beta chapter without a human: interacts with people,
## steps on triggers and warps in story order, lets the autopilot fight,
## befriend and free. Fails (exit 1) when a story flag is missing afterwards.
##
##   godot --headless --path game -s res://tests/tools/autoplay_beta.gd
## Prints the dialog transcript with -- --transcript.

var world
var ok := true
var grind_battles := 0


func _initialize() -> void:
	create_timer(600.0, true, false, true).timeout.connect(func(): printerr("AUTOPLAY timeout"); quit(2))
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


func _levels() -> String:
	return ", ".join(GameState.current.party.map(func(r): return "%s %d" % [r["species"], r["level"]]))


func _grind(map_id: String, until_level: int, max_battles := 60) -> void:
	BattleView.autopilot_fight = true
	var md: MapData = world.map
	var table: Array = md.def["encounters"]["table"]
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	while grind_battles < max_battles:
		var avg := 0.0
		for r in GameState.current.party:
			avg += r["level"]
		avg /= GameState.current.party.size()
		if avg >= until_level:
			break
		var e: Dictionary = table[rng.randi_range(0, table.size() - 1)]
		# Like a player: fill a free bell by befriending, otherwise fight.
		BattleView.autopilot_fight = GameState.current.party.size() >= GameState.current.bells
		world.start_wild_battle(e["species"], rng.randi_range(int(e["levels"][0]), int(e["levels"][1])), null)
		await _idle()
		grind_battles += 1
		if world.map.id != map_id:
			await world.enter_map(map_id, "", Vector2(-1, -1), false)
		GameState.current.heal_party()
	BattleView.autopilot_fight = false


func _run() -> void:
	DialogBox.autopilot = true
	BattleView.autopilot = true
	BefriendView.autopilot = true
	PlaytestLog.path = "user://autoplay_playtest.jsonl"
	GameState.delete_save(0)
	GameState.current = GameState.new_game("Auto")
	world = load("res://scenes/world/world.tscn").instantiate()
	root.add_child(world)
	await _idle()
	print("== prologue")
	_expect("intro_done")
	await _event("meister_gift", "meister")
	_expect("has_fengling")
	await _step(15, 10)
	_expect("silence_fell")
	await _step(31, 14)
	_expect_map("flussufer")
	_expect("river_arrived")
	await _event("prolog_wawalurch")
	_expect("yao_battle1")
	await _event("prolog_nebelaffe")
	_expect("prologue_tamed")
	await _step(0, 7)
	_expect_map("weidendorf")
	await _step(27, 14)
	_expect("voice_taken")
	_expect("prologue_done")
	print("  party: ", _levels(), "  bells ", GameState.current.bells)
	print("== bamboo path")
	await _step(28, 0)
	_expect_map("bambuspfad")
	await _event("chest_bamboo")
	await _grind("bambuspfad", int(_arg("bamboo_level", "6")), 30)
	print("  after grinding (%d battles): %s" % [grind_battles, _levels()])
	await _step(29, 5)
	_expect("yao_battle2")
	await _step(35, 5)
	_expect_map("teeufer")
	_expect("teeufer_arrived")
	print("== town")
	await _event("inn_door")
	await _event("shop_door")
	await _event("teahouse", "teemeister")
	await _event("stille_frau", "stille_frau")
	await _step(26, 0)
	_expect_map("reisterrassen")
	print("== terraces")
	await _grind("reisterrassen", int(_arg("terrace_level", "9")), 60)
	print("  after grinding (%d battles): %s" % [grind_battles, _levels()])
	await _event("moth_a")
	await _event("silent_leopard")
	print("  leopard freed: ", GameState.current.flag("freed_firnleopard"), "  party: ", _levels(), "  farm ", GameState.current.farm.size())
	await _step(14, 0)
	_expect_map("drachenschrein")
	_expect("shrine_arrived")
	await _event("moench")
	await _event("boss_qinglong")
	if not GameState.current.flag("tone_jue"):
		print("  boss lost once, healing and retrying")
		await world.enter_map("drachenschrein", "from_terraces")
		GameState.current.heal_party()
		await _event("boss_qinglong")
	_expect("tone_jue")
	print("  freed dragon: ", GameState.current.flag("freed_qinglong"), "  bells ", GameState.current.bells)
	print("== stats ", GameState.current.stats, " coins ", GameState.current.coins, " grind ", grind_battles)
	if "--transcript" in OS.get_cmdline_user_args():
		for line in DialogBox.transcript:
			print(line)
	GameState.delete_save(0)
	print("AUTOPLAY ", "OK" if ok else "FAILED")
	quit(0 if ok else 1)
