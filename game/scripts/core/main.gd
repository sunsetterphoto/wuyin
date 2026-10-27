extends Control
## Boot scene: shows title, version and platform. Prints a marker line so
## automated checks (desktop and Android logcat) can confirm a clean start.

const BOOT_MARKER := "WUYIN_BOOT_OK"

@onready var _info: Label = %Info
@onready var _battle_1v1: Button = %Battle1v1
@onready var _battle_2v2: Button = %Battle2v2
@onready var _camera_test: Button = %CameraTest


func _ready() -> void:
	var version: String = ProjectSettings.get_setting("application/config/version")
	_info.text = "v%s · %s · Godot %s" % [version, OS.get_name(), Engine.get_version_info().string]
	print("%s version=%s os=%s renderer=%s" % [
		BOOT_MARKER, version, OS.get_name(), RenderingServer.get_current_rendering_method()])
	_battle_1v1.pressed.connect(_open_battle.bind(1))
	_battle_2v2.pressed.connect(_open_battle.bind(2))
	_camera_test.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/world/test_map.tscn"))
	if "--camera-bench" in OS.get_cmdline_user_args():
		get_tree().change_scene_to_file.call_deferred("res://scenes/world/test_map.tscn")
	LlmService.instance().warm_up()
	# Dev automation: `adb shell run-as com.wuyin.game sh -c 'echo res://scenes/dev/llm_bench.tscn > files/dev_autorun.txt'`
	if OS.is_debug_build() and FileAccess.file_exists("user://dev_autorun.txt"):
		var scene := FileAccess.get_file_as_string("user://dev_autorun.txt").strip_edges()
		DirAccess.remove_absolute("user://dev_autorun.txt")
		if ResourceLoader.exists(scene):
			get_tree().change_scene_to_file.call_deferred(scene)
			return
	if "--quit-after-boot" in OS.get_cmdline_user_args():
		get_tree().quit.call_deferred()


func _open_battle(active: int) -> void:
	var screen := load("res://scripts/battle/battle_screen.gd")
	screen.setup = screen.default_setup(active)
	get_tree().change_scene_to_file("res://scenes/battle/battle_screen.tscn")
