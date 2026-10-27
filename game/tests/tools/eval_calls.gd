extends SceneTree
## Prints every call sentence with the translation, for prompt tuning.
##   godot --headless --path game -s res://tests/tools/eval_calls.gd -- [model|template]

const CallEval := preload("res://tests/llm/call_eval.gd")


func _initialize() -> void:
	_run()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var mode: String = args[0] if args.size() > 0 else "model"
	var r := await CallEval.run(mode, LlmService.instance())
	for row in r["rows"]:
		print("%s %-55s -> %-16s %-9s %-10s %s" % ["  " if row["intent"] else "XX", row["text"].left(55),
			row["move"], row["target"], row["stance"], row["source"] if row["reason"] == "" else row["source"] + " (" + row["reason"] + ")"])
	var ms: Array = r["ms"]
	ms.sort()
	print("valid %d/%d  intent %d/%d  median %s ms" % [r["valid"], r["total"], r["intent_ok"], r["total"],
		ms[ms.size() / 2] if not ms.is_empty() else "-"])
	quit()
