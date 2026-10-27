extends RefCounted
## Shared by tests and the eval tool: runs the call sentences through a
## translator and scores validity (must be 100 %) and intent match (quality).

const SENTENCES := "res://data/llm/eval/call_sentences.json"


static func battle() -> Battle:
	var b := Battle.create(77, [
		[{"id": "bambaer", "level": 10}, {"id": "wawalurch", "level": 10}],
		[{"id": "glutfasan", "level": 10}, {"id": "rollschupp", "level": 10}]], 2)
	# A hurt partner makes "protect"/"heal" calls meaningful.
	b.unit_at(0, 1).hp = b.unit_at(0, 1).max_hp / 3
	b.unit_at(0, 0).hp = b.unit_at(0, 0).max_hp / 3
	return b


## Held-out set: never used while tuning prompts or keywords; only for honest scoring.
const HOLDOUT := "res://data/llm/eval/call_sentences_holdout.json"
static var sentence_file := SENTENCES


static func sentences() -> Array:
	return JSON.parse_string(FileAccess.get_file_as_string(sentence_file))


## mode: "template" (keywords only) or "model" (LLM with fallback).
## Returns {"total", "valid", "intent_ok", "by_source", "ms": Array, "rows": Array}
static func run(mode: String, service: LlmService = null) -> Dictionary:
	var out := {"total": 0, "valid": 0, "intent_ok": 0, "by_source": {}, "ms": [], "rows": []}
	if mode == "model" and service and service.is_model_available():
		# Like the battle screen does at battle start.
		var warm := battle()
		for slot in 2:
			var c := CallTranslator.context(warm, 0, slot)
			await service.prefill(CallTranslator.lane_for(c), CallTranslator.messages(c, "")[0]["content"]).wait()
	var previous_locale := TranslationServer.get_locale()
	for s in sentences():
		# A player calls in their game language.
		TranslationServer.set_locale({"de": "de", "en": "en", "zh": "zh_Hans"}.get(s["lang"], "en"))
		var b := battle()
		var ctx := CallTranslator.context(b, 0, int(s["slot"]))
		var res: Dictionary
		if mode == "template":
			res = CallTranslator.from_keywords(ctx, s["text"])
		else:
			res = await CallTranslator.translate(ctx, s["text"], service)
		out["total"] += 1
		var action: Dictionary = res["action"]
		var err := b.submit(0, int(s["slot"]), action)
		var ok := err == ""
		if ok:
			out["valid"] += 1
		var mv := GameData.move(action["move"])
		var intent: bool = mv["kind"] == s["kind"]
		if intent and s.has("move"):
			intent = action["move"] == s["move"]
		if intent and s.has("target"):
			intent = res.get("target_id", "") == s["target"]
		if intent:
			out["intent_ok"] += 1
		var src: String = res.get("source", "template")
		out["by_source"][src] = out["by_source"].get(src, 0) + 1
		if res.has("ms"):
			out["ms"].append(res["ms"])
		out["rows"].append({"text": s["text"], "move": action["move"], "target": res.get("target_id", ""),
			"stance": res.get("stance", ""), "intent": intent, "valid": ok, "error": err, "source": src,
			"reason": res.get("reason", "")})
	TranslationServer.set_locale(previous_locale)
	return out
