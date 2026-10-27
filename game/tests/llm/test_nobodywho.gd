extends "res://tests/test_case.gd"
## In-process model via NobodyWho. Needs WUYIN_MODEL=<path to .gguf>; skipped otherwise.

const CallEval := preload("res://scripts/dev/call_eval.gd")


func _service() -> LlmService:
	var s := LlmService.new()
	s.backends.clear()
	s.backends.append(NobodyWhoBackend.new())
	return s


func test_extension_loads() -> void:
	assert_true(NobodyWhoBackend.extension_loaded(), "addons/nobodywho registered its classes")


func test_streaming_and_grammar_switch() -> void:
	var s := _service()
	if not s.is_model_available():
		skip("WUYIN_MODEL not set")
		return
	for r in s.roles.values():
		r["timeout_ms"] = 20000  # first call loads the model
	var tokens := [0]
	var job := s.ask("lingshou_voice", [{"role": "user", "content": "Say hello to a panda in one sentence."}])
	job.token.connect(func(_t): tokens[0] += 1)
	var r := await job.wait()
	assert_true(r["ok"], r["reason"])
	assert_true(tokens[0] > 1, "streamed")
	var a := await s.ask("call_translator", [{"role": "user", "content": "Attack!"}], {}, 'root ::= "A" | "B"').wait()
	assert_true(a["text"] in ["A", "B"], a["text"])
	var b := await s.ask("call_translator", [{"role": "user", "content": "Yes?"}], {}, 'root ::= "yes" | "no"').wait()
	assert_true(b["text"] in ["yes", "no"], b["text"])


func test_max_tokens_enforced() -> void:
	var s := _service()
	if not s.is_model_available():
		skip("WUYIN_MODEL not set")
		return
	s.roles["silenced_voice"]["timeout_ms"] = 20000
	var r := await s.ask("silenced_voice", [{"role": "user", "content": "Tell a very long story about the sea."}]).wait()
	# 15 tokens is roughly 60 characters; generous bound.
	assert_true(r["text"].length() < 120, "%d chars" % r["text"].length())


func test_call_sentences_in_process() -> void:
	var s := _service()
	if not s.is_model_available():
		skip("WUYIN_MODEL not set")
		return
	await s.backends[0].warm_up()
	var r := await CallEval.run("model", s)
	var ms: Array = r["ms"]
	ms.sort()
	print("    nobodywho: valid %d/%d, intent %d/%d, sources %s, median %d ms" % [
		r["valid"], r["total"], r["intent_ok"], r["total"], r["by_source"], ms[ms.size() / 2]])
	assert_eq(r["valid"], r["total"])
