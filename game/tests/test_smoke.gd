extends "res://tests/test_case.gd"


func test_project_metadata() -> void:
	assert_eq(ProjectSettings.get_setting("application/config/name"), "Wuyin")
	assert_eq(ProjectSettings.get_setting("application/run/main_scene"), "res://scenes/main.tscn")


func test_main_scene_loads() -> void:
	var scene: PackedScene = load("res://scenes/main.tscn")
	assert_true(scene != null, "main scene loads")
	var root := scene.instantiate()
	assert_true(root.has_node("Center/Title"), "title label exists")
	root.free()


func test_data_dirs_exist() -> void:
	for dir in ["res://data/lingshou", "res://data/moves", "res://data/cards", "res://data/templates", "res://data/maps"]:
		assert_true(DirAccess.dir_exists_absolute(dir), dir)
