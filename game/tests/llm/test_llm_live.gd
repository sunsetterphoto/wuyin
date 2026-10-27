extends "res://tests/test_case.gd"
## Talks to a real llama-server if one runs on WUYIN_LLM_PORT (default 8090);
## skipped otherwise, so the suite stays green without a model.


func test_live_schema_constrained_answer() -> void:
	var backend := HttpLlamaBackend.new("127.0.0.1",
		int(OS.get_environment("WUYIN_LLM_PORT")) if OS.has_environment("WUYIN_LLM_PORT") else 8090)
	if not backend.is_available():
		skip("no llama-server running")
		return
	var s := LlmService.new()
	s.backends.clear()
	s.backends.append(backend)
	s.roles["npc_dialog"]["timeout_ms"] = 15000  # first request may load the model
	var schema := {"type": "object", "properties": {"stance": {"enum": ["offensive", "defensive"]}}, "required": ["stance"]}
	var job := s.ask("npc_dialog", [{"role": "user", "content": "Attack! Answer as JSON."}], schema)
	var tokens := [0]
	job.token.connect(func(_t): tokens[0] += 1)
	var r := await job.wait()
	assert_true(r["ok"], r.get("reason", ""))
	var data = JSON.parse_string(r["text"])
	assert_true(data is Dictionary and data.get("stance") in ["offensive", "defensive"], r["text"])
	assert_true(tokens[0] > 1, "streamed in several tokens")
	print("    live: first token %d ms, total %d ms" % [r["first_token_ms"], r["total_ms"]])
