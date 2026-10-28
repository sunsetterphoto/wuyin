class_name LingshouVoice
extends RefCounted
## Gives Lingshou their voice: 1-2 sentences from the model based on the
## character card and the current event, or a temperament template. Silenced
## Lingshou only speak in fragments. Output always passes TextGuard.
##
##   var line := await LingshouVoice.comment(unit, "hit", {"target": "Glutfasan"}, "de")
##   # line = {"text": String, "source": "model"|"template", "ms": int}

const TEMPLATES_PATH := "res://data/templates/voice.json"
const EVENTS: Array[String] = ["attack", "hit", "low_hp", "win", "obey", "disobey", "bonus"]
## Hard limits per role (characters); token limits live in data/llm/roles.json.
const MAX_CHARS := {"lingshou_voice": 140, "silenced_voice": 48}
const LANGUAGE_NAMES := {"en": "English", "de": "German", "zh_Hans": "Simplified Chinese"}
## Repeated in the target language at the end: small models follow this far better.
const ANSWER_IN := {"en": "Answer in English.", "de": "Antworte auf Deutsch.", "zh_Hans": "请用中文回答。"}

## English descriptions of events for the prompt (facts, filled from the battle).
const EVENT_FACTS := {
	"attack": "You are attacking {target}.",
	"hit": "{target} just hit you hard.",
	"low_hp": "You are badly hurt and close to exhaustion.",
	"win": "Your team just won the battle.",
	"obey": "Your partner (the player) called: \"{call}\". You do it.",
	"disobey": "Your partner (the player) called: \"{call}\". You refuse and do your own thing.",
	"bonus": "Your partner's call was clever and gave you an advantage.",
}

static var _templates: Dictionary = {}


static func card(unit: BattleUnit, locale: String) -> String:
	var path := "res://data/" + String(unit.species.get("voice_card", "")).replace("{lang}", locale)
	if not FileAccess.file_exists(path):
		path = "res://data/" + String(unit.species.get("voice_card", "")).replace("{lang}", "en")
	return FileAccess.get_file_as_string(path).strip_edges()


static func messages(unit: BattleUnit, event: String, facts: Dictionary, locale: String) -> Array:
	var silenced: bool = unit.species.get("alignment") == "silenced" or unit.has_status("silenced")
	var lang: String = LANGUAGE_NAMES.get(locale, "English")
	var system := ""
	if silenced:
		system = "You are %s, a spirit animal whose voice was stolen. Answer in %s with a broken fragment of at most 6 words, trailing off with an ellipsis. No full sentences." % [
			TranslationServer.translate(unit.name_key()), lang]
	else:
		system = "You are %s, a spirit animal in a family-friendly fantasy game. Stay in character.\n%s\nAnswer in %s with one or two short sentences, at most 20 words. No quotes, no emojis, no narration." % [
			_name_in(unit.name_key(), locale), card(unit, locale), lang]
	var fact := String(EVENT_FACTS.get(event, event)).format(facts)
	return [{"role": "system", "content": system}, {"role": "user", "content": "%s %s" % [fact, ANSWER_IN.get(locale, "")]}]


## on_token: optional Callable(text_so_far) for streaming into the UI (capped at the role limit).
static func comment(unit: BattleUnit, event: String, facts := {}, locale := "", service: LlmService = null,
		on_token := Callable()) -> Dictionary:
	locale = locale if locale != "" else TranslationServer.get_locale()
	service = service if service else LlmService.instance()
	var silenced: bool = unit.species.get("alignment") == "silenced" or unit.has_status("silenced")
	var role := "silenced_voice" if silenced else "lingshou_voice"
	var job := service.ask(role, messages(unit, event, facts, locale))
	if on_token.is_valid():
		job.token.connect(func(_t): on_token.call(TextGuard.limit(job.text.strip_edges(), MAX_CHARS[role])))
	var r := await job.wait()
	if r["ok"]:
		var forbidden: Array = []
		var text := TextGuard.clean(r["text"], locale, MAX_CHARS[role], forbidden)
		if text != "":
			return {"text": text, "source": "model", "ms": r["total_ms"], "reason": ""}
		r["reason"] = "rejected by guard"
	return {"text": template(unit, event, locale, silenced), "source": "template", "ms": r["total_ms"],
		"reason": r["reason"]}


static func template(unit: BattleUnit, event: String, locale: String, silenced := false) -> String:
	var data := _data()
	var lang := locale if data["voice"].has(locale) else "en"
	if silenced:
		var frags: Array = data["silenced"][lang]
		return frags[abs(hash(unit.uid + event)) % frags.size()]
	var temperament: String = unit.species.get("temperaments", ["gentle"])[0]
	var by_event: Dictionary = data["voice"][lang].get(temperament, data["voice"][lang]["gentle"])
	return by_event.get(event, by_event["attack"])


static func _name_in(key: String, locale: String) -> String:
	var tr_obj := TranslationServer.get_translation_object(locale)
	return String(tr_obj.get_message(key)) if tr_obj else key


static func _data() -> Dictionary:
	if _templates.is_empty():
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(TEMPLATES_PATH))
		_templates = parsed if parsed is Dictionary else {}
	return _templates
