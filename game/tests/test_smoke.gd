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


func test_battle_screen_loads() -> void:
	var scene: PackedScene = load("res://scenes/battle/battle_screen.tscn")
	assert_true(scene != null, "battle scene loads")


func test_test_map_loads() -> void:
	assert_true(load("res://scenes/world/test_map.tscn") != null, "test map scene loads")
	for kind in ["grass", "path", "water", "stone", "bamboo", "wood", "roof", "lantern"]:
		assert_eq(PixelArt.tile(kind).get_size(), Vector2(32, 32), kind)
	for kind in ["hero", "jinli", "panda"]:
		assert_eq(PixelArt.character(kind).get_size(), Vector2(32, 48), kind)
