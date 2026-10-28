class_name BattleView
extends Control
## The battle as the player sees it in the beta: background scene, Lingshou
## sprites with small animations, info panels, a message box and the command
## panel (attacks, call, befriending, bag, switching, fleeing).
##
##   var r := await BattleView.new().run(setup, GameState.current)   # after add_child
##   r = {"outcome": "win"|"lose"|"tamed"|"freed"|"fled", "battle": Battle}

signal _done

## Automated playthroughs: the player's side picks sensible actions by itself.
static var autopilot := false
## Autopilot fights wild Lingshou instead of befriending them (grinding).
static var autopilot_fight := false
## Autopilot never talks to silenced Lingshou (playthrough towards the bitter ending).
static var autopilot_no_free := false

const PLAYER := 0
const ENEMY := 1
const BG_DIR := "res://assets/backgrounds/"
const STEP_S := 0.6
const COINS_PER_LEVEL := 4

var battle: Battle
var ai: BattleAI
var state: GameState
var setup: Dictionary

var _bg: TextureRect
var _stage: Control
var _sprites := {}  # uid -> TextureRect
var _panels := {}  # uid -> {"unit", "name", "bar", "hp", "extra", "extra_label"}
var _enemy_info: HBoxContainer
var _player_info: VBoxContainer
var _msg: RichTextLabel
var _voice: Label
var _prompt: Label
var _tabs: HBoxContainer
var _content: GridContainer
var _call_row: HBoxContainer
var _call_input: LineEdit
var _suggest: HFlowContainer
var _slot := 0
var _busy := false
var _tab := "attack"
var _skip := false
var _babble: Babble
var _talk_mode := "call"
var _voice_speaker := ""
var _voice_shown := 0  # what the text row does: "call" or "talk" (befriending)


func run(battle_setup: Dictionary, game_state: GameState) -> Dictionary:
	setup = battle_setup
	state = game_state
	var enemies: Array = setup["enemies"]
	var seed_value: int = setup.get("seed", Time.get_ticks_usec())
	battle = Battle.create(seed_value, [state.party_specs(), enemies], int(setup.get("active", 1)))
	battle.mods = setup.get("mods", {})
	ai = BattleAI.new(seed_value)
	for e in enemies:
		state.mark_seen(e["id"])
	theme = UiTheme.get_theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_babble = Babble.new()
	add_child(_babble)
	_build()
	_rebuild_stage()
	PlaytestLog.record("battle_start", {"seed": seed_value, "active": battle.active_count,
		"enemies": enemies.map(func(e): return e["id"]), "llm": LlmService.instance().is_model_available()})
	CallTranslator.prepare(battle, PLAYER)
	if _befriendable() != null:
		TameJudge.prepare()
	await get_tree().process_frame
	await _show_line(_intro_text())
	_next()
	await _done
	return {"outcome": battle.outcome, "battle": battle}


func _intro_text() -> String:
	var e := battle.unit_at(ENEMY, 0)
	if setup.has("foe"):
		return tr("BATTLE_INTRO_FOE").format({"foe": tr(EventRunner.npc(setup["foe"]).get("name", setup["foe"]))})
	if e.species.get("guardian", false):
		return tr("BATTLE_INTRO_GUARDIAN").format({"name": tr(e.name_key())})
	if e.role == "silenced":
		return tr("BATTLE_INTRO_SILENCED").format({"name": tr(e.name_key())})
	if e.species.get("alignment") == "shadow_moth":
		return tr("BATTLE_INTRO_MOTH").format({"name": tr(e.name_key())})
	return tr("BATTLE_INTRO_WILD").format({"name": tr(e.name_key())})


# --- layout ------------------------------------------------------------------

func _build() -> void:
	var back := ColorRect.new()
	back.color = Color("1a1620")
	back.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(back)
	_bg = TextureRect.new()
	_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var path := BG_DIR + String(setup.get("bg", "river")) + ".png"
	if ResourceLoader.exists(path):
		_bg.texture = load(path)
	else:
		var g := Gradient.new()
		g.colors = [Color("6a8fb0"), Color("3f7232")]
		var gt := GradientTexture2D.new()
		gt.gradient = g
		gt.fill_from = Vector2(0, 0)
		gt.fill_to = Vector2(0, 1)
		_bg.texture = gt
	add_child(_bg)
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.15)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	_stage = Control.new()
	_stage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_stage)
	# Opponents: one row at the top; own Lingshou: compact rows above the message box.
	_enemy_info = HBoxContainer.new()
	_enemy_info.position = Vector2(24, 16)
	_enemy_info.add_theme_constant_override("separation", 12)
	add_child(_enemy_info)

	var bottom := HBoxContainer.new()
	bottom.set_anchor(SIDE_TOP, 0.62, true)
	bottom.set_anchor(SIDE_BOTTOM, 1.0, true)
	bottom.set_anchor(SIDE_RIGHT, 1.0, true)
	bottom.offset_left = 16
	bottom.offset_right = -16
	bottom.offset_bottom = -12
	bottom.add_theme_constant_override("separation", 12)
	add_child(bottom)
	var left := PanelContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_stretch_ratio = 0.8
	left.mouse_filter = Control.MOUSE_FILTER_STOP
	left.gui_input.connect(func(ev): if ev is InputEventScreenTouch or (ev is InputEventMouseButton and ev.pressed): _skip = true)
	bottom.add_child(left)
	var lv := VBoxContainer.new()
	left.add_child(lv)
	_player_info = VBoxContainer.new()
	_player_info.add_theme_constant_override("separation", 4)
	lv.add_child(_player_info)
	_voice = UiTheme.label("", 22, Color(0.95, 0.85, 0.55))
	_voice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lv.add_child(_voice)
	_msg = RichTextLabel.new()
	_msg.bbcode_enabled = true
	_msg.scroll_following = true
	_msg.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_msg.add_theme_font_size_override("normal_font_size", 22)
	_msg.mouse_filter = Control.MOUSE_FILTER_PASS
	lv.add_child(_msg)

	var right := PanelContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom.add_child(right)
	var rv := VBoxContainer.new()
	rv.add_theme_constant_override("separation", 8)
	right.add_child(rv)
	_prompt = UiTheme.label("", 22, UiTheme.GOLD)
	rv.add_child(_prompt)
	_tabs = HBoxContainer.new()
	_tabs.add_theme_constant_override("separation", 6)
	rv.add_child(_tabs)
	_call_row = HBoxContainer.new()
	rv.add_child(_call_row)
	_call_input = LineEdit.new()
	_call_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_call_input.custom_minimum_size = Vector2(0, 56)
	_call_input.text_submitted.connect(func(_t): _on_text_sent(_call_input.text))
	_call_row.add_child(_call_input)
	_call_row.add_child(UiTheme.button(tr("BATTLE_CALL_BUTTON"), func(): _on_text_sent(_call_input.text), 120))
	_suggest = HFlowContainer.new()
	_suggest.add_theme_constant_override("h_separation", 6)
	_suggest.add_theme_constant_override("v_separation", 6)
	rv.add_child(_suggest)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	rv.add_child(scroll)
	_content = GridContainer.new()
	_content.columns = 2
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_theme_constant_override("h_separation", 8)
	_content.add_theme_constant_override("v_separation", 8)
	scroll.add_child(_content)


func _rebuild_stage() -> void:
	for c in _stage.get_children():
		c.queue_free()
	for c in _enemy_info.get_children() + _player_info.get_children():
		c.queue_free()
	_sprites.clear()
	_panels.clear()
	var view := get_viewport_rect().size if is_inside_tree() else Vector2(1280, 720)
	var enemies := battle.active_units(ENEMY)
	var players := battle.active_units(PLAYER)
	for i in enemies.size():
		var u := enemies[i]
		var x: float = 0.70 if enemies.size() == 1 else [0.62, 0.84][i]
		var y: float = 0.52 if enemies.size() == 1 else [0.50, 0.55][i]
		_add_sprite(u, Vector2(view.x * x, view.y * y), false)
		_enemy_info.add_child(_make_panel(u))
	for i in players.size():
		var u := players[i]
		var x: float = 0.25 if players.size() == 1 else [0.15, 0.34][i]
		var y: float = 0.61 if players.size() == 1 else [0.62, 0.59][i]
		_add_sprite(u, Vector2(view.x * x, view.y * y), true)
		_player_info.add_child(_make_panel(u))
	_refresh()


func _add_sprite(u: BattleUnit, feet: Vector2, own: bool) -> void:
	if not u.is_alive():
		return
	var grey := u.role == "silenced" and not u.freed
	var tex := Sprites.lingshou(u.species["id"], grey)
	var s := TextureRect.new()
	s.texture = tex
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	s.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	s.flip_h = own
	var px := 4 if tex.get_width() <= 48 else 3
	s.size = Vector2(tex.get_width(), tex.get_height()) * px
	s.position = feet - Vector2(s.size.x / 2.0, s.size.y)
	s.pivot_offset = Vector2(s.size.x / 2.0, s.size.y)
	s.set_meta("home", s.position)
	if grey and tex == Sprites.lingshou(u.species["id"]):
		s.modulate = Color(0.62, 0.62, 0.7)
	var shadow := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0.3)
	sb.set_corner_radius_all(40)
	shadow.add_theme_stylebox_override("panel", sb)
	shadow.size = Vector2(s.size.x * 0.7, s.size.x * 0.12)
	shadow.position = feet - Vector2(shadow.size.x / 2.0, shadow.size.y / 2.0)
	_stage.add_child(shadow)
	_stage.add_child(s)
	_sprites[u.uid] = s
	# Idle breathing.
	var tw := s.create_tween().set_loops()
	tw.tween_property(s, "scale", Vector2(1.0, 0.97), 0.9 + randf() * 0.3).set_trans(Tween.TRANS_SINE)
	tw.tween_property(s, "scale", Vector2(1.0, 1.0), 0.9).set_trans(Tween.TRANS_SINE)


func _make_panel(u: BattleUnit) -> Control:
	if u.side == PLAYER:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		var n := UiTheme.label("", 19)
		n.custom_minimum_size = Vector2(250, 0)
		row.add_child(n)
		var b := UiTheme.bar(UiTheme.JADE, 14)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(b)
		var h := UiTheme.label("", 17, UiTheme.MUTED)
		h.custom_minimum_size = Vector2(90, 0)
		h.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(h)
		_panels[u.uid] = {"unit": u, "name": n, "bar": b, "hp": h, "extra": ProgressBar.new()}
		return row
	var box := PanelContainer.new()
	box.custom_minimum_size = Vector2(380, 0)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	box.add_child(v)
	var name_label := UiTheme.label("", 22)
	v.add_child(name_label)
	var bar := UiTheme.bar(UiTheme.JADE, 16)
	v.add_child(bar)
	var hp := UiTheme.label("", 16, UiTheme.MUTED)
	v.add_child(hp)
	var extra_label := UiTheme.label("", 16, UiTheme.GOLD)
	var extra := UiTheme.bar(UiTheme.GOLD, 10)
	if u.side == ENEMY and (u.role == "wild" or u.role == "silenced"):
		extra_label.text = tr("BATTLE_TRUST") if u.role == "wild" else tr("BATTLE_HEART")
		v.add_child(extra_label)
		v.add_child(extra)
	_panels[u.uid] = {"unit": u, "name": name_label, "bar": bar, "hp": hp, "extra": extra}
	return box


func _refresh() -> void:
	for uid in _panels:
		var p: Dictionary = _panels[uid]
		var u: BattleUnit = p["unit"]
		var st := " ".join(u.statuses.keys().map(func(s): return "[%s]" % BattleText.status_name(s)))
		if u.side == PLAYER:
			p["name"].text = "%s  %s %s" % [tr(u.name_key()), tr("BATTLE_LEVEL").format({"level": u.level}), st]
		else:
			p["name"].text = "%s  %s  %s %s" % [tr(u.name_key()), tr("BATTLE_LEVEL").format({"level": u.level}),
				BattleText.element_name(u.element()), st]
		p["bar"].max_value = u.max_hp
		create_tween().tween_property(p["bar"], "value", float(u.hp), 0.3)
		var fill: StyleBoxFlat = p["bar"].get_theme_stylebox("fill").duplicate()
		var frac := float(u.hp) / u.max_hp
		fill.bg_color = UiTheme.JADE if frac > 0.5 else (UiTheme.GOLD if frac > 0.2 else UiTheme.VERMILION)
		p["bar"].add_theme_stylebox_override("fill", fill)
		p["hp"].text = "%d / %d" % [u.hp, u.max_hp] if u.side == PLAYER else ""
		var extra: ProgressBar = p["extra"]
		extra.max_value = 100
		create_tween().tween_property(extra, "value", float(u.trust if u.role == "wild" else u.heart), 0.4)


# --- turn flow ----------------------------------------------------------------

func _next() -> void:
	_refresh()
	if battle.is_over():
		_finish()
		return
	var open := battle.open_slots(PLAYER)
	if open.is_empty():
		_hide_commands()
		ai.fill(battle, ENEMY)
		var events := battle.resolve_turn()
		await _play_events(events)
		_speak_about(events)
		_next()
		return
	_slot = open[0]
	_show_commands()
	if autopilot:
		_auto_choose.call_deferred()


func _hide_commands() -> void:
	_prompt.text = ""
	_call_row.visible = false
	_tabs.visible = false
	_clear(_suggest)
	_clear(_content)


func _show_commands() -> void:
	var u := battle.unit_at(PLAYER, _slot)
	_prompt.text = tr("BATTLE_CHOOSE_MOVE").format({"user": tr(u.name_key())})
	_tabs.visible = true
	_clear(_tabs)
	var tabs := [["attack", "BATTLE_TAB_ATTACK"], ["call", "BATTLE_TAB_CALL"]]
	var target := _befriendable()
	if target:
		tabs.append(["tame", "BATTLE_TAB_TAME" if target.role == "wild" else "BATTLE_TAB_FREE"])
	tabs.append(["bag", "BATTLE_TAB_BAG"])
	if not battle.bench(PLAYER).is_empty():
		tabs.append(["switch", "BATTLE_TAB_SWITCH"])
	if battle.can_flee():
		tabs.append(["flee", "BATTLE_TAB_FLEE"])
	if _tab not in tabs.map(func(t): return t[0]):
		_tab = "attack"
	for t in tabs:
		var b := UiTheme.button(tr(t[1]), _open_tab.bind(t[0]))
		b.custom_minimum_size = Vector2(0, 52)
		b.add_theme_font_size_override("font_size", 18)
		if t[0] == _tab:
			b.add_theme_color_override("font_color", UiTheme.GOLD)
		_tabs.add_child(b)
	_open_tab(_tab, false)


func _open_tab(tab: String, rebuild := true) -> void:
	_tab = tab
	if rebuild:
		_show_commands()
		return
	_clear(_content)
	_clear(_suggest)
	_call_row.visible = false
	var u := battle.unit_at(PLAYER, _slot)
	match tab:
		"attack":
			for mid in u.usable_moves():
				var mv := GameData.move(mid)
				var b := _cmd_button("%s\n[%s]" % [tr(mv["name"]), BattleText.element_name(mv["element"])], _on_move.bind(mid))
				b.add_theme_color_override("font_color", Sprites.element_color(mv["element"]).lightened(0.35))
		"call":
			_talk_mode = "call"
			_call_row.visible = true
			var can := battle.breath[PLAYER] > 0 and u.accepts_calls()
			_call_input.placeholder_text = tr("BATTLE_CALL_PLACEHOLDER")
			_call_input.editable = can
			_prompt.text = tr("BATTLE_BREATH").format({"n": battle.breath[PLAYER], "max": Obedience.BREATH_MAX})
			if not u.accepts_calls():
				_prompt.text += "  " + tr("BATTLE_DEAF").format({"user": tr(u.name_key())})
			if can:
				for text in CallTranslator.suggestions(CallTranslator.context(battle, PLAYER, _slot)):
					_suggest_button(text)
		"tame":
			var t := _befriendable()
			_prompt.text = tr("TEMPERAMENT_HINT_" + Taming.temperament(t).to_upper()) if t.role == "wild" else tr("TAME_HINT_SILENCED")
			_prompt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			_cmd_button(tr("BATTLE_CALM"), func(): _submit(Battle.tame_action("calm", battle.slot_of(t))))
			_cmd_button(tr("BATTLE_TALK"), _open_talk)
			if t.role == "wild":
				for id in state.items:
					if GameData.item(id).get("kind") == "food":
						_cmd_button("%s ×%d" % [tr(GameData.item(id)["name"]), state.item_count(id)], _on_feed.bind(id))
		"bag":
			var any := false
			for id in state.items:
				var it := GameData.item(id)
				if it.get("kind") in ["heal", "revive"]:
					any = true
					_cmd_button("%s ×%d" % [tr(it["name"]), state.item_count(id)], _on_item.bind(id))
				elif it.get("kind") == "festival":
					any = true
					var b := _cmd_button(tr(it["name"]), func(): _submit(Battle.scare_action(id, 0)))
					b.add_theme_color_override("font_color", UiTheme.VERMILION.lightened(0.3))
			if not any:
				_prompt.text = tr("BATTLE_BAG_EMPTY")
		"switch":
			for idx in battle.bench(PLAYER):
				var b: BattleUnit = battle.sides[PLAYER]["party"][idx]
				_cmd_button("%s  %d/%d" % [tr(b.name_key()), b.hp, b.max_hp], func(): _submit(Battle.switch_action(idx)))
		"flee":
			_cmd_button(tr("BATTLE_FLEE_CONFIRM"), func(): _submit(Battle.flee_action()))


func _open_talk() -> void:
	_talk_mode = "talk"
	_clear(_content)
	_clear(_suggest)
	_call_row.visible = true
	_call_input.editable = true
	_call_input.placeholder_text = tr("BATTLE_TALK_PLACEHOLDER")
	var t := _befriendable()
	_prompt.text = tr("BATTLE_TALK_PROMPT").format({"name": tr(t.name_key())})
	# Three suggested sentences in different tones (one fits the temperament best).
	var tones := ["soothing", "encouraging", "playful", "respectful", "praising"]
	var rng := RandomNumberGenerator.new()
	rng.seed = battle.turn * 31 + battle.seed_value
	var picked: Array = []
	while picked.size() < 3:
		var tone: String = tones[rng.randi_range(0, tones.size() - 1)]
		if tone not in picked:
			picked.append(tone)
	for tone in picked:
		_suggest_button(tr("TALK_%s_%d" % [tone.to_upper(), rng.randi_range(0, 1)]).format({"name": tr(t.name_key())}))
	_cmd_button(tr("MENU_BACK"), _show_commands)


func _cmd_button(text: String, cb: Callable) -> Button:
	var b := UiTheme.button(text, cb)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.custom_minimum_size = Vector2(0, 68)
	b.add_theme_font_size_override("font_size", 19)
	_content.add_child(b)
	return b


func _suggest_button(text: String) -> void:
	var b := UiTheme.button(text, func(): _on_text_sent(text, true))
	b.custom_minimum_size = Vector2(0, 52)
	b.add_theme_font_size_override("font_size", 17)
	_suggest.add_child(b)


func _clear(node: Node) -> void:
	for c in node.get_children():
		c.queue_free()


## The wild or silenced opponent that can be befriended right now (or null).
func _befriendable() -> BattleUnit:
	for u in battle.active_units(ENEMY):
		if u.is_alive() and (u.role == "wild" or u.role == "silenced"):
			return u
	return null


# --- commands -----------------------------------------------------------------

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
	_clear(_content)
	_clear(_suggest)
	_prompt.text = tr("BATTLE_CHOOSE_TARGET")
	for c in candidates:
		_cmd_button(tr(battle.unit_at(c.x, c.y).name_key()), _submit.bind(Battle.move_action(mid, c.x, c.y)))
	_cmd_button(tr("MENU_BACK"), _show_commands)


func _on_feed(item: String) -> void:
	if state.item_count(item) <= 0:
		return
	var t := _befriendable()
	if _submit(Battle.tame_action("feed", battle.slot_of(t), item)):
		state.take_item(item)


func _on_item(item: String) -> void:
	_clear(_content)
	_prompt.text = tr("BATTLE_CHOOSE_TARGET")
	var party: Array = battle.sides[PLAYER]["party"]
	for i in party.size():
		var u: BattleUnit = party[i]
		_cmd_button("%s  %d/%d" % [tr(u.name_key()), u.hp, u.max_hp], func():
			if _submit(Battle.item_action(item, i)):
				state.take_item(item))
	_cmd_button(tr("MENU_BACK"), _show_commands)


func _on_text_sent(text: String, suggested := false) -> void:
	text = text.strip_edges()
	if text == "" or _busy:
		return
	_busy = true
	_call_input.text = ""
	_call_input.release_focus()
	DisplayServer.virtual_keyboard_hide()
	_hide_commands()
	if _talk_mode == "talk":
		await _talk(text, suggested)
	else:
		await _call(text, suggested)
	_busy = false


func _call(text: String, suggested: bool) -> void:
	_append("[i]%s[/i]" % tr("BATTLE_CALL_HEARD").format({"text": text}))
	var addressed := CallTranslator.addressed_slot(battle, PLAYER, battle.open_slots(PLAYER), text)
	if addressed >= 0 and battle.unit_at(PLAYER, addressed).accepts_calls():
		_slot = addressed
	var ctx := CallTranslator.context(battle, PLAYER, _slot)
	var res := await CallTranslator.translate(ctx, text)
	var action: Dictionary = res["action"]
	var target := battle.unit_at(action["target_side"], action["target_slot"])
	_append("[color=#9ab]%s[/color]" % tr("BATTLE_CALL_RESULT").format({
		"move": tr(GameData.move(action["move"])["name"]), "target": tr(target.name_key()),
		"source": tr("CALL_SOURCE_MODEL") if res["source"] == "model" else tr("CALL_SOURCE_TEMPLATE"),
		"ms": res.get("ms", 0)}))
	PlaytestLog.record("command", {"kind": "call_suggested" if suggested else "call_typed", "text": text,
		"move": action["move"], "source": res["source"], "ms": res.get("ms", 0)})
	state.count("calls")
	_submit(action)


func _talk(text: String, suggested: bool) -> void:
	var t := _befriendable()
	_append("[i]%s[/i]" % tr("BATTLE_TALK_HEARD").format({"text": text}))
	var r := await TameJudge.judge(text)
	PlaytestLog.record("command", {"kind": "talk_suggested" if suggested else "talk_typed", "text": text,
		"tone": r["tone"], "source": r["source"], "ms": r["ms"]})
	_append("[color=#9ab]%s[/color]" % tr("BATTLE_TALK_TONE").format({"tone": tr("TONE_" + r["tone"].to_upper())}))
	_submit(Battle.tame_action("talk", battle.slot_of(t), "", r["tone"]))


## Returns true when the battle accepted the action.
func _submit(action: Dictionary) -> bool:
	var err := battle.submit(PLAYER, _slot, action)
	if err != "":
		_append("[color=#e88]%s[/color]" % tr("BATTLE_NOT_POSSIBLE"))
		push_warning("battle rejected action: " + err)
		_show_commands()
		return false
	_next()
	return true


## Autopilot: befriend wild ones with the tone they like, talk to silenced ones
## every other turn, otherwise fight like a sensible player.
func _auto_choose() -> void:
	var u := battle.unit_at(PLAYER, _slot)
	var t := _befriendable()
	if t and t.role == "wild" and not autopilot_fight:
		var talk: Dictionary = Taming.TALK.get(Taming.temperament(t), Taming.TALK["gentle"])
		var best := "soothing"
		for tone in talk:
			if talk[tone] > talk[best]:
				best = tone
		_submit(Battle.tame_action("talk", battle.slot_of(t), "", best))
		return
	for e in battle.active_units(ENEMY):
		for item in e.species.get("fears", []):
			if e.is_alive() and state.item_count(item) > 0 and _submit(Battle.scare_action(item, battle.slot_of(e))):
				return
	if float(u.hp) / u.max_hp < 0.35:
		for item in ["kraeutertee", "jasmintee", "reisbaellchen"]:
			if state.item_count(item) > 0 and _submit(Battle.item_action(item, battle.sides[PLAYER]["party"].find(u))):
				state.take_item(item)
				return
	var talk_turn := battle.turn % 2 == 0 if battle.active_count == 1 else _slot == 0
	if t and t.role == "silenced" and talk_turn and not autopilot_no_free:
		_submit(Battle.tame_action("talk", battle.slot_of(t), "", "soothing"))
		return
	var own := BattleAI.choose_for(battle, u)
	if own["type"] == "move" and GameData.move(own["move"])["target"] == "enemy" and t and t.role == "silenced":
		for s in battle.sides[ENEMY]["active"].size():
			var e := battle.unit_at(ENEMY, s)
			if e.is_alive() and e.role != "silenced":
				own["target_slot"] = s
	_submit(own)


# --- playback -----------------------------------------------------------------

func _play_events(events: Array[Dictionary]) -> void:
	for e in events:
		var lines := BattleText.describe(battle, e)
		match e["type"]:
			"uses":
				_lunge(e["user"])
				Audio.sfx("select")
			"damage":
				Audio.sfx("hit")
				_hit(e["target"], e["amount"], e["effectiveness"])
			"heal", "revive":
				Audio.sfx("heal")
				_float_text(e["target"], "+%d" % e["amount"], UiTheme.JADE)
			"faint", "flees":
				_faint(e["target"])
			"scared":
				Audio.sfx("hit")
				_float_text(e["target"], "!", UiTheme.VERMILION)
			"learned":
				Audio.sfx("level")
			"trust":
				Audio.sfx("trust" if e["amount"] > 0 else "fail")
				_float_text(e["target"], ("♥ +%d" % e["amount"]) if e["amount"] >= 0 else ("♥ %d" % e["amount"]),
					UiTheme.JADE if e["amount"] > 0 else UiTheme.VERMILION)
			"heart":
				Audio.sfx("heart")
				_float_text(e["target"], "♪ +%d" % e["amount"], UiTheme.GOLD)
			"tamed":
				Audio.sfx("level")
				_hop(e["target"])
			"freed":
				Audio.sfx("bell")
				var s: TextureRect = _sprites.get(e["target"])
				if s:
					var fu := battle.find_unit(e["target"])
					s.texture = Sprites.lingshou(fu.species["id"])
					s.modulate = Color(0.6, 0.6, 0.7)
					create_tween().tween_property(s, "modulate", Color(1.6, 1.6, 1.6), 0.5)
					create_tween().tween_property(s, "modulate", Color.WHITE, 1.0).set_delay(0.5)
			"switch", "send_in":
				_rebuild_stage()
			"level_up":
				Audio.sfx("level")
		_refresh()
		for line in lines:
			await _show_line(line)


func _show_line(line: String) -> void:
	_append(line)
	if autopilot:
		DialogBox.transcript.append("  [battle] " + line)
		return
	_skip = false
	var t := 0.0
	while t < STEP_S and not _skip:
		await get_tree().process_frame
		t += get_process_delta_time()


func _append(line: String) -> void:
	_msg.append_text(line + "\n")


func _lunge(uid: String) -> void:
	var s: Control = _sprites.get(uid)
	if s == null:
		return
	var home: Vector2 = s.get_meta("home")
	var dir := 1.0 if battle.find_unit(uid).side == PLAYER else -1.0
	var tw := create_tween()
	tw.tween_property(s, "position", home + Vector2(40 * dir, -10), 0.12)
	tw.tween_property(s, "position", home, 0.18)


func _hit(uid: String, amount: int, effectiveness: float) -> void:
	var s: Control = _sprites.get(uid)
	if s == null:
		return
	var home: Vector2 = s.get_meta("home")
	var tw := create_tween()
	var base_mod := s.modulate
	tw.tween_property(s, "modulate", Color(3, 3, 3), 0.05)
	tw.tween_property(s, "modulate", base_mod, 0.1)
	for i in 3:
		tw.tween_property(s, "position", home + Vector2(8 if i % 2 == 0 else -8, 0), 0.04)
	tw.tween_property(s, "position", home, 0.04)
	var c := UiTheme.TEXT if effectiveness == 1.0 else (UiTheme.GOLD if effectiveness > 1.0 else UiTheme.MUTED)
	_float_text(uid, str(amount), c)


func _faint(uid: String) -> void:
	var s: Control = _sprites.get(uid)
	if s == null:
		return
	var tw := create_tween()
	tw.tween_property(s, "modulate:a", 0.0, 0.5)
	tw.parallel().tween_property(s, "position:y", s.position.y + 30, 0.5)


func _hop(uid: String) -> void:
	var s: Control = _sprites.get(uid)
	if s == null:
		return
	var home: Vector2 = s.get_meta("home")
	var tw := create_tween()
	for i in 2:
		tw.tween_property(s, "position", home + Vector2(0, -36), 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(s, "position", home, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)


func _float_text(uid: String, text: String, color: Color) -> void:
	var s: Control = _sprites.get(uid)
	if s == null:
		return
	var l := UiTheme.label(text, 34, color)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 8)
	l.position = s.position + Vector2(s.size.x / 2.0 - 20, s.size.y * 0.25)
	_stage.add_child(l)
	var tw := create_tween()
	tw.tween_property(l, "position:y", l.position.y - 60, 0.8)
	tw.parallel().tween_property(l, "modulate:a", 0.0, 0.8).set_delay(0.3)
	tw.tween_callback(l.queue_free)


func _on_voice_partial(partial: String) -> void:
	_babble.feed(partial.substr(_voice_shown))
	_voice_shown = partial.length()
	_voice.text = "%s: %s" % [_voice_speaker, partial]


## One of the player's Lingshou comments on the most notable event of the turn.
func _speak_about(events: Array[Dictionary]) -> void:
	var pick := {}
	var priority := {"end": 6, "disobey": 5, "situation_bonus": 4, "obey": 3, "damage_taken": 2}
	var best := 0
	var last_user := ""
	for e in events:
		var kind := ""
		var uid := ""
		if e["type"] == "uses":
			last_user = e["user"]
		match e["type"]:
			"end":
				if e["winner"] == PLAYER and not battle.active_units(PLAYER).is_empty():
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
	_babble.set_speaker(u)
	var facts := {"target": BattleText.unit_name(battle, pick["attacker"]) if pick["attacker"] != "" else "", "call": ""}
	_voice_speaker = speaker
	_voice_shown = 0
	# A method callable (not a lambda) becomes invalid when this screen is freed mid-stream.
	var r := await LingshouVoice.comment(u, pick["event"], facts, "", null, _on_voice_partial)
	if not is_inside_tree():
		return
	_voice.text = "%s: %s" % [speaker, r["text"]]


# --- end ---------------------------------------------------------------------

func _finish() -> void:
	_hide_commands()
	PlaytestLog.record("battle_end", {"outcome": battle.outcome, "turns": battle.turn})
	for u in battle.sides[ENEMY]["party"]:
		if u.freed:
			state.set_flag("freed_" + u.species["id"])
	var enemy: BattleUnit = battle.sides[ENEMY]["party"][0]
	match battle.outcome:
		"win":
			var coins := 0
			for u in battle.sides[ENEMY]["party"]:
				coins += u.level * COINS_PER_LEVEL
				if u.role == "silenced" and not u.freed:
					state.count("defeated_silenced")
			coins += int(setup.get("coins", 0))
			state.coins += coins
			Audio.play("victory")
			await _show_line(tr("BATTLE_COINS").format({"n": coins}))
		"tamed":
			state.count("tamed")
			var rec := state.add_lingshou(enemy.species["id"], enemy.level, Taming.starting_bond(enemy.trust))
			Audio.play("victory")
			await _say_as(enemy, "win")
			await _show_line(tr("MSG_JOINED" if state.in_party(rec) else "MSG_TO_FARM").format({"name": tr(enemy.name_key())}))
		"freed":
			state.count("freed")
			Audio.play("victory")
			for u in battle.sides[ENEMY]["party"]:
				if u.freed:
					await _say_as(u, "freed")
					if not u.species.get("guardian", false) and not setup.get("no_join", false):
						var rec := state.add_lingshou(u.species["id"], u.level, 30)
						await _show_line(tr("MSG_FREED_JOINS" if state.in_party(rec) else "MSG_TO_FARM").format({"name": tr(u.name_key())}))
		"fled":
			await _show_line(tr("BATTLE_FLED"))
	# Freed guardians in a battle won by exhausting the rest.
	if battle.outcome == "win":
		for u in battle.sides[ENEMY]["party"]:
			if u.freed:
				state.count("freed")
				await _say_as(u, "freed")
	var b := UiTheme.button(tr("UI_CONTINUE"), func(): _done.emit())
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.custom_minimum_size = Vector2(0, 72)
	_content.add_child(b)
	b.grab_focus.call_deferred()
	if autopilot:
		_done.emit.call_deferred()


## A Lingshou speaks with its own voice (model or template), e.g. freed or tamed.
func _say_as(u: BattleUnit, event: String) -> void:
	var speaker := tr(u.name_key())
	var was_role := u.role
	u.role = ""
	var saved := u.statuses.duplicate()
	u.statuses.clear()
	_babble.set_speaker(u)
	var ev := "win" if event == "freed" else event
	var r := await LingshouVoice.comment(u, ev, {"call": "", "target": ""})
	u.role = was_role
	u.statuses = saved
	var text: String = r["text"]
	if event == "freed" and r["source"] == "template":
		text = tr("VOICE_FREED_GENERIC")
	_voice.text = "%s: %s" % [speaker, text]
	_babble.feed(text)
	await _show_line("[color=#f2d98c]%s: %s[/color]" % [speaker, text])
	if not autopilot:
		await get_tree().create_timer(0.8).timeout
