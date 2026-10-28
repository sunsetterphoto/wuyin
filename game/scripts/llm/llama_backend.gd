class_name LlamaBackend
extends LlmBackend
## In-process llama.cpp through our own GDExtension (addons/wuyin_llama,
## source in addons/llama). Replaced the NobodyWho plugin, which was ~3x slower
## on Android (measured on a Snapdragon 8 Gen 3) and 140 MB instead of ~9 MB.
##
## Lanes: one llama context per lane ("talk", "calls:<uid>") so prompt caches
## don't evict each other; the extension reuses the shared token prefix itself.

const SETTING_MODEL := "wuyin/llm/model_path"
const DEFAULT_MODEL := "user://models/wuyin.gguf"
const MAX_CALL_LANES := 3
const N_CTX := 2048

var model_path := ""
var _llama: Object
var _loading := false
var _load_failed := ""
var _lanes := {}  # lane -> context id
var _lane_use: Array[String] = []
var _jobs := {}  # request id -> LlmJob
var _busy_job: LlmJob


func _init(path := "") -> void:
	if path != "":
		model_path = path
	elif OS.has_environment("WUYIN_MODEL"):
		model_path = OS.get_environment("WUYIN_MODEL")
	else:
		model_path = ProjectSettings.get_setting(SETTING_MODEL, DEFAULT_MODEL)


func name() -> String:
	return "wuyin_llama (%s)" % model_path.get_file()


static func extension_loaded() -> bool:
	return ClassDB.class_exists("WuyinLlama")


func is_available() -> bool:
	return extension_loaded() and _load_failed == "" and FileAccess.file_exists(model_path)


static func threads() -> int:
	if OS.get_name() == "Android":
		# Measured on a Snapdragon 8 Gen 3: 6 threads beat 8 (efficiency cores stall the rest).
		return int(ProjectSettings.get_setting("wuyin/llm/threads_android", 6))
	return maxi(1, OS.get_processor_count() - 2)


func warm_up() -> bool:
	if _llama != null and _llama.is_loaded():
		return true
	if _loading:
		while _loading:
			await (Engine.get_main_loop() as SceneTree).process_frame
		return _load_failed == ""
	_loading = true
	_llama = ClassDB.instantiate("WuyinLlama")
	_llama.token.connect(_on_token)
	_llama.finished.connect(_on_finished)
	_llama.load(ProjectSettings.globalize_path(model_path), threads())
	var res: Array = await _llama.loaded
	if not res[0]:
		_load_failed = res[1]
	_loading = false
	return _load_failed == ""


func run(job: LlmJob) -> void:
	_generate(job)


func cancel(job: LlmJob) -> void:
	for id in _jobs:
		if _jobs[id] == job:
			_llama.cancel(id)


static func lane_for(job: LlmJob) -> String:
	if job.lane != "":
		return job.lane
	return "calls" if job.role == "call_translator" else "talk"


func _lane_ctx(lane: String) -> int:
	if _lanes.has(lane):
		_lane_use.erase(lane)
		_lane_use.append(lane)
		return _lanes[lane]
	var call_lanes := _lane_use.filter(func(l): return l.begins_with("calls"))
	if lane.begins_with("calls") and call_lanes.size() >= MAX_CALL_LANES:
		_llama.drop_context(_lanes[call_lanes[0]])
		_lanes.erase(call_lanes[0])
		_lane_use.erase(call_lanes[0])
	var ctx: int = _llama.new_context(N_CTX)
	_lanes[lane] = ctx
	_lane_use.append(lane)
	return ctx


func _generate(job: LlmJob) -> void:
	if not await warm_up():
		job.finish(false, _load_failed)
		return
	# One generation at a time; the extension's worker also serializes.
	while _busy_job != null and not _busy_job.done:
		await (Engine.get_main_loop() as SceneTree).process_frame
	if job.done:
		return
	_busy_job = job
	var temperature := job.temperature if job.grammar == "" and job.schema.is_empty() else 0.0
	var id: int = _llama.generate(_lane_ctx(lane_for(job)), job.messages, job.grammar, job.max_tokens, temperature)
	_jobs[id] = job
	while not job.done and _jobs.has(id):
		await (Engine.get_main_loop() as SceneTree).process_frame
	if job.done and _jobs.has(id):
		_llama.cancel(id)  # timed out or preempted


func _on_token(id: int, text: String) -> void:
	if _jobs.has(id):
		_jobs[id].push_token(text)


func _on_finished(id: int, ok: bool, reason: String, stats: Dictionary) -> void:
	var job: LlmJob = _jobs.get(id)
	_jobs.erase(id)
	if job == null:
		return
	if _busy_job == job:
		_busy_job = null
	job.set_meta("stats", stats)
	job.finish(ok and job.text != "", reason if reason != "" else ("" if job.text != "" else "empty output"))
