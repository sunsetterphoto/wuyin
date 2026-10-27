extends Control
## Menu-only test battle (M0.2): HP panels, move buttons, target choice, log.
## Grey boxes on purpose; real art comes in Phase 1. The free-text call (Ruf)
## replaces/extends this menu in M0.4.

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


func _ready() -> void:
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
	ai = BattleAI.new(seed_value)
	_log.clear()
	_append_log("Seed %d" % seed_value)
	_rebuild_panels()
	_next_prompt()


# --- flow --------------------------------------------------------------------

func _next_prompt() -> void:
	_refresh_panels()
	_clear_buttons()
	if battle.is_over():
		_prompt.text = ""
		_add_button(tr("BATTLE_RESTART"), _start)
		_add_button(tr("MENU_BACK"), _back)
		return
	var open := battle.open_slots(PLAYER)
	if open.is_empty():
		ai.fill(battle, ENEMY)
		for e in battle.resolve_turn():
			for line in BattleText.describe(battle, e):
				_append_log(line)
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


func _on_move(mid: String) -> void:
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
