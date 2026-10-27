class_name LlmJob
extends RefCounted
## One request to the language model. Emits tokens while streaming and exactly
## one `finished` with the result:
##   {"ok": bool, "text": String, "source": "model"|"none", "reason": String,
##    "first_token_ms": int, "total_ms": int}
## ok = false means: use the role's template (timeout, no backend, disabled, error).

signal token(text: String)
signal finished(result: Dictionary)

var role: String
var messages: Array
var schema: Dictionary
## Optional GBNF grammar; takes precedence over `schema` (compact, enumerated output).
var grammar := ""
var max_tokens: int
var temperature: float
var timeout_ms: int

var text := ""
var done := false
var cancelled := false
var result: Dictionary = {}
## Keeps the service (and its watchdog coroutine) alive until the job is done.
var keepalive: RefCounted
var _started_ms := 0
var _first_token_ms := -1


func start_clock() -> void:
	_started_ms = Time.get_ticks_msec()


func elapsed_ms() -> int:
	return Time.get_ticks_msec() - _started_ms


func push_token(t: String) -> void:
	if done or cancelled:
		return
	if _first_token_ms < 0:
		_first_token_ms = elapsed_ms()
	text += t
	token.emit(t)


func finish(ok: bool, reason := "") -> void:
	if done:
		return
	done = true
	result = {"ok": ok, "text": text if ok else "", "source": "model" if ok else "none", "reason": reason,
		"first_token_ms": _first_token_ms, "total_ms": elapsed_ms()}
	finished.emit(result)
	keepalive = null


## Awaitable: `var r := await job.wait()`
func wait() -> Dictionary:
	if not done:
		await finished
	return result
