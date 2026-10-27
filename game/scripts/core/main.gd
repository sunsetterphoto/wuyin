extends Control
## Boot scene: shows title, version and platform. Prints a marker line so
## automated checks (desktop and Android logcat) can confirm a clean start.

const BOOT_MARKER := "WUYIN_BOOT_OK"

@onready var _info: Label = %Info
@onready var _battle_1v1: Button = %Battle1v1
@onready var _battle_2v2: Button = %Battle2v2


func _ready() -> void:
	var version: String = ProjectSettings.get_setting("application/config/version")
	_info.text = "v%s · %s · Godot %s" % [version, OS.get_name(), Engine.get_version_info().string]
	print("%s version=%s os=%s renderer=%s" % [
		BOOT_MARKER, version, OS.get_name(), RenderingServer.get_current_rendering_method()])
	_battle_1v1.pressed.connect(_open_battle.bind(1))
	_battle_2v2.pressed.connect(_open_battle.bind(2))
	if "--quit-after-boot" in OS.get_cmdline_user_args():
		get_tree().quit.call_deferred()


func _open_battle(active: int) -> void:
	var screen := load("res://scripts/battle/battle_screen.gd")
	screen.setup = screen.default_setup(active)
	get_tree().change_scene_to_file("res://scenes/battle/battle_screen.tscn")
