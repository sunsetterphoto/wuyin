class_name NobodyWhoBackend
extends LlmBackend
## In-process llama.cpp via the NobodyWho GDExtension (addons/nobodywho,
## EUPL-1.2). Runs on Android arm64 (Vulkan) and desktop (Metal/Vulkan/CPU).
## Uses the stateless chat.complete(messages, config) per request, so every
## role brings its own messages and grammar. The model loads lazily on first use.
##
## Model file: project setting wuyin/llm/model_path (default user://models/wuyin.gguf),
## overridable with the WUYIN_MODEL environment variable on desktop.

const SETTING_MODEL := "wuyin/llm/model_path"
const DEFAULT_MODEL := "user://models/wuyin.gguf"

var model_path := ""
var _model: Object
## Separate contexts ("lanes") so calls and chatter don't evict each other's prompt
## cache. "talk" for voices and dialog; one "calls:<uid>" lane per active Lingshou.
var _chats := {}
var _chat_cfg := {}
var _lane_use: Array[String] = []  # least recently used first
const MAX_CALL_LANES := 3
var _loading := false
var _load_failed := ""
var _busy_job: LlmJob


func _init(path := "") -> void:
	if path != "":
		model_path = path
	elif OS.has_environment("WUYIN_MODEL"):
		model_path = OS.get_environment("WUYIN_MODEL")
	else:
		model_path = ProjectSettings.get_setting(SETTING_MODEL, DEFAULT_MODEL)


func name() -> String:
	return "nobodywho (%s%s)" % [model_path.get_file(), " + mtp" if draft_path() != "" else ""]


static func extension_loaded() -> bool:
	return ClassDB.class_exists("NobodyWhoChat")


func is_available() -> bool:
	return extension_loaded() and _load_failed == "" and FileAccess.file_exists(model_path)


## Loads model and chat; safe to call early (e.g. at game start) to hide the load time.
func warm_up() -> bool:
	if not _chats.is_empty():
		return true
	if _loading:
		while _loading:
			await (Engine.get_main_loop() as SceneTree).process_frame
		return not _chats.is_empty()
	_loading = true
	var abs_path := ProjectSettings.globalize_path(model_path)
	var model_cfg := {"use_gpu": _use_gpu()}
	var chat_cfg := {"n_ctx": 2048, "use_gpu": _use_gpu(), "template_variables": {"enable_thinking": false}}
	if OS.get_name() == "Android":
		# Measured on a Snapdragon 8 Gen 3: 6 threads beat 8 (efficiency cores stall the rest) and the default.
		chat_cfg["n_threads"] = int(ProjectSettings.get_setting("wuyin/llm/threads_android", 6))
	# Optional multi-token-prediction drafter next to the model (e.g. wuyin.mtp.gguf): faster decoding.
	var draft := draft_path()
	if draft != "":
		model_cfg["draft_path"] = ProjectSettings.globalize_path(draft)
		chat_cfg["mtp"] = true
	_model = await _resolve(ClassDB.class_call_static("NobodyWhoModel", "create", abs_path, model_cfg))
	if _model == null:
		_load_failed = "model failed to load: " + abs_path
	else:
		_chat_cfg = chat_cfg
		if await _lane_chat("talk") == null:
			_load_failed = "chat failed to start"
	_loading = false
	return _load_failed == "" and not _chats.is_empty()


## Context for a lane, created on first use; the least recently used call lane
## is dropped when more than MAX_CALL_LANES exist.
func _lane_chat(lane: String):
	if _chats.has(lane):
		_lane_use.erase(lane)
		_lane_use.append(lane)
		return _chats[lane]
	var call_lanes := _lane_use.filter(func(l): return l.begins_with("calls"))
	if lane.begins_with("calls") and call_lanes.size() >= MAX_CALL_LANES:
		_chats.erase(call_lanes[0])
		_lane_use.erase(call_lanes[0])
	var chat = await _resolve(ClassDB.class_call_static("NobodyWhoChat", "create", _model, _chat_cfg))
	if chat != null:
		_chats[lane] = chat
		_lane_use.append(lane)
	return chat


## GPU (Vulkan) only where it is measured to help; ggml-vulkan on Adreno was not faster than the CPU.
static func _use_gpu() -> bool:
	return ProjectSettings.get_setting("wuyin/llm/use_gpu_android", false) if OS.get_name() == "Android" else true


func draft_path() -> String:
	var p := model_path.get_basename() + ".mtp.gguf"
	return p if FileAccess.file_exists(p) else ""


static func lane_for(job: LlmJob) -> String:
	if job.lane != "":
		return job.lane
	return "calls" if job.role == "call_translator" else "talk"


func run(job: LlmJob) -> void:
	_generate(job)


func cancel(job: LlmJob) -> void:
	if _busy_job == job and _chats.has(lane_for(job)):
		_chats[lane_for(job)].stop_generation()


func _generate(job: LlmJob) -> void:
	if not await warm_up():
		job.finish(false, _load_failed)
		return
	# One model, one generation at a time: wait for the previous job to end.
	while _busy_job != null and not _busy_job.done:
		await (Engine.get_main_loop() as SceneTree).process_frame
	if job.done:
		return
	_busy_job = job
	var chat = await _lane_chat(lane_for(job))
	if chat == null:
		_busy_job = null
		job.finish(false, "lane failed to start")
		return
	var config := {"sampler": _sampler(job), "template_variables": {"enable_thinking": false}}
	var stream = chat.complete(job.messages, config)
	var count := 0
	while true:
		var tok = await _resolve(stream.next_token())
		if tok == null or job.done:
			break
		job.push_token(str(tok))
		count += 1
		if count >= job.max_tokens:
			chat.stop_generation()
			break
	if job.done:
		# Timed out or preempted: stop so the context is free for the next request.
		chat.stop_generation()
	_busy_job = null
	job.finish(job.text != "", "" if job.text != "" else "empty output")


func _sampler(job: LlmJob) -> Object:
	if job.grammar != "":
		return ClassDB.class_call_static("NobodyWhoSamplerPresets", "constrain_with_grammar", job.grammar)
	if not job.schema.is_empty():
		return ClassDB.class_call_static("NobodyWhoSamplerPresets", "constrain_with_json_schema", JSON.stringify(job.schema))
	return ClassDB.class_call_static("NobodyWhoSamplerPresets", "temperature", job.temperature)


## NobodyWho returns Signals or stream objects; turn any of them into a value.
static func _resolve(x):
	if x is Signal:
		return await x
	if x is Object and x.has_method("completed") and not x.has_method("next_token"):
		return await _resolve(x.completed())
	return x
