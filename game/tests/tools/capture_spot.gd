extends SceneTree
## One screenshot of a map at a tile and hour (desktop, needs a window):
##   godot --path game --resolution 1560x720 -s res://tests/tools/capture_spot.gd -- <out.png> <map> <x> <y> [hour] [flag,flag]

func _initialize() -> void:
	create_timer(120.0, true, false, true).timeout.connect(func(): printerr("CAPTURE timeout"); quit(2))
	_run.call_deferred()


func _run() -> void:
	var a := OS.get_cmdline_user_args()
	PlaytestLog.path = "user://capture_playtest.jsonl"
	DialogBox.autopilot = true
	GameState.current = GameState.new_game("Lian", 1, 2)
	var s := GameState.current
	for f in ["intro_done", "jinli_follows", "has_fengling", "silence_fell", "prologue_done", "tone_jue", "voice_taken"]:
		s.set_flag(f)
	for m in MapData.all_ids():
		s.set_flag(m + "_arrived")
	for f in ["temple_arrived", "plateau_arrived", "kamm_arrived", "gipfel_arrived", "bucht_arrived", "hof_arrived"]:
		s.set_flag(f)
	if a.size() > 5:
		for f in a[5].split(","):
			s.set_flag(f)
	s.add_lingshou("bambaer", 16)
	s.add_lingshou("glutpanda", 16)
	s.minute = int(a[4]) * 60 if a.size() > 4 else 11 * 60
	var world = load("res://scenes/world/world.tscn").instantiate()
	root.add_child(world)
	while world.busy or world.map == null:
		await process_frame
	await world.enter_map(a[1], "", Vector2(int(a[2]), int(a[3])), false)
	for i in 20:
		await process_frame
	root.get_viewport().get_texture().get_image().save_png(a[0])
	print("shot ", a[0])
	quit()
