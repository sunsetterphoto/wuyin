extends Control
## Test battle (Phase 0): HP panels, move menu, and the call (Ruf) as free
## text or tap-to-send suggestions. Grey boxes on purpose; art comes in Phase 1.

const PLAYER := 0
const ENEMY := 1
const BUTTON_HEIGHT := 72
const FONT_SIZE := 24

## Set before changing to this scene: {"active": 1|2, "parties": [[...], [...]], "seed": int}
static var setup := {}

var battle: Battle
var ai: BattleAI
var _slot := 0
var _pending_move := ""
var _panels := {}  # uid -> {"name": Label, "bar": ProgressBar, "info": Label}
var _enemy_row: HBoxContainer
var _player_row: HBoxContainer
var _log: RichTextLabel
var _prompt: Label
var _buttons: GridContainer
var _call_row: HBoxContainer
var _call_input: LineEdit
var _call_button: Button
var _breath: Label
var _suggestions: HFlowContainer
var _busy := false
var _logged_end := false
var _voice: Label
var _babble: Babble


func _ready() -> void:
	_babble = Babble.new()
	add_child(_babble)
	if setup.is_empty():
		setup = default_setup(1)
	_build_ui()
	_start()


static func default_setup(active: int) -> Dictionary:
	if active == 1:
		return {"active": 1, "parties": [
			[{"id": "bambaer", "level": 8}, {"id": "wawalurch", "level": 8}],
			[{"id": "glutfasan", "level": 8}]]}
	return {"active": 2, "parties": [
		[{"id": "bambaer", "level": 10}, {"id": "glutfasan", "level": 10}, {"id": "wawalurch", "level": 10}],
		[{"id": "rollschupp", "level": 10}, {"id": "zirpo", "level": 10}, {"id": "firnleopard", "level": 10}]]}


func _start() -> void:
	var seed_value: int = setup.get("seed", Time.get_ticks_usec())
	battle = Battle.create(seed_value, setup["parties"], setup["active"])
	_logged_end = false
	ai = BattleAI.new(seed_value)
	_log.clear()
	_append_log("Seed %d" % seed_value)
	PlaytestLog.record("battle_start", {"seed": seed_value, "active": setup["active"], "llm": LlmService.instance().is_model_available()})
	_rebuild_panels()
	_next_prompt()


# --- flow --------------------------------------------------------------------

func _next_prompt() -> void:
	_refresh_panels()
	_clear_buttons()
	_clear_suggestions()
	if battle.is_over():
		_prompt.text = ""
		_call_row.visible = false
		if not _logged_end:
			_logged_end = true
			PlaytestLog.record("battle_end", {"winner": battle.winner, "turns": battle.turn})
		_add_button(tr("BATTLE_RESTART"), _start)
		_add_button(tr("MENU_BACK"), _back)
		return
	var open := battle.open_slots(PLAYER)
	if open.is_empty():
		ai.fill(battle, ENEMY)
		var events := battle.resolve_turn()
		for e in events:
			for line in BattleText.describe(battle, e):
				_append_log(line)
		_speak_about(events)
		_rebuild_panels()
		_next_prompt()
		return
	_slot = open[0]
	var u := battle.unit_at(PLAYER, _slot)
	_prompt.text = tr("BATTLE_CHOOSE_MOVE").format({"user": tr(u.name_key())})
	for mid in u.usable_moves():
		var mv := GameData.move(mid)
		var label := "%s\n%s" % [tr(mv["name"]), BattleText.element_name(mv["element"])]
		_add_button(label, _on_move.bind(mid))
	for idx in battle.bench(PLAYER):
		var b: BattleUnit = battle.sides[PLAYER]["party"][idx]
		_add_button("⇄ %s" % tr(b.name_key()), _on_switch.bind(idx))
	_update_call_row(u)


func _update_call_row(u: BattleUnit) -> void:
	_call_row.visible = true
	var can_call := battle.breath[PLAYER] > 0 and u.accepts_calls()
	_breath.text = tr("BATTLE_BREATH").format({"n": battle.breath[PLAYER], "max": Obedience.BREATH_MAX})
	if not u.accepts_calls():
		_breath.text += "  " + tr("BATTLE_DEAF").format({"user": tr(u.name_key())})
	_call_input.editable = can_call
	_call_button.disabled = not can_call
	if can_call:
		for text in CallTranslator.suggestions(CallTranslator.context(battle, PLAYER, _slot)):
			var b := Button.new()
			b.text = text
			b.custom_minimum_size = Vector2(0, 56)
			b.add_theme_font_size_override("font_size", 18)
			b.pressed.connect(_on_call.bind(text, true))
			_suggestions.add_child(b)


func _on_call_submitted(_text := "") -> void:
	_on_call(_call_input.text)


func _on_call(text: String, suggested := false) -> void:
	text = text.strip_edges()
	if text == "" or _busy:
		return
	_busy = true
	_call_input.text = ""
	_call_input.editable = false
	_call_button.disabled = true
	_append_log("[i]%s[/i]" % tr("BATTLE_CALL_HEARD").format({"text": text}))
	# "Glutfasan, ...!" goes to Glutfasan if it still needs a command this turn.
	var addressed := CallTranslator.addressed_slot(battle, PLAYER, battle.open_slots(PLAYER), text)
	if addressed >= 0 and battle.unit_at(PLAYER, addressed).accepts_calls():
		_slot = addressed
	var ctx := CallTranslator.context(battle, PLAYER, _slot)
	var res := await CallTranslator.translate(ctx, text)
	var action: Dictionary = res["action"]
	var target := battle.unit_at(action["target_side"], action["target_slot"])
	_append_log("[color=#9ab]%s[/color]" % tr("BATTLE_CALL_RESULT").format({
		"move": tr(GameData.move(action["move"])["name"]), "target": tr(target.name_key()),
		"source": tr("CALL_SOURCE_MODEL") if res["source"] == "model" else tr("CALL_SOURCE_TEMPLATE"),
		"ms": res.get("ms", 0)}))
	PlaytestLog.record("command", {"kind": "call_suggested" if suggested else "call_typed", "text": text,
		"move": action["move"], "source": res["source"], "ms": res.get("ms", 0)})
	_busy = false
	_submit(action)


## Lets one of the player's Lingshou comment on the most notable event of the turn.
func _speak_about(events: Array[Dictionary]) -> void:
	var pick := {}
	var priority := {"end": 6, "disobey": 5, "situation_bonus": 4, "obey": 3, "damage_taken": 2, "attack": 1}
	var best := 0
	var last_user := ""
	for e in events:
		var kind := ""
		var uid := ""
		if e["type"] == "uses":
			last_user = e["user"]
		match e["type"]:
			"end":
				if e["winner"] == PLAYER:
					kind = "win"
					uid = battle.active_units(PLAYER)[0].uid
			"disobey", "situation_bonus", "obey":
				kind = {"disobey": "disobey", "situation_bonus": "bonus", "obey": "obey"}[e["type"]]
				uid = e["user"]
			"damage":
				var t := battle.find_unit(e["target"])
				if t and t.side == PLAYER and t.is_alive():
					kind = "low_hp" if float(t.hp) / t.max_hp < 0.3 else "hit"
					uid = t.uid
					e = e.duplicate()
					e["attacker"] = last_user
		if kind == "":
			continue
		var u := battle.find_unit(uid)
		if u == null or u.side != PLAYER:
			continue
		var prio: int = priority.get(e["type"] if e["type"] != "damage" else "damage_taken", 0)
		if prio > best:
			best = prio
			pick = {"unit": u, "event": kind, "attacker": e.get("attacker", "")}
	if pick.is_empty():
		return
	var u: BattleUnit = pick["unit"]
	var speaker := tr(u.name_key())
	_voice.text = "%s: …" % speaker
	var facts := {"target": BattleText.unit_name(battle, pick["attacker"]) if pick["attacker"] != "" else "", "call": ""}
	var r := await LingshouVoice.comment(u, pick["event"], facts, "", null,
		func(partial): _voice.text = "%s: %s" % [speaker, partial])
	_voice.text = "%s: %s" % [speaker, r["text"]]
	_append_log("[color=#f2d98c]%s: %s[/color]" % [speaker, r["text"]])


func _on_move(mid: String) -> void:
	PlaytestLog.record("command", {"kind": "menu", "move": mid})
	var mv := GameData.move(mid)
	var candidates: Array[Vector2i] = []
	match mv["target"]:
		"enemy":
			for s in battle.sides[ENEMY]["active"].size():
				if battle.unit_at(ENEMY, s).is_alive():
					candidates.append(Vector2i(ENEMY, s))
		"ally":
			for s in battle.sides[PLAYER]["active"].size():
				if battle.unit_at(PLAYER, s).is_alive():
					candidates.append(Vector2i(PLAYER, s))
		_:
			candidates.append(Vector2i(PLAYER, _slot))
	if candidates.size() == 1:
		_submit(Battle.move_action(mid, candidates[0].x, candidates[0].y))
		return
	_clear_buttons()
	_prompt.text = tr("BATTLE_CHOOSE_TARGET")
	for c in candidates:
		var t := battle.unit_at(c.x, c.y)
		_add_button(tr(t.name_key()), _submit.bind(Battle.move_action(mid, c.x, c.y)))
	_add_button(tr("MENU_BACK"), _next_prompt)


func _on_switch(idx: int) -> void:
	_submit(Battle.switch_action(idx))


func _submit(action: Dictionary) -> void:
	var err := battle.submit(PLAYER, _slot, action)
	if err != "":
		_append_log("[color=#e88]%s[/color]" % err)
	_next_prompt()


func _back() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")


# --- UI ----------------------------------------------------------------------

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.09, 0.07, 0.12)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 12)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	add_child(margin)
	margin.add_child(root)
	_enemy_row = HBoxContainer.new()
	_enemy_row.alignment = BoxContainer.ALIGNMENT_END
	_enemy_row.add_theme_constant_override("separation", 16)
	root.add_child(_enemy_row)
	_player_row = HBoxContainer.new()
	_player_row.add_theme_constant_override("separation", 16)
	root.add_child(_player_row)
	_voice = Label.new()
	_voice.add_theme_font_size_override("font_size", 22)
	_voice.add_theme_color_override("font_color", Color(0.95, 0.85, 0.55))
	_voice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(_voice)
	var bottom := HBoxContainer.new()
	bottom.size_flags_vertical = Control.SIZE_EXPAND_FILL
	bottom.add_theme_constant_override("separation", 16)
	root.add_child(bottom)
	_log = RichTextLabel.new()
	_log.bbcode_enabled = true
	_log.scroll_following = true
	_log.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_log.add_theme_font_size_override("normal_font_size", 20)
	bottom.add_child(_log)
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom.add_child(right)
	_prompt = Label.new()
	_prompt.add_theme_font_size_override("font_size", FONT_SIZE)
	right.add_child(_prompt)
	_call_row = HBoxContainer.new()
	right.add_child(_call_row)
	_call_input = LineEdit.new()
	_call_input.placeholder_text = tr("BATTLE_CALL_PLACEHOLDER")
	_call_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_call_input.custom_minimum_size = Vector2(0, 56)
	_call_input.add_theme_font_size_override("font_size", 20)
	_call_input.text_submitted.connect(_on_call_submitted)
	_call_row.add_child(_call_input)
	_call_button = Button.new()
	_call_button.text = tr("BATTLE_CALL_BUTTON")
	_call_button.custom_minimum_size = Vector2(120, 56)
	_call_button.add_theme_font_size_override("font_size", 20)
	_call_button.pressed.connect(_on_call_submitted)
	_call_row.add_child(_call_button)
	_breath = Label.new()
	_breath.add_theme_font_size_override("font_size", 18)
	right.add_child(_breath)
	_suggestions = HFlowContainer.new()
	_suggestions.add_theme_constant_override("h_separation", 8)
	_suggestions.add_theme_constant_override("v_separation", 8)
	right.add_child(_suggestions)
	_buttons = GridContainer.new()
	_buttons.columns = 3
	_buttons.add_theme_constant_override("h_separation", 8)
	_buttons.add_theme_constant_override("v_separation", 8)
	right.add_child(_buttons)


func _rebuild_panels() -> void:
	for row in [_enemy_row, _player_row]:
		for c in row.get_children():
			c.queue_free()
	_panels.clear()
	for u in battle.active_units(ENEMY):
		_enemy_row.add_child(_make_panel(u))
	for u in battle.active_units(PLAYER):
		_player_row.add_child(_make_panel(u))
	_refresh_panels()


func _make_panel(u: BattleUnit) -> Control:
	var box := PanelContainer.new()
	box.custom_minimum_size = Vector2(380, 0)
	var v := VBoxContainer.new()
	box.add_child(v)
	var name_label := Label.new()
	name_label.add_theme_font_size_override("font_size", FONT_SIZE)
	v.add_child(name_label)
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(0, 20)
	bar.show_percentage = false
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.45, 0.8, 0.45)
	bar.add_theme_stylebox_override("fill", fill)
	v.add_child(bar)
	var info := Label.new()
	info.add_theme_font_size_override("font_size", 18)
	v.add_child(info)
	_panels[u.uid] = {"unit": u, "name": name_label, "bar": bar, "info": info}
	return box


func _refresh_panels() -> void:
	for uid in _panels:
		var p: Dictionary = _panels[uid]
		var u: BattleUnit = p["unit"]
		p["name"].text = "%s  %s  %s" % [tr(u.name_key()), tr("BATTLE_LEVEL").format({"level": u.level}),
			BattleText.element_name(u.element())]
		p["bar"].max_value = u.max_hp
		p["bar"].value = u.hp
		var st := ", ".join(u.statuses.keys().map(func(s): return BattleText.status_name(s)))
		p["info"].text = "%d / %d  %s" % [u.hp, u.max_hp, st]


func _clear_suggestions() -> void:
	for c in _suggestions.get_children():
		c.queue_free()


func _clear_buttons() -> void:
	for c in _buttons.get_children():
		c.queue_free()


func _add_button(text: String, callback: Callable) -> void:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(200, BUTTON_HEIGHT)
	b.add_theme_font_size_override("font_size", 20)
	b.pressed.connect(callback)
	_buttons.add_child(b)


func _append_log(line: String) -> void:
	_log.append_text(line + "\n")
