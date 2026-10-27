extends SceneTree
## Token counts of the role prompts (needs WUYIN_MODEL for the tokenizer).


func _initialize() -> void:
	_run()


func _run() -> void:
	var model = await NobodyWhoBackend._resolve(ClassDB.class_call_static("NobodyWhoModel", "create", OS.get_environment("WUYIN_MODEL"), {}))
	var chat = await NobodyWhoBackend._resolve(ClassDB.class_call_static("NobodyWhoChat", "create", model, {}))
	var CallEval = load("res://scripts/dev/call_eval.gd")
	var b: Battle = CallEval.battle()
	var ctx := CallTranslator.context(b, 0, 1)
	var msgs := CallTranslator.messages(ctx, "Wawalurch, schütz Bambär!")
	for m in msgs:
		var toks = await NobodyWhoBackend._resolve(chat.tokenize(m["content"]))
		print("TOKENS %s %d chars=%d" % [m["role"], toks.size() if toks is Array or toks is PackedInt32Array else -1, m["content"].length()])
	var vm := LingshouVoice.messages(BattleUnit.create("wawalurch", 5), "hit", {"target": "Glutfasan"}, "de")
	for m in vm:
		var toks = await NobodyWhoBackend._resolve(chat.tokenize(m["content"]))
		print("VOICE TOKENS %s %d" % [m["role"], toks.size() if toks is Array or toks is PackedInt32Array else -1])
	quit()
