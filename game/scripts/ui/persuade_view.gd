class_name PersuadeView
extends Control
## Talking someone round (GDD "Reden außerhalb von Kämpfen"): the person says
## what they want, the player answers in free text or taps a suggestion. The
## model (or keywords) names the category of each sentence; the event's data
## decides how much it counts. Enough points before the tries run out = success.
##
##   var ok: bool = await view.run(spec, GameState.current)   # after add_child
## spec: {"who": npc id, "intro": KEY, "accept": {category: points}, "need": n, "tries": n,
##        "proof_flags": [...], "bribe": coins, "allow_fight": bool}

signal _done(ok: bool)

static var autopilot := false

var spec: Dictionary
var state: GameState
var _score := 0
var _tries := 0
var _msg: RichTextLabel
var _input: LineEdit
var _suggest: HFlowContainer
var _dots: Label
var _busy := false


func run(persuade_spec: Dictionary, game_state: GameState) -> bool:
	spec = persuade_spec
	state = game_state
	_tries = int(spec.get("tries", 3))
	theme = UiTheme.get_theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build()
	Persuader.prepare()
	_say("[color=#e0b04a]%s:[/color] %s" % [_who(), tr(spec.get("intro", ""))])
	_say("[color=#9ab]%s[/color]" % tr("PERSUADE_HOWTO"))
	_update_dots()
	if autopilot:
		_auto.call_deferred()
	var ok: bool = await _done
	state.count("persuaded" if ok else "persuade_failed")
	PlaytestLog.record("persuade", {"who": spec.get("who", ""), "ok": ok, "score": _score})
	return ok


func _who() -> String:
	return tr(EventRunner.npc(spec.get("who", "")).get("name", spec.get("who", "")))


func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var panel := PanelContainer.new()
	panel.set_anchor(SIDE_LEFT, 0.08, true)
	panel.set_anchor(SIDE_RIGHT, 0.92, true)
	panel.set_anchor(SIDE_TOP, 0.08, true)
	panel.set_anchor(SIDE_BOTTOM, 0.92, true)
	add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	panel.add_child(v)
	var top := HBoxContainer.new()
	v.add_child(top)
	var title := UiTheme.label(tr("PERSUADE_TITLE").format({"name": _who()}), 28, UiTheme.GOLD)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(title)
	_dots = UiTheme.label("", 24, UiTheme.JADE)
	top.add_child(_dots)
	_msg = RichTextLabel.new()
	_msg.bbcode_enabled = true
	_msg.scroll_following = true
	_msg.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_msg.add_theme_font_size_override("normal_font_size", 21)
	v.add_child(_msg)
	var row := HBoxContainer.new()
	v.add_child(row)
	_input = LineEdit.new()
	_input.placeholder_text = tr("PERSUADE_PLACEHOLDER")
	_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_input.custom_minimum_size = Vector2(0, 64)
	_input.text_submitted.connect(func(t): _send(t))
	row.add_child(_input)
	row.add_child(UiTheme.button(tr("UI_SAY"), func(): _send(_input.text), 140))
	_suggest = HFlowContainer.new()
	_suggest.add_theme_constant_override("h_separation", 8)
	_suggest.add_theme_constant_override("v_separation", 8)
	v.add_child(_suggest)
	for cat in ["logic", "compassion", "proof", "bribe", "threat"]:
		var key: String = "PERSUADE_SUGGEST_" + cat.to_upper()
		if cat == "bribe" and int(spec.get("bribe", 0)) <= 0:
			continue
		var text := tr(key).format({"coins": int(spec.get("bribe", 0))})
		var b := UiTheme.button(text, func(): _send(text))
		b.add_theme_font_size_override("font_size", 17)
		_suggest.add_child(b)
	if spec.get("allow_fight", true):
		v.add_child(UiTheme.button(tr("PERSUADE_GIVE_UP"), func(): _done.emit(false)))


func _say(t: String) -> void:
	_msg.append_text(t + "\n")


func _update_dots() -> void:
	_dots.text = "%s %s   ·   %d" % ["●".repeat(mini(_score, int(spec.get("need", 2)))),
		"○".repeat(maxi(0, int(spec.get("need", 2)) - _score)), _tries]


func _send(text: String) -> void:
	text = text.strip_edges()
	if text == "" or _busy or _tries <= 0:
		return
	_busy = true
	_input.text = ""
	_input.release_focus()
	DisplayServer.virtual_keyboard_hide()
	_say("[i]%s[/i]" % tr("BATTLE_TALK_HEARD").format({"text": text}))
	var r := await Persuader.judge(text)
	var cat: String = r["category"]
	var pts := Persuader.points(spec, cat, state)
	PlaytestLog.record("command", {"kind": "persuade", "text": text, "category": cat, "source": r["source"], "ms": r["ms"]})
	_score = maxi(0, _score + pts)
	_tries -= 1
	_say("[color=#9ab]%s[/color]" % tr("PERSUADE_CATEGORY").format({"cat": tr("PCAT_" + cat.to_upper())}))
	var react := "PERSUADE_REACT_GOOD" if pts >= 2 else ("PERSUADE_REACT_SOME" if pts == 1 else ("PERSUADE_REACT_ANGRY" if pts < 0 else "PERSUADE_REACT_NO"))
	if cat == "proof" and pts == 0:
		react = "PERSUADE_REACT_NOPROOF"
	if cat == "bribe" and pts == 0:
		react = "PERSUADE_REACT_NOBRIBE"
	_say("[color=#e0b04a]%s:[/color] %s" % [_who(), tr(spec.get("react_" + cat, react))])
	Audio.sfx("trust" if pts > 0 else "fail")
	_update_dots()
	_busy = false
	if _score >= int(spec.get("need", 2)):
		_say("[color=#7c7]%s[/color]" % tr(spec.get("won", "PERSUADE_WON")))
		await get_tree().create_timer(0.1 if autopilot else 1.6).timeout
		_done.emit(true)
	elif _tries <= 0:
		_say("[color=#e88]%s[/color]" % tr(spec.get("lost", "PERSUADE_LOST")))
		await get_tree().create_timer(0.1 if autopilot else 1.6).timeout
		_done.emit(false)


## Autopilot: answers with the best accepted category.
func _auto() -> void:
	var accept: Dictionary = spec.get("accept", {})
	var best := "compassion"
	for cat in accept:
		if int(accept[cat]) > int(accept.get(best, 0)) and (cat != "proof" or Persuader.points({"accept": accept, "proof_flags": spec.get("proof_flags", [])}, "proof", state) > 0) and cat != "bribe":
			best = cat
	while not is_queued_for_deletion() and _tries > 0 and _score < int(spec.get("need", 2)):
		await _send(tr("PERSUADE_SUGGEST_" + best.to_upper()).format({"coins": 0}))
		await get_tree().process_frame
