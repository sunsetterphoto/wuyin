extends Control
## Dev scene: measures the in-process model on the device (M0.3/M0.4 acceptance).
## Prints WUYIN_LLM lines to the log (adb logcat -s godot) and shows them on screen.
## Start from the main menu or via the autorun file (see main.gd).

const CallEval := preload("res://scripts/dev/call_eval.gd")

var _out: RichTextLabel


func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.04, 0.07)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	_out = RichTextLabel.new()
	_out.set_anchors_preset(Control.PRESET_FULL_RECT)
	_out.offset_left = 24
	_out.offset_top = 24
	_out.scroll_following = true
	_out.add_theme_font_size_override("normal_font_size", 18)
	add_child(_out)
	_run()


func _log(line: String) -> void:
	print("WUYIN_LLM " + line)
	_out.append_text(line + "\n")


func _run() -> void:
	var standby := get_node_or_null("/root/DevStandby")
	if standby:
		standby.hold(true)
	var service := LlmService.instance()
	_log("os=%s model_available=%s backends=%s" % [OS.get_name(), service.is_model_available(),
		", ".join(service.backends.map(func(b): return b.name()))])
	var backend := service.active_backend()
	if backend == null:
		_log("no backend; template fallback only")
	else:
		var t0 := Time.get_ticks_msec()
		if backend.has_method("warm_up"):
			var ok: bool = await backend.warm_up()
			_log("warm_up ok=%s ms=%d" % [ok, Time.get_ticks_msec() - t0])
		for r in service.roles.values():
			r["timeout_ms"] = maxi(int(r["timeout_ms"]), 15000)  # measure true latency, no early fallback

	# Calls: 55 sentences, validity + intent + latency.
	var res := await CallEval.run("model", service)
	var ms: Array = res["ms"]
	ms.sort()
	for row in res["rows"]:
		if not row["intent"]:
			_log("  miss: %s -> %s %s (%s)" % [row["text"], row["move"], row["target"], row["source"]])
	_log("calls valid=%d/%d intent=%d/%d sources=%s median_ms=%d p90_ms=%d max_ms=%d" % [
		res["valid"], res["total"], res["intent_ok"], res["total"], res["by_source"],
		ms[ms.size() / 2], ms[int(ms.size() * 0.9)], ms[-1]])

	# Voices: first token and total per language.
	var u := BattleUnit.create("wawalurch", 5)
	for loc in ["de", "en", "zh_Hans", "de", "en", "zh_Hans"]:
		var first := [-1]
		var t0 := Time.get_ticks_msec()
		var r := await LingshouVoice.comment(u, "hit", {"target": "Glutfasan"}, loc, service,
			func(_p): if first[0] < 0: first[0] = Time.get_ticks_msec() - t0)
		_log("voice %s first_ms=%d total_ms=%d source=%s text=%s" % [loc, first[0], r["ms"], r["source"], r["text"]])
	_log("DONE")
	if standby:
		standby.hold(false)
