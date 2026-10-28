extends Control
## Title screen: continue, new game (name and look), options, feedback.
## Debug builds also list the Phase-0 test scenes. Prints a marker line so
## automated checks (desktop and Android logcat) can confirm a clean start.

const BOOT_MARKER := "WUYIN_BOOT_OK"
const WORLD_SCENE := "res://scenes/world/world.tscn"

var _menu: VBoxContainer
var _info: Label


func _ready() -> void:
	Inputs.ensure()
	Settings.apply()
	theme = UiTheme.get_theme()
	var version: String = ProjectSettings.get_setting("application/config/version")
	print("%s version=%s os=%s renderer=%s" % [
		BOOT_MARKER, version, OS.get_name(), RenderingServer.get_current_rendering_method()])
	_build(version)
	LlmService.instance().warm_up()
	Audio.play("title")
	# Dev automation: `adb shell run-as com.wuyin.game sh -c 'echo res://scenes/dev/llm_bench.tscn > files/dev_autorun.txt'`
	if OS.is_debug_build() and FileAccess.file_exists("user://dev_autorun.txt"):
		var scene := FileAccess.get_file_as_string("user://dev_autorun.txt").strip_edges()
		DirAccess.remove_absolute("user://dev_autorun.txt")
		if ResourceLoader.exists(scene):
			get_tree().change_scene_to_file.call_deferred(scene)
			return
	if "--camera-bench" in OS.get_cmdline_user_args():
		get_tree().change_scene_to_file.call_deferred("res://scenes/world/test_map.tscn")
	if "--quit-after-boot" in OS.get_cmdline_user_args():
		get_tree().quit.call_deferred()


func _build(version: String) -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color(0.09, 0.07, 0.12)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	if ResourceLoader.exists("res://assets/ui/title.png"):
		var art := TextureRect.new()
		art.texture = load("res://assets/ui/title.png")
		art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		add_child(art)
	var col := VBoxContainer.new()
	col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 10)
	add_child(col)
	var title := UiTheme.label("Wuyin", 84, UiTheme.GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_outline_color", Color("1a1620"))
	title.add_theme_constant_override("outline_size", 16)
	col.add_child(title)
	var sub := UiTheme.label(tr("TITLE_SUBTITLE"), 30)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_color_override("font_outline_color", Color("1a1620"))
	sub.add_theme_constant_override("outline_size", 10)
	col.add_child(sub)
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 30)
	col.add_child(spacer)
	_menu = VBoxContainer.new()
	_menu.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_menu.add_theme_constant_override("separation", 10)
	col.add_child(_menu)
	var cont: Button = null
	if GameState.has_save(World.AUTOSAVE_SLOT):
		cont = _add(tr("TITLE_CONTINUE"), _continue)
	var new_b := _add(tr("TITLE_NEW"), _new_game)
	_add(tr("MENU_OPTIONS"), _options)
	_add(tr("MENU_FEEDBACK"), _feedback)
	(cont if cont else new_b).grab_focus.call_deferred()
	if OS.is_debug_build():
		var dev := HBoxContainer.new()
		dev.set_anchor(SIDE_TOP, 1.0, true)
		dev.set_anchor(SIDE_BOTTOM, 1.0, true)
		dev.offset_top = -70
		dev.offset_left = 16
		dev.add_theme_constant_override("separation", 6)
		add_child(dev)
		for entry in [["MENU_BATTLE_1V1", func(): _open_battle(1)], ["MENU_BATTLE_2V2", func(): _open_battle(2)],
				["MENU_CAMERA_TEST", func(): get_tree().change_scene_to_file("res://scenes/world/test_map.tscn")]]:
			var b := UiTheme.button(tr(entry[0]), entry[1])
			b.add_theme_font_size_override("font_size", 14)
			b.custom_minimum_size = Vector2(0, 48)
			dev.add_child(b)
	_info = UiTheme.label("v%s · %s · %s" % [version, OS.get_name(),
		tr("TITLE_LLM_ON") if LlmService.instance().is_model_available() else tr("TITLE_LLM_OFF")], 16, UiTheme.MUTED)
	_info.set_anchor(SIDE_LEFT, 1.0, true)
	_info.set_anchor(SIDE_RIGHT, 1.0, true)
	_info.set_anchor(SIDE_TOP, 1.0, true)
	_info.set_anchor(SIDE_BOTTOM, 1.0, true)
	_info.offset_left = -520
	_info.offset_top = -40
	_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(_info)


func _add(text: String, cb: Callable) -> Button:
	var b := UiTheme.button(text, cb, 420)
	b.add_theme_font_size_override("font_size", 26)
	_menu.add_child(b)
	return b


func _continue() -> void:
	var s := GameState.load_game(World.AUTOSAVE_SLOT)
	if s == null:
		return
	GameState.current = s
	get_tree().change_scene_to_file(WORLD_SCENE)


func _new_game() -> void:
	var n := NewGameMenu.new()
	add_child(n)
	var result: Dictionary = await n.finished
	n.queue_free()
	if result.is_empty():
		return
	GameState.current = GameState.new_game(result["name"], result["hair"], result["outfit"])
	get_tree().change_scene_to_file(WORLD_SCENE)


func _options() -> void:
	var o := OptionsMenu.new()
	add_child(o)
	await o.closed
	o.queue_free()
	get_tree().reload_current_scene()


func _feedback() -> void:
	var f := FeedbackForm.new()
	f.context = "title"
	add_child(f)
	await f.closed
	f.queue_free()


func _open_battle(active: int) -> void:
	var screen := load("res://scripts/battle/battle_screen.gd")
	screen.setup = screen.default_setup(active)
	get_tree().change_scene_to_file("res://scenes/battle/battle_screen.tscn")
