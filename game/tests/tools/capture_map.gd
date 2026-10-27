extends SceneTree
## Screenshots of the camera test: HD-2D, mid-transition, classic 2D.
##   godot --path game --resolution 1280x720 -s res://tests/tools/capture_map.gd -- <out_dir>


func _initialize() -> void:
	_run()


func _run() -> void:
	var out: String = OS.get_cmdline_user_args()[0] if not OS.get_cmdline_user_args().is_empty() else "user://"
	TranslationServer.set_locale("de")
	var map: Control = load("res://scenes/world/test_map.tscn").instantiate()
	root.add_child(map)
	for i in 60:
		await process_frame
	_save(out.path_join("map_hd2d.png"))
	map._toggle_mode()
	await create_timer(CameraRig.TRANSITION_S * 0.5).timeout
	_save(out.path_join("map_transition.png"))
	await create_timer(CameraRig.TRANSITION_S).timeout
	for i in 10:
		await process_frame
	_save(out.path_join("map_classic.png"))
	quit()


func _save(path: String) -> void:
	root.get_viewport().get_texture().get_image().save_png(path)
	print("CAPTURED ", path)
