extends SceneTree
## Screenshot of the title screen (desktop, needs a window):
##   godot --path game --resolution 1560x720 -s res://tests/tools/capture_title.gd -- <out.png> [locale]

func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 1:
		TranslationServer.set_locale(a[1])
	root.add_child(load("res://scenes/main.tscn").instantiate())
	for i in 90:
		await process_frame
	root.get_viewport().get_texture().get_image().save_png(a[0])
	print("shot ", a[0])
	quit()
