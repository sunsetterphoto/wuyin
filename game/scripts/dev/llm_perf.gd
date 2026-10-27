extends Control
## Dev scene: raw NobodyWho throughput on the device. GPU (Vulkan) vs CPU,
## short vs long prompt; prints WUYIN_PERF lines with time to first token
## (≈ prompt processing) and decode rate.

const LONG_FILLER := "The spirit animals of Yunhai live in five regions: bamboo sea, misty river, rainbow ridge, singing dunes and cloud pillars. "

var _out: RichTextLabel


func _ready() -> void:
	_out = RichTextLabel.new()
	_out.set_anchors_preset(Control.PRESET_FULL_RECT)
	_out.offset_left = 24
	_out.offset_top = 24
	_out.add_theme_font_size_override("normal_font_size", 18)
	add_child(_out)
	_run()


func _log(line: String) -> void:
	print("WUYIN_PERF " + line)
	_out.append_text(line + "\n")


func _run() -> void:
	var standby := get_node_or_null("/root/DevStandby")
	if standby:
		standby.hold(true)
	# All models in user://models/perf/ (else the game model), alternating so heat drift hits all equally.
	var paths: Array[String] = []
	var dir := "user://models/perf"
	for f in DirAccess.get_files_at(dir):
		if f.ends_with(".gguf"):
			paths.append(ProjectSettings.globalize_path(dir.path_join(f)))
	if paths.is_empty():
		paths.append(ProjectSettings.globalize_path(ProjectSettings.get_setting("wuyin/llm/model_path", "user://models/wuyin.gguf")))
	var configs := []
	for threads in [4, 6]:
		for p in paths:
			configs.append({"name": "%s_t%d" % [p.get_file().get_basename(), threads], "use_gpu": false, "threads": threads, "path": p})
	_log("models=%s cores=%d" % [paths.map(func(x): return x.get_file()), OS.get_processor_count()])
	for cfg in configs:
		var path: String = cfg["path"]
		var t0 := Time.get_ticks_msec()
		var model = await NobodyWhoBackend._resolve(ClassDB.class_call_static("NobodyWhoModel", "create", path, {"use_gpu": cfg["use_gpu"]}))
		var chat_cfg := {"n_ctx": 2048, "use_gpu": cfg["use_gpu"], "template_variables": {"enable_thinking": false}}
		if cfg.has("threads"):
			chat_cfg["n_threads"] = cfg["threads"]
		var chat = await NobodyWhoBackend._resolve(ClassDB.class_call_static("NobodyWhoChat", "create", model, chat_cfg))
		_log("[%s] load_ms=%d" % [cfg["name"], Time.get_ticks_msec() - t0])
		for prompt_kind in ["short", "medium"]:
			var content := "Name one fruit." if prompt_kind == "short" else LONG_FILLER.repeat(9) + "\nName one fruit."
			var msgs := [{"role": "system", "content": "Answer in one short sentence."}, {"role": "user", "content": content}]
			var sampler = ClassDB.class_call_static("NobodyWhoSamplerPresets", "temperature", 0.0)
			var ntok = await NobodyWhoBackend._resolve(chat.tokenize(content))
			var prompt_tokens: int = ntok.size() if ntok is Array or ntok is PackedInt32Array else -1
			var t1 := Time.get_ticks_msec()
			var stream = chat.complete(msgs, {"sampler": sampler, "template_variables": {"enable_thinking": false}})
			var first := -1
			var n := 0
			while true:
				var tok = await NobodyWhoBackend._resolve(stream.next_token())
				if tok == null:
					break
				if first < 0:
					first = Time.get_ticks_msec() - t1
				n += 1
				if n >= 16:
					chat.stop_generation()
			var total := Time.get_ticks_msec() - t1
			var decode_s := maxf(0.001, (total - first) / 1000.0)
			_log("[%s] %s prompt_tokens=%d first_token_ms=%d pp_tok_s=%.1f tokens=%d decode_tok_s=%.1f total_ms=%d" % [
				cfg["name"], prompt_kind, prompt_tokens, first, prompt_tokens / maxf(0.001, first / 1000.0), n, (n - 1) / decode_s, total])
		chat = null
		model = null
		await get_tree().create_timer(1.0).timeout
	_log("DONE")
	if standby:
		standby.hold(false)
