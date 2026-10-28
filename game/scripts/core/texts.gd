class_name Texts
extends RefCounted
## Translations in a specific language, independent of the current game
## language (prompts name things in the answer language; tests check that
## every key exists everywhere). The project has several CSV files per
## language, so TranslationServer.get_translation_object() is not enough.

static var _by_locale := {}


static func get_text(key: String, locale: String) -> String:
	for t in _translations(locale):
		var msg := String(t.get_message(key))
		if msg != "":
			return msg
	return ""


static func has(key: String, locale: String) -> bool:
	return get_text(key, locale) != ""


static func _translations(locale: String) -> Array:
	if not _by_locale.has(locale):
		var list := []
		for path in ProjectSettings.get_setting("internationalization/locale/translations", PackedStringArray()):
			var t: Translation = load(path)
			if t and t.locale == locale:
				list.append(t)
		_by_locale[locale] = list
	return _by_locale[locale]
