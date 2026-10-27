extends "res://tests/test_case.gd"


func test_summary_counts_commands_and_latency() -> void:
	var entries := [
		{"event": "battle_start"},
		{"event": "command", "kind": "menu"},
		{"event": "command", "kind": "menu"},
		{"event": "command", "kind": "call_typed", "ms": 600, "source": "model"},
		{"event": "command", "kind": "call_suggested", "ms": 700, "source": "model"},
		{"event": "command", "kind": "call_typed", "ms": 50, "source": "template"},
		{"event": "battle_end"},
	]
	var s := PlaytestLog.summary(entries)
	assert_eq(s["kinds"], {"menu": 2, "call_typed": 2, "call_suggested": 1})
	assert_eq(s["calls"], 3)
	assert_eq(s["battles"], 1)
	assert_eq(s["call_median_ms"], 600)
	assert_almost_eq(s["template_share"], 1.0 / 3.0)


func test_record_and_read_roundtrip() -> void:
	var real := PlaytestLog.path
	PlaytestLog.path = "user://playtest_selftest.jsonl"
	DirAccess.remove_absolute(PlaytestLog.path)
	var before := PlaytestLog.read_all().size()
	PlaytestLog.record("command", {"kind": "menu", "move": "test"})
	var after := PlaytestLog.read_all()
	assert_eq(after.size(), before + 1)
	assert_eq(after[-1]["kind"], "menu")
	DirAccess.remove_absolute(PlaytestLog.path)
	PlaytestLog.path = real
