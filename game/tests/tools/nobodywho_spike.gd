extends SceneTree
## Spike: NobodyWho in-process LLM. Checks grammar per request, streaming,
## stopping, and latency.
##   godot --headless --path game -s res://tests/tools/nobodywho_spike.gd -- <model.gguf>


func _initialize() -> void:
	_run()


## NobodyWho returns Signals or task/stream objects; turn any of them into a value.
func _resolve(x):
	if x is Signal:
		return await x
	if x is Object and x.has_method("completed"):
		return await _resolve(x.completed())
	return x


func _t() -> int:
	return Time.get_ticks_msec()


func _run() -> void:
	var path: String = OS.get_cmdline_user_args()[0]
	var t0 := _t()
	var model = await _resolve(NobodyWhoModel.create(path, {}))
	print("model ready after %d ms: %s" % [_t() - t0, model])
	var chat = await _resolve(NobodyWhoChat.create(model, {"system_prompt": "You answer briefly."}))
	print("chat: ", chat, " vars: ", chat.get_template_variables())
	chat.set_template_variable("enable_thinking", false)

	# 1) streaming, free text
	chat.set_sampler_config(NobodyWhoSamplerPresets.temperature(0.7))
	t0 = _t()
	var stream = chat.ask("Say hello to a giant panda in one short sentence.")
	print("ask returned ", stream)
	var first := -1
	var parts := []
	while true:
		var tok = await _resolve(stream.next_token())
		if tok == null:
			break
		if first < 0:
			first = _t() - t0
		parts.append(tok)
	print("STREAM first=%d ms total=%d ms tokens=%d text=%s" % [first, _t() - t0, parts.size(), "".join(parts)])

	# 2) grammar A, then grammar B on the same chat
	for g in ['root ::= "{\\"stance\\":" ("\\"offensive\\"" | "\\"defensive\\"") "}"', 'root ::= ("yes" | "no")']:
		chat.reset_history()
		chat.set_sampler_config(NobodyWhoSamplerPresets.constrain_with_grammar(g))
		t0 = _t()
		var s = chat.ask("Attack now! Answer in the required format.")
		var out = await _resolve(s.completed())
		print("GRAMMAR %d ms -> %s" % [_t() - t0, out])

	# 3) stateless complete() with messages + config
	t0 = _t()
	var res = chat.complete([{"role": "system", "content": "Answer with one word."}, {"role": "user", "content": "Color of the sky?"}],
		{"sampler": NobodyWhoSamplerPresets.greedy()})
	print("complete returned ", res)
	res = await _resolve(res)
	print("COMPLETE %d ms -> %s" % [_t() - t0, res])

	# 4) stop mid-stream
	chat.reset_history()
	chat.set_sampler_config(NobodyWhoSamplerPresets.temperature(0.8))
	t0 = _t()
	var s2 = chat.ask("Write a long story about a fox.")
	var n := 0
	while true:
		var tok = await _resolve(s2.next_token())
		if tok == null:
			break
		n += 1
		if n == 5:
			chat.stop_generation()
	print("STOP after %d tokens, %d ms" % [n, _t() - t0])
	print("stats: ", chat.get_stats())
	quit()
