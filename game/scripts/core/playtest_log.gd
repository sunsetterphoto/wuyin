class_name PlaytestLog
extends RefCounted
## Local, offline record of how commands are given (Phase 0 question: is the
## call more fun than the menu?). One JSON object per line in user://playtest.jsonl;
## nothing leaves the device.
##
##   PlaytestLog.record("command", {"kind": "call_typed", "ms": 640, "source": "model"})

## Tests and capture tools point this elsewhere so real playtest data stays clean.
static var path := "user://playtest.jsonl"


static func record(event: String, data := {}) -> void:
	var entry := data.duplicate()
	entry["event"] = event
	entry["t"] = Time.get_unix_time_from_system()
	var f := FileAccess.open(path, FileAccess.READ_WRITE if FileAccess.file_exists(path) else FileAccess.WRITE)
	if f == null:
		return
	f.seek_end()
	f.store_line(JSON.stringify(entry))


static func read_all(from := "") -> Array:
	var p := from if from != "" else path
	var out := []
	if not FileAccess.file_exists(p):
		return out
	for line in FileAccess.get_file_as_string(p).split("\n", false):
		var e = JSON.parse_string(line)
		if e is Dictionary:
			out.append(e)
	return out


## Counts per command kind, median call latency, template share, battles played.
static func summary(entries: Array) -> Dictionary:
	var kinds := {}
	var ms: Array = []
	var templates := 0
	var calls := 0
	var battles := 0
	for e in entries:
		match e.get("event"):
			"command":
				var k: String = e.get("kind", "?")
				kinds[k] = kinds.get(k, 0) + 1
				if k.begins_with("call"):
					calls += 1
					ms.append(int(e.get("ms", 0)))
					if e.get("source") == "template":
						templates += 1
			"battle_end":
				battles += 1
	ms.sort()
	return {"kinds": kinds, "battles": battles, "calls": calls,
		"call_median_ms": ms[ms.size() / 2] if not ms.is_empty() else 0,
		"template_share": float(templates) / calls if calls > 0 else 0.0}
