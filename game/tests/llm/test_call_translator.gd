extends "res://tests/test_case.gd"
## M0.4: the call (Ruf). Validity must be 100 % with and without the model.

const CallEval := preload("res://tests/llm/call_eval.gd")


func test_sentence_set_size() -> void:
	var s: Array = CallEval.sentences()
	var de := s.filter(func(x): return x["lang"] == "de").size()
	var en := s.filter(func(x): return x["lang"] == "en").size()
	assert_true(de + en >= 50, "at least 50 German and English sentences, got %d" % (de + en))


func test_template_translation_always_valid() -> void:
	var r := await CallEval.run("template")
	assert_eq(r["valid"], r["total"], "invalid: %s" % str(r["rows"].filter(func(x): return not x["valid"])))
	# Keywords are the fallback, not the main path; they should still get most intents right.
	var rate: float = float(r["intent_ok"]) / r["total"]
	print("    template intent match: %d/%d" % [r["intent_ok"], r["total"]])
	assert_true(rate >= 0.6, "template intent rate %.2f" % rate)


func test_validator_rejects_garbage() -> void:
	var ctx := CallTranslator.context(CallEval.battle(), 0, 1)
	assert_false(CallTranslator.validate(ctx, "not json")["valid"])
	assert_false(CallTranslator.validate(ctx, "{\"action\":\"move:flammensprung\",\"target\":\"enemy:0\"}")["valid"], "move it doesn't know")
	assert_false(CallTranslator.validate(ctx, "[1,2]")["valid"])


func test_validator_repairs_target() -> void:
	var ctx := CallTranslator.context(CallEval.battle(), 0, 1)
	var r := CallTranslator.validate(ctx, "{\"action\":\"move:tauchen\",\"target\":\"partner\",\"stance\":\"offensive\",\"fits_situation\":false}")
	assert_true(r["valid"])
	assert_true(r["target_id"].begins_with("enemy:"), "attack on partner redirected to an enemy")
	var g := CallTranslator.validate(ctx, "{\"action\":\"move:schlammwand\",\"target\":\"enemy:0\",\"stance\":\"protective\",\"fits_situation\":true}")
	assert_eq(g["target_id"], "self", "guard on an enemy becomes self")


func test_silenced_unit_only_gets_basic_attack() -> void:
	var b := CallEval.battle()
	b.unit_at(0, 0).statuses["silenced"] = {"turns": 2, "applied_turn": 0}
	var ctx := CallTranslator.context(b, 0, 0)
	assert_eq(ctx["actions"], ["move:grundangriff"] as Array[String])
	var r := CallTranslator.from_keywords(ctx, "Bambusschlag!")
	assert_eq(r["action"]["move"], "grundangriff")


func test_model_unavailable_falls_back_to_keywords() -> void:
	var s := LlmService.new()
	s.backends.clear()
	var ctx := CallTranslator.context(CallEval.battle(), 0, 1)
	var r := await CallTranslator.translate(ctx, "Schütz Bambär!", s)
	assert_eq(r["source"], "template")
	assert_eq(r["action"]["move"], "schlammwand")
	assert_eq(r["target_id"], "partner")


func test_live_model_always_valid() -> void:
	var service := LlmService.instance()
	if not service.is_model_available():
		skip("no llama-server running")
		return
	var r := await CallEval.run("model", service)
	var ms: Array = r["ms"]
	ms.sort()
	print("    model: valid %d/%d, intent %d/%d, sources %s, median %d ms, max %d ms" % [
		r["valid"], r["total"], r["intent_ok"], r["total"], r["by_source"], ms[ms.size() / 2], ms[-1]])
	assert_eq(r["valid"], r["total"])
