class_name LlmService
extends RefCounted
## Single entry point for all model calls (rules 1-3): the model only formulates
## and interprets; every role validates its output and falls back to templates.
## Returns jobs that always finish, at the latest after the role's timeout.
##
##   var job := LlmService.instance().ask("call_translator", messages, schema)
##   job.token.connect(func(t): label.text += t)
##   var r := await job.wait()
##   if not r["ok"]: use template

const ROLES_PATH := "res://data/llm/roles.json"
const SETTING_ENABLED := "wuyin/llm/enabled"

static var _instance: LlmService

var enabled := true
var backends: Array[LlmBackend] = []
var roles: Dictionary = {}
## Running jobs; a higher-priority request preempts lower ones (one model, one queue).
var _active: Array[LlmJob] = []


static func instance() -> LlmService:
	if _instance == null:
		_instance = LlmService.new()
		_instance.enabled = ProjectSettings.get_setting(SETTING_ENABLED, true)
		# In-process model first (shipping path), llama-server second (desktop development).
		if LlamaBackend.extension_loaded():
			_instance.backends.append(LlamaBackend.new())
		_instance.backends.append(HttpLlamaBackend.new(
			OS.get_environment("WUYIN_LLM_HOST") if OS.has_environment("WUYIN_LLM_HOST") else "127.0.0.1",
			int(OS.get_environment("WUYIN_LLM_PORT")) if OS.has_environment("WUYIN_LLM_PORT") else 8090))
	return _instance


## For tests: replace the singleton.
static func set_instance(service: LlmService) -> void:
	_instance = service


func _init() -> void:
	var text := FileAccess.get_file_as_string(ROLES_PATH)
	var parsed = JSON.parse_string(text)
	roles = parsed if parsed is Dictionary else {}


## Precomputes a prompt prefix in a lane (low priority; a real call preempts it).
## The system message is what gets cached; the user message is a throwaway.
func prefill(lane: String, system_text: String) -> LlmJob:
	return ask("prefill", [{"role": "system", "content": system_text}, {"role": "user", "content": "ok"}], {}, "", lane)


## Loads the in-process model in the background so the first call is fast.
func warm_up() -> void:
	for b in backends:
		if b.has_method("warm_up") and b.is_available():
			b.warm_up()
			return


func role(name: String) -> Dictionary:
	assert(roles.has(name), "unknown LLM role: " + name)
	return roles[name]


func active_backend() -> LlmBackend:
	if not enabled:
		return null
	for b in backends:
		if b.is_available():
			return b
	return null


func is_model_available() -> bool:
	return active_backend() != null


func ask(role_name: String, messages: Array, schema := {}, grammar := "", lane := "") -> LlmJob:
	var cfg := role(role_name)
	var job := LlmJob.new()
	job.role = role_name
	job.messages = messages
	job.schema = schema
	job.grammar = grammar
	job.lane = lane
	job.max_tokens = int(cfg.get("max_tokens", 40))
	job.temperature = float(cfg.get("temperature", 0.5))
	job.timeout_ms = int(cfg.get("timeout_ms", 3000))
	job.keepalive = self
	job.start_clock()
	var backend := active_backend()
	if backend == null:
		_finish_deferred(job, "llm disabled" if not enabled else "no backend available")
		return job
	_preempt_below(int(cfg.get("priority", 0)), backend)
	_active.append(job)
	job.finished.connect(func(_r): _active.erase(job))
	job.set_meta("priority", int(cfg.get("priority", 0)))
	_watchdog(job, backend)
	backend.run(job)
	return job


## A call must not wait behind a chatty voice: cancel lower-priority jobs
## (they fall back to their templates).
func _preempt_below(priority: int, backend: LlmBackend) -> void:
	for other in _active.duplicate():
		if int(other.get_meta("priority", 0)) < priority and not other.done:
			backend.cancel(other)
			other.finish(false, "preempted")


func _finish_deferred(job: LlmJob, reason: String) -> void:
	# Finish on the next frame so callers can connect signals first.
	var tree := Engine.get_main_loop() as SceneTree
	await tree.process_frame
	job.finish(false, reason)


func _watchdog(job: LlmJob, backend: LlmBackend) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	await tree.create_timer(job.timeout_ms / 1000.0, true, false, true).timeout
	if not job.done:
		backend.cancel(job)
		job.finish(false, "timeout after %d ms" % job.timeout_ms)
