extends SceneTree
## Screenshots of the full game for a visual check (desktop, needs a window):
##   godot --path game --resolution 1560x720 -s res://tests/tools/capture_full.gd -- <out_dir>
## Every map after the Bamboo Sea at different times and weather, the farm,
## the new menus, the Nian battle and the end screen.

var out := "res://../build/screens"


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		out = args[0]
	create_timer(240.0, true, false, true).timeout.connect(func(): printerr("CAPTURE timeout"); quit(2))
	_run.call_deferred()


func _shot(name: String) -> void:
	for i in 10:
		await process_frame
	var img := root.get_viewport().get_texture().get_image()
	img.save_png(out.path_join(name + ".png"))
	print("shot ", name)


func _run() -> void:
	PlaytestLog.path = "user://capture_playtest.jsonl"
	DialogBox.autopilot = true
	GameState.current = GameState.new_game("Lian", 1, 2)
	var s := GameState.current
	s.seed = 3
	for f in ["intro_done", "jinli_follows", "has_fengling", "silence_fell", "prologue_done", "tone_jue", "voice_taken"]:
		s.set_flag(f)
	for m in MapData.all_ids():
		s.set_flag(m + "_arrived")
	for f in ["kreuzweg_arrived", "karstufer_arrived", "nebelhafen_arrived", "bucht_arrived", "danxiapfad_arrived", "rotfels_arrived",
			"gipfel_arrived", "duenenweg_arrived", "mondquell_arrived", "kamm_arrived", "saeulenpfad_arrived", "kiefernhang_arrived",
			"plateau_arrived", "temple_arrived", "hof_arrived", "teeufer_arrived", "river_arrived", "terraces_arrived", "shrine_arrived"]:
		s.set_flag(f)
	s.add_lingshou("bambaer", 16)
	s.add_lingshou("glutpanda", 16)
	for sp in ["wawalurch", "perlkormoran", "felstakin", "glockenkamel", "zirpo", "stromdelfin"]:
		var rec := s.add_lingshou(sp, 12)
		if s.party.has(rec):
			s.move_to_farm(s.party.find(rec))
	var world = load("res://scenes/world/world.tscn").instantiate()
	root.add_child(world)
	while world.busy or world.map == null:
		await process_frame
	var plan := [["kreuzweg", 10, ""], ["karstufer", 9, "fog"], ["nebelhafen", 12, "rain"], ["schildkroetenbucht", 15, ""],
		["danxiapfad", 11, "sun"], ["rotfels", 18, ""], ["feuergipfel", 19, ""], ["duenenweg", 13, "sandstorm"],
		["mondquell", 20, ""], ["singender_kamm", 17, ""], ["saeulenpfad", 9, "snow"], ["kiefernhang", 22, ""],
		["qilin_plateau", 6, ""], ["phoenixtempel", 18, ""], ["hof", 10, ""], ["weidendorf", 23, "storm"]]
	for p in plan:
		s.minute = int(p[1]) * 60
		s.weather.clear()
		if p[2] != "":
			for r in Weather.TABLE:
				s.weather[r] = p[2]
		await world.enter_map(p[0], "", Vector2(-1, -1), false)
		await _shot("full_map_%s" % p[0])
	s.weather.clear()
	world._rig.set_mode(CameraRig.CLASSIC, false)
	s.minute = 11 * 60
	for m in ["teeufer", "nebelhafen", "kreuzweg"]:
		await world.enter_map(m, "", Vector2(-1, -1), false)
		await _shot("full_classic_" + m)
	world._rig.set_mode(CameraRig.HD2D, false)
	for room in ["teeufer_inn", "weidendorf_home", "weidendorf_workshop", "nebelhafen_restaurant", "rotfels_teahouse", "teeufer_shop"]:
		await world.enter_map(room, "door", Vector2(-1, -1), false)
		await _shot("full_room_" + room)
	await world.enter_map("hof", "", Vector2(-1, -1), false)
	for entry in [["full_pen", PenMenu.make(0)], ["full_carpenter", CarpenterMenu.new()], ["full_food", RestaurantMenu.make(["fischsuppe", "feuertopf"])],
			["full_inn", InnMenu.make(true)]]:
		world._overlay_layer.add_child(entry[1])
		await _shot(entry[0])
		entry[1].queue_free()
	var menu := GameMenu.new()
	world._overlay_layer.add_child(menu)
	await process_frame
	menu._lexicon()
	await _shot("full_lexicon")
	menu._lex_entry("xuanwu")
	await _shot("full_lexicon_entry")
	menu._details(s.party[0])
	await _shot("full_moves")
	menu.queue_free()
	var pv := PersuadeView.new()
	world._overlay_layer.add_child(pv)
	pv.run({"who": "order_bucht", "intro": "PER_BUCHT_INTRO", "accept": {"logic": 2}, "need": 2, "bribe": 50}, s)
	await _shot("full_persuade")
	pv.queue_free()
	s.give_item("trommel")
	s.give_item("feuerwerk")
	var view := BattleView.new()
	world._overlay_layer.add_child(view)
	view.run({"enemies": [{"id": "nian", "level": 20}, {"id": "schattenmotte", "level": 16}], "active": 2, "bg": "village_night"}, s)
	for i in 90:
		await process_frame
	await _shot("full_battle_nian")
	view.queue_free()
	var boss := BattleView.new()
	world._overlay_layer.add_child(boss)
	boss.run({"enemies": [{"id": "xuanwu", "level": 18, "role": "silenced"}, {"id": "schattenmotte", "level": 15}], "active": 2, "bg": "karst"}, s)
	for i in 90:
		await process_frame
	await _shot("full_battle_xuanwu")
	boss.queue_free()
	s.set_flag("ending", "reconcile")
	var end := EndScreen.make("final")
	world._overlay_layer.add_child(end)
	await _shot("full_end")
	GameState.delete_save(0)
	quit()
