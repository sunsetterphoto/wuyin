class_name Settings
extends RefCounted
## Player options, stored in user://settings.cfg and applied at start.

const PATH := "user://settings.cfg"
const DEFAULTS := {
	"locale": "",  # "" = device language (falls back to English)
	"llm_enabled": true,
	"camera": "hd2d",
	"text_speed": 2,  # 1 slow, 2 normal, 3 instant
	"music_db": -6.0,
	"sfx_db": 0.0,
	"big_text": false,
}

static var _values := {}


static func get_value(key: String) -> Variant:
	if _values.is_empty():
		load_settings()
	return _values.get(key, DEFAULTS[key])


static func set_value(key: String, value: Variant) -> void:
	if _values.is_empty():
		load_settings()
	_values[key] = value
	var cfg := ConfigFile.new()
	for k in _values:
		cfg.set_value("options", k, _values[k])
	cfg.save(PATH)
	apply()


static func load_settings() -> void:
	_values = DEFAULTS.duplicate()
	var cfg := ConfigFile.new()
	if cfg.load(PATH) == OK:
		for k in DEFAULTS:
			_values[k] = cfg.get_value("options", k, DEFAULTS[k])


## Applies language and model switch; music volume is read by the Music autoload.
static func apply() -> void:
	var loc: String = get_value("locale")
	if loc == "":
		var sys := OS.get_locale_language()
		loc = "de" if sys == "de" else ("zh_Hans" if sys == "zh" else "en")
	TranslationServer.set_locale(loc)
	LlmService.instance().enabled = bool(get_value("llm_enabled")) and ProjectSettings.get_setting(LlmService.SETTING_ENABLED, true)
	var music := AudioServer.get_bus_index("Music")
	if music >= 0:
		AudioServer.set_bus_volume_db(music, float(get_value("music_db")))


## Characters per second for the dialog typewriter (0 = instant).
static func chars_per_second() -> float:
	return [0.0, 28.0, 55.0, 0.0][int(get_value("text_speed"))]
