extends SceneTree
## Prints the playtest summary (menu vs calls, latency, template share).
##   godot --headless --path game -s res://tests/tools/playtest_summary.gd


func _initialize() -> void:
	print(JSON.stringify(PlaytestLog.summary(PlaytestLog.read_all()), "  "))
	quit()
