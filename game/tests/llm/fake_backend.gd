extends LlmBackend
## Scripted backend for tests: streams `tokens` with `delay_ms` between them.

var tokens: Array[String] = []
var delay_ms := 0
var available := true
var fail_reason := ""
var cancelled_jobs := 0


func name() -> String:
	return "fake"


func is_available() -> bool:
	return available


func run(job: LlmJob) -> void:
	_play(job)


func cancel(_job: LlmJob) -> void:
	cancelled_jobs += 1


func _play(job: LlmJob) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	for t in tokens:
		if delay_ms > 0:
			await tree.create_timer(delay_ms / 1000.0, true, false, true).timeout
		else:
			await tree.process_frame
		if job.done:
			return
		job.push_token(t)
	if fail_reason != "":
		job.finish(false, fail_reason)
	else:
		job.finish(true)
