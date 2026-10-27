extends Control
## Boot scene: shows title, version and platform. Prints a marker line so
## automated checks (desktop and Android logcat) can confirm a clean start.

const BOOT_MARKER := "WUYIN_BOOT_OK"

@onready var _info: Label = %Info


func _ready() -> void:
	var version: String = ProjectSettings.get_setting("application/config/version")
	_info.text = "v%s · %s · Godot %s" % [version, OS.get_name(), Engine.get_version_info().string]
	print("%s version=%s os=%s renderer=%s" % [
		BOOT_MARKER, version, OS.get_name(), RenderingServer.get_current_rendering_method()])
	if "--quit-after-boot" in OS.get_cmdline_user_args():
		get_tree().quit.call_deferred()
