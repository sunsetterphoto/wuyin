class_name OptionsMenu
extends MenuScreen
## Options: language, language model on/off, camera look, text speed, music
## volume, big text.

const LOCALES := [["", "OPT_LANG_SYSTEM"], ["de", "OPT_LANG_DE"], ["en", "OPT_LANG_EN"], ["zh_Hans", "OPT_LANG_ZH"]]


func _ready() -> void:
	_build()


func _build() -> void:
	clear_body()
	title_label.text = tr("MENU_OPTIONS")
	_choice("OPT_LANGUAGE", LOCALES.map(func(l): return l[0]), LOCALES.map(func(l): return l[1]), "locale")
	_choice("OPT_LLM", [true, false], ["OPT_ON", "OPT_OFF"], "llm_enabled")
	body.add_child(UiTheme.label(tr("OPT_LLM_NOTE") if LlmService.instance().backends.any(func(b): return b.is_available()) \
		else tr("OPT_LLM_MISSING"), 17, UiTheme.MUTED))
	_choice("OPT_CAMERA", ["hd2d", "classic"], ["CAM_MODE_HD2D", "CAM_MODE_CLASSIC"], "camera")
	_choice("OPT_TEXT_SPEED", [1, 2, 3], ["OPT_SLOW", "OPT_NORMAL", "OPT_INSTANT"], "text_speed")
	_choice("OPT_MUSIC", [-60.0, -14.0, -6.0, 0.0], ["OPT_OFF", "OPT_QUIET", "OPT_NORMAL", "OPT_LOUD"], "music_db")
	_choice("OPT_BIG_TEXT", [false, true], ["OPT_OFF", "OPT_ON"], "big_text")


func _choice(label_key: String, values: Array, names: Array, setting: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var l := UiTheme.label(tr(label_key), 22)
	l.custom_minimum_size = Vector2(260, 0)
	row.add_child(l)
	var current = Settings.get_value(setting)
	for i in values.size():
		var b := UiTheme.button(tr(names[i]), func():
			Settings.set_value(setting, values[i])
			if setting == "big_text":
				UiTheme.reset()
				theme = UiTheme.get_theme()
			_build())
		if typeof(current) == typeof(values[i]) and current == values[i]:
			b.add_theme_color_override("font_color", UiTheme.GOLD)
			b.add_theme_stylebox_override("normal", b.get_theme_stylebox("hover"))
		row.add_child(b)
	body.add_child(row)
