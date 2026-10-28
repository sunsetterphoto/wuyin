class_name BefriendView
extends Control
## Prologue taming without a battle (GDD: the first Lingshou are tamed by the
## player alone, as the taming tutorial): calm, feed or talk to a shy wild
## Lingshou until its trust is full. Rude words or bad luck can scare it away.
##
##   var r := await view.run("wawalurch", 4, GameState.current)   # after add_child
##   r = {"outcome": "tamed" | "fled", "trust": int}

signal _done

static var autopilot := false

const FLEE_BELOW := 0

var state: GameState
var unit: BattleUnit
var _sprite: TextureRect
var _bar: ProgressBar
var _msg: RichTextLabel
var _buttons: GridContainer
var _input_row: HBoxContainer
var _input: LineEdit
var _suggest: HFlowContainer
var _busy := false
var _rng := RandomNumberGenerator.new()
var _mood := 0.0


func run(species: String, level: int, game_state: GameState) -> Dictionary:
	state = game_state
	unit = BattleUnit.create(species, level, "befriend")
	unit.side = 1
	unit.role = "wild"
	unit.trust = Taming.START_TRUST
	_rng.seed = hash(species) + Time.get_ticks_msec()
	_mood = Obedience.roll_mood(_rng)
	state.mark_seen(species)
	theme = UiTheme.get_theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build()
	TameJudge.prepare()
	_say(tr("BEFRIEND_INTRO").format({"name": tr(unit.name_key()), "temperament": tr("TEMPERAMENT_" + Taming.temperament(unit).to_upper())}))
	_show_actions()
	if autopilot:
		_auto.call_deferred()
	await _done
	var outcome := "tamed" if unit.trust >= Taming.TRUST_FULL else "fled"
	if outcome == "tamed":
		state.count("tamed")
		state.add_lingshou(species, level, Taming.starting_bond(unit.trust))
	PlaytestLog.record("befriend", {"species": species, "outcome": outcome})
	return {"outcome": outcome, "trust": unit.trust}


func _auto() -> void:
	while unit.trust < Taming.TRUST_FULL and unit.trust >= FLEE_BELOW:
		var talk: Dictionary = Taming.TALK.get(Taming.temperament(unit), Taming.TALK["gentle"])
		var best := "soothing"
		for tone in talk:
			if talk[tone] > talk[best]:
				best = tone
		_act("talk", "", best)
		await get_tree().process_frame
	_done.emit()


func _build() -> void:
	var bg := TextureRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var path := BattleView.BG_DIR + "river.png"
	if ResourceLoader.exists(path):
		bg.texture = load(path)
	var back := ColorRect.new()
	back.color = Color("1f2a3a")
	back.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(back)
	add_child(bg)
	_sprite = TextureRect.new()
	_sprite.texture = Sprites.lingshou(unit.species["id"])
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_sprite.size = Vector2(240, 240)
	_sprite.set_anchor(SIDE_LEFT, 0.5, true)
	_sprite.set_anchor(SIDE_RIGHT, 0.5, true)
	_sprite.offset_left = -120
	_sprite.offset_top = 70
	_sprite.offset_right = 120
	_sprite.offset_bottom = 310
	add_child(_sprite)
	var top := PanelContainer.new()
	top.position = Vector2(24, 20)
	top.custom_minimum_size = Vector2(420, 0)
	add_child(top)
	var tv := VBoxContainer.new()
	top.add_child(tv)
	tv.add_child(UiTheme.label("%s · %s" % [tr(unit.name_key()), tr("TEMPERAMENT_" + Taming.temperament(unit).to_upper())], 22))
	tv.add_child(UiTheme.label(tr("BATTLE_TRUST"), 16, UiTheme.GOLD))
	_bar = UiTheme.bar(UiTheme.GOLD, 14)
	_bar.max_value = 100
	_bar.value = unit.trust
	tv.add_child(_bar)
	var bottom := HBoxContainer.new()
	bottom.set_anchor(SIDE_TOP, 0.6, true)
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
	bottom.add_child(left)
	_msg = RichTextLabel.new()
	_msg.bbcode_enabled = true
	_msg.scroll_following = true
	_msg.add_theme_font_size_override("normal_font_size", 22)
	left.add_child(_msg)
	var right := PanelContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom.add_child(right)
	var rv := VBoxContainer.new()
	rv.add_theme_constant_override("separation", 8)
	right.add_child(rv)
	_input_row = HBoxContainer.new()
	rv.add_child(_input_row)
	_input = LineEdit.new()
	_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_input.custom_minimum_size = Vector2(0, 56)
	_input.placeholder_text = tr("BATTLE_TALK_PLACEHOLDER")
	_input.text_submitted.connect(func(_t): _talk(_input.text))
	_input_row.add_child(_input)
	_input_row.add_child(UiTheme.button(tr("BATTLE_TALK"), func(): _talk(_input.text), 140))
	_suggest = HFlowContainer.new()
	_suggest.add_theme_constant_override("h_separation", 6)
	_suggest.add_theme_constant_override("v_separation", 6)
	rv.add_child(_suggest)
	_buttons = GridContainer.new()
	_buttons.columns = 2
	_buttons.add_theme_constant_override("h_separation", 8)
	_buttons.add_theme_constant_override("v_separation", 8)
	rv.add_child(_buttons)
	var tw := _sprite.create_tween().set_loops()
	tw.tween_property(_sprite, "position:y", _sprite.position.y - 6, 0.8).set_trans(Tween.TRANS_SINE)
	tw.tween_property(_sprite, "position:y", _sprite.position.y, 0.8).set_trans(Tween.TRANS_SINE)


func _say(text: String) -> void:
	_msg.append_text(text + "\n")


func _show_actions() -> void:
	for c in _buttons.get_children() + _suggest.get_children():
		c.queue_free()
	_input_row.visible = false
	var calm := UiTheme.button(tr("BATTLE_CALM"), func(): _act("calm"))
	calm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_buttons.add_child(calm)
	var talk := UiTheme.button(tr("BATTLE_TALK"), _open_talk)
	talk.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_buttons.add_child(talk)
	for id in state.items:
		if GameData.item(id).get("kind") == "food":
			var b := UiTheme.button("%s ×%d" % [tr(GameData.item(id)["name"]), state.item_count(id)], func():
				if state.take_item(id):
					_act("feed", id))
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			_buttons.add_child(b)


func _open_talk() -> void:
	for c in _buttons.get_children() + _suggest.get_children():
		c.queue_free()
	_input_row.visible = true
	var tones := ["soothing", "encouraging", "playful", "respectful", "praising"]
	tones.shuffle()
	for tone in tones.slice(0, 3):
		var text := tr("TALK_%s_%d" % [tone.to_upper(), _rng.randi_range(0, 1)]).format({"name": tr(unit.name_key())})
		var b := UiTheme.button(text, func(): _talk(text))
		b.custom_minimum_size = Vector2(0, 52)
		b.add_theme_font_size_override("font_size", 17)
		_suggest.add_child(b)
	_buttons.add_child(UiTheme.button(tr("MENU_BACK"), _show_actions))


func _talk(text: String) -> void:
	text = text.strip_edges()
	if text == "" or _busy:
		return
	_busy = true
	_input.text = ""
	_input.release_focus()
	DisplayServer.virtual_keyboard_hide()
	_say("[i]%s[/i]" % tr("BATTLE_TALK_HEARD").format({"text": text}))
	var r := await TameJudge.judge(text)
	_say("[color=#9ab]%s[/color]" % tr("BATTLE_TALK_TONE").format({"tone": tr("TONE_" + r["tone"].to_upper())}))
	PlaytestLog.record("command", {"kind": "befriend_talk", "text": text, "tone": r["tone"], "source": r["source"], "ms": r["ms"]})
	_busy = false
	_act("talk", "", r["tone"])


func _act(act: String, item := "", tone := "neutral") -> void:
	var amount := Taming.gain(unit, act, item, tone, _mood)
	unit.trust = clampi(unit.trust + amount, -20, Taming.TRUST_FULL)
	create_tween().tween_property(_bar, "value", float(maxi(0, unit.trust)), 0.4)
	match act:
		"calm":
			_say(tr("BATTLE_CALMS").format({"target": tr(unit.name_key())}))
		"feed":
			_say(tr("BATTLE_FEEDS").format({"target": tr(unit.name_key()), "item": tr(GameData.item(item)["name"])}))
	var key := "BATTLE_TRUST_UP" if amount > 0 else ("BATTLE_TRUST_DOWN" if amount < 0 else "BATTLE_TRUST_SAME")
	_say(tr(key).format({"target": tr(unit.name_key())}))
	Audio.sfx("trust" if amount > 0 else "fail")
	if unit.trust >= Taming.TRUST_FULL:
		Audio.sfx("level")
		var tw := create_tween()
		for i in 2:
			tw.tween_property(_sprite, "position:y", _sprite.position.y - 40, 0.15)
			tw.tween_property(_sprite, "position:y", _sprite.position.y, 0.15)
		_say("[color=#f2d98c]%s[/color]" % tr("BATTLE_TAMED").format({"target": tr(unit.name_key())}))
		_end()
		return
	if unit.trust < FLEE_BELOW:
		_say(tr("BEFRIEND_FLED").format({"name": tr(unit.name_key())}))
		create_tween().tween_property(_sprite, "modulate:a", 0.0, 0.6)
		_end()
		return
	_show_actions()


func _end() -> void:
	for c in _buttons.get_children() + _suggest.get_children():
		c.queue_free()
	_input_row.visible = false
	var b := UiTheme.button(tr("UI_CONTINUE"), func(): _done.emit())
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_buttons.add_child(b)
