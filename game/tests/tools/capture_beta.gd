extends SceneTree
## Renders screenshots of beta scenes for a visual check (desktop):
##   godot --path game -s res://tests/tools/capture_beta.gd -- <out_dir>
## Shows the title, every map (fresh game, some flags set) and a battle.

var out := "res://../build/screens"


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		out = args[0]
	_run.call_deferred()


func _shot(name: String) -> void:
	for i in 8:
		await process_frame
	var img := root.get_viewport().get_texture().get_image()
	img.save_png(out.path_join(name + ".png"))
	print("shot ", name)


func _run() -> void:
	PlaytestLog.path = "user://capture_playtest.jsonl"
	var title: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(title)
	await _shot("beta_title")
	title.queue_free()
	GameState.current = GameState.new_game("Lian", 1, 2)
	var s := GameState.current
	for f in ["intro_done", "jinli_follows", "river_arrived", "teeufer_arrived", "terraces_arrived", "shrine_arrived", "has_fengling"]:
		s.set_flag(f)
	s.add_lingshou("bambaer", 6)
	s.add_lingshou("wawalurch", 6)
	var world = load("res://scenes/world/world.tscn").instantiate()
	root.add_child(world)
	while world.busy or world.map == null:
		await process_frame
	for id in ["weidendorf", "flussufer", "bambuspfad", "teeufer", "reisterrassen", "drachenschrein"]:
		await world.enter_map(id, "", Vector2(-1, -1), false)
		await _shot("beta_map_" + id)
	await world.enter_map("teeufer", "", Vector2(-1, -1), false)
	world.dialog.say("Teemeister Chen", "Setz dich. Tee schmeckt auch in der Stille. Und Neuigkeiten gibt es immer.", {"tone": "gong", "style": "gentle"})
	await _shot("beta_dialog")
	world.dialog.advanced.emit()
	var view := BattleView.new()
	world._overlay_layer.add_child(view)
	view.run({"enemies": [{"id": "jadelibelle", "level": 5, "role": "wild"}], "active": 1, "bg": "bamboo"}, s)
	for i in 90:
		await process_frame
	await _shot("beta_battle_wild")
	view.queue_free()
	var boss := BattleView.new()
	world._overlay_layer.add_child(boss)
	boss.run({"enemies": [{"id": "qinglong", "level": 12, "role": "silenced"}, {"id": "schattenmotte", "level": 10}], "active": 2, "bg": "shrine"}, s)
	for i in 90:
		await process_frame
	await _shot("beta_battle_boss")
	var menu := GameMenu.new()
	world._overlay_layer.add_child(menu)
	await _shot("beta_menu")
	GameState.delete_save(0)
	quit()
