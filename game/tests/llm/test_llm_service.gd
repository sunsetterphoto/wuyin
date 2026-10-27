extends "res://tests/test_case.gd"
## LLM service contract: streaming, timeout with fallback, disabled mode,
## missing model. Uses a scripted backend, no model needed.

const FakeBackend := preload("res://tests/llm/fake_backend.gd")


func _service(fake: LlmBackend, enabled := true) -> LlmService:
	var s := LlmService.new()
	s.enabled = enabled
	s.backends.clear()
	if fake:
		s.backends.append(fake)
	# Short timeouts so tests run fast.
	for r in s.roles.values():
		r["timeout_ms"] = 300
	return s


func test_streams_tokens_and_finishes() -> void:
	var fake := FakeBackend.new()
	fake.tokens = ["{\"a\"", ":", "1}"] as Array[String]
	var job := _service(fake).ask("call_translator", [])
	var seen: Array[String] = []
	job.token.connect(func(t): seen.append(t))
	var r := await job.wait()
	assert_true(r["ok"])
	assert_eq(r["text"], "{\"a\":1}")
	assert_eq(seen.size(), 3, "tokens streamed one by one")
	assert_true(r["first_token_ms"] >= 0)


func test_timeout_falls_back() -> void:
	var fake := FakeBackend.new()
	fake.tokens = ["slow", "slow", "slow"] as Array[String]
	fake.delay_ms = 250
	var job := _service(fake).ask("lingshou_voice", [])
	var r := await job.wait()
	assert_false(r["ok"], "too slow -> template")
	assert_true(r["reason"].begins_with("timeout"), r["reason"])
	assert_eq(r["text"], "", "partial text is not used")
	assert_eq(fake.cancelled_jobs, 1, "backend was told to stop")
	assert_true(r["total_ms"] < 600, "finished near the limit: %d ms" % r["total_ms"])


func test_disabled_never_calls_backend() -> void:
	var fake := FakeBackend.new()
	fake.tokens = ["x"] as Array[String]
	var job := _service(fake, false).ask("npc_dialog", [])
	var r := await job.wait()
	assert_false(r["ok"])
	assert_eq(r["reason"], "llm disabled")


func test_no_model_available() -> void:
	var fake := FakeBackend.new()
	fake.available = false
	var job := _service(fake).ask("rumor", [])
	var r := await job.wait()
	assert_false(r["ok"])
	assert_eq(r["reason"], "no backend available")


func test_backend_error_falls_back() -> void:
	var fake := FakeBackend.new()
	fake.tokens = ["{"] as Array[String]
	fake.fail_reason = "http 500"
	var r := await _service(fake).ask("call_translator", []).wait()
	assert_false(r["ok"])
	assert_eq(r["reason"], "http 500")


func test_all_roles_configured() -> void:
	var s := LlmService.new()
	for role in ["call_translator", "lingshou_voice", "silenced_voice", "npc_dialog", "rumor"]:
		assert_true(s.roles.has(role), role)
		assert_true(int(s.roles.get(role, {}).get("max_tokens", 0)) > 0, role + " max_tokens")
		assert_true(int(s.roles.get(role, {}).get("timeout_ms", 99999)) <= 8000, role + " timeout")
