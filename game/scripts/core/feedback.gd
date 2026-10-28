class_name Feedback
extends RefCounted
## Playtest feedback on the device: ratings with free text, and reports of
## model-written text (Google Play requires a report function for AI content).
## Both are JSON lines in user:// and get pulled with tools/pull_feedback.sh.

const FEEDBACK_PATH := "user://feedback.jsonl"
const REPORTS_PATH := "user://reports.jsonl"
## Rated areas (translation keys FB_<AREA>).
const AREAS: Array[String] = ["overall", "calls", "taming", "battles", "story", "graphics", "music", "controls", "speed"]


static func report(data: Dictionary) -> void:
	_append(REPORTS_PATH, data)
	PlaytestLog.record("report", data)


## ratings: area -> 1..5 (0 = not rated); text: free comment; context: where it was given.
static func submit(ratings: Dictionary, text: String, context: String) -> void:
	var s := GameState.current
	_append(FEEDBACK_PATH, {"ratings": ratings, "text": text, "context": context,
		"map": s.map if s else "", "play_minutes": roundi(s.play_seconds / 60.0) if s else 0,
		"flags": s.flags.keys() if s else [], "llm": LlmService.instance().is_model_available(),
		"version": ProjectSettings.get_setting("application/config/version")})


static func read_all(path := FEEDBACK_PATH) -> Array:
	var out := []
	if not FileAccess.file_exists(path):
		return out
	for line in FileAccess.get_file_as_string(path).split("\n", false):
		var json := JSON.new()
		if json.parse(line) == OK:
			out.append(json.data)
	return out


static func _append(path: String, data: Dictionary) -> void:
	var entry := data.duplicate()
	entry["time"] = Time.get_datetime_string_from_system()
	var f := FileAccess.open(path, FileAccess.READ_WRITE if FileAccess.file_exists(path) else FileAccess.WRITE)
	if f == null:
		return
	f.seek_end()
	f.store_line(JSON.stringify(entry))
