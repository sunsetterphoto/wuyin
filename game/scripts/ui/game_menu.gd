class_name GameMenu
extends MenuScreen
## Pause menu in the overworld: party, bag, wind chime and journal, options,
## saving, feedback, back to title.


func _ready() -> void:
	_main()


func _main() -> void:
	clear_body()
	title_label.text = tr("MENU_TITLE")
	var s := GameState.current
	body.add_child(UiTheme.label("%s   ·   %s %d   ·   %s %s   ·   %s" % [s.player["name"], tr("UI_COINS"), s.coins,
		tr("UI_BELLS"), "🔔".repeat(s.bells), _time(s.play_seconds)], 20, UiTheme.MUTED))
	var q: String = World.instance().current_quest() if World.instance() else s.flag("quest", "")
	if q != "":
		body.add_child(UiTheme.para("◆ " + tr(q), 22))
	var main_q: String = s.flag("quest", "")
	if main_q != "" and main_q != q:
		body.add_child(UiTheme.para("◇ " + tr(main_q), 18, UiTheme.MUTED))
	# Open tasks in the other regions (Act 2 and 3 can be played in any order).
	var rq: Dictionary = s.flag("rquest", {})
	for reg in rq:
		if rq[reg] != q:
			body.add_child(UiTheme.para("◇ %s: %s" % [tr("REGION_" + String(reg).to_upper()), tr(rq[reg])], 17, UiTheme.MUTED))
	if s.flag("prologue_done"):
		body.add_child(UiTheme.label("%s · %02d:%02d   ·   %s %d/5" % [tr("UI_DAY_N").format({"n": s.day}), s.minute / 60, s.minute % 60,
			tr("UI_TONES"), s.tones_count()], 18, UiTheme.MUTED))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	body.add_child(grid)
	for entry in [["MENU_PARTY", _party], ["MENU_BAG", _bag], ["MENU_MAP", _map], ["MENU_LEXICON", _lexicon], ["MENU_OPTIONS", _options],
			["MENU_SAVE", _save], ["MENU_FEEDBACK", _feedback], ["MENU_TO_TITLE", _to_title]]:
		var b := UiTheme.button(tr(entry[0]), entry[1])
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0, 80)
		grid.add_child(b)


static func _time(seconds: float) -> String:
	var m := int(seconds / 60.0)
	return "%d:%02d h" % [m / 60, m % 60]


func _party() -> void:
	clear_body()
	title_label.text = tr("MENU_PARTY")
	var s := GameState.current
	for i in s.party.size():
		var extra: Array[Control] = []
		if i > 0:
			extra.append(UiTheme.button("▲", func(): _move_up(i), 72))
		extra.append(UiTheme.button("…", func(): _details(s.party[i]), 72))
		body.add_child(MenuScreen.lingshou_row(s.party[i], extra))
	if not s.farm.is_empty():
		body.add_child(UiTheme.para(tr("MENU_FARM_NOTE").format({"n": s.farm.size()}), 18, UiTheme.MUTED))
	body.add_child(UiTheme.button(tr("MENU_BACK"), _main))


## One companion: description and the four active moves out of all it knows.
func _details(rec: Dictionary) -> void:
	clear_body()
	var u := BattleUnit.from_record(rec)
	title_label.text = tr(u.name_key())
	body.add_child(MenuScreen.lingshou_row(rec))
	body.add_child(UiTheme.para(tr(u.species.get("desc", "")), 19))
	body.add_child(UiTheme.label("%s %s" % ["♀" if u.sex == "f" else ("♂" if u.sex == "m" else ""), tr("LEX_MOVES_NOTE")], 18, UiTheme.MUTED))
	for mid in u.known:
		var mv := GameData.move(mid)
		var active := mid in u.moves
		var b := UiTheme.button("%s %s  [%s]" % ["●" if active else "○", tr(mv["name"]), BattleText.element_name(mv["element"])], func():
			if active and u.moves.size() > 1:
				u.moves.erase(mid)
			elif not active and u.moves.size() < GameData.MAX_MOVES:
				u.moves.append(mid)
			else:
				Audio.sfx("fail")
				return
			rec["moves"] = u.moves.duplicate()
			rec["known"] = u.known.duplicate()
			Audio.sfx("select")
			_details(rec))
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.add_theme_color_override("font_color", Sprites.element_color(mv["element"]).lightened(0.35) if active else UiTheme.MUTED)
		body.add_child(b)
	body.add_child(UiTheme.button(tr("MENU_BACK"), _party))


## The bestiary (GDD "Lexikon"): every Lingshou seen so far, with drawing and entry.
func _lexicon() -> void:
	clear_body()
	var s := GameState.current
	var ids := GameData.lingshou_ids()
	ids.sort_custom(func(a, b): return _lex_order(a) < _lex_order(b))
	title_label.text = "%s   ·   %d/%d" % [tr("MENU_LEXICON"), ids.filter(func(i): return i in s.seen).size(), ids.size()]
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	body.add_child(grid)
	for id in ids:
		var seen: bool = id in s.seen
		var sp := GameData.lingshou(id)
		var b := Button.new()
		b.custom_minimum_size = Vector2(0, 150)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.text = tr(sp["name"]) if seen else "???"
		b.icon = Sprites.lingshou(id)
		b.expand_icon = true
		b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		b.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		b.add_theme_constant_override("icon_max_width", 96)
		b.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		if not seen:
			b.modulate = Color(0, 0, 0, 0.8)
			b.disabled = true
		else:
			b.pressed.connect(func(): _lex_entry(id))
		grid.add_child(b)
	body.add_child(UiTheme.button(tr("MENU_BACK"), _main))


static func _lex_order(id: String) -> String:
	var sp := GameData.lingshou(id)
	var group := 3 if sp.get("hybrid", false) else (2 if sp.get("guardian", false) or sp["alignment"] == "nian" else 1)
	return "%d%s%s" % [group, ["wood", "fire", "earth", "metal", "water"].find(sp["element"]), id]


func _lex_entry(id: String) -> void:
	clear_body()
	var sp := GameData.lingshou(id)
	title_label.text = tr(sp["name"])
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 20)
	body.add_child(h)
	var pic := TextureRect.new()
	pic.texture = Sprites.lingshou(id)
	pic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pic.custom_minimum_size = Vector2(220, 220)
	h.add_child(pic)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	v.add_child(UiTheme.label("%s · %s · %s" % [tr(sp["animal"]), BattleText.element_name(sp["element"]),
		tr("TEMPERAMENT_" + String(sp["temperaments"][0]).to_upper())], 20, UiTheme.MUTED))
	v.add_child(UiTheme.para(tr(sp.get("desc", "")), 21))
	var where: Array[String] = []
	for m in MapData.all_ids():
		var md := MapData.load_map(m)
		var found: bool = md.def.get("encounters", {}).get("table", []).any(func(e): return e["species"] == id) \
			or md.def.get("lingshou", []).any(func(e): return e.get("species", "") == id)
		if found:
			where.append(tr(md.name_key()))
	if not where.is_empty():
		v.add_child(UiTheme.para(tr("LEX_WHERE") + " " + ", ".join(where), 18, UiTheme.MUTED))
	elif sp.get("hybrid", false):
		v.add_child(UiTheme.para(tr("LEX_BRED"), 18, UiTheme.MUTED))
	body.add_child(UiTheme.button(tr("MENU_BACK"), _lexicon))


func _map() -> void:
	var m := WorldMap.new()
	add_child(m)
	await m.closed
	m.queue_free()
	_main()


func _move_up(i: int) -> void:
	var s := GameState.current
	var a: Dictionary = s.party[i]
	s.party[i] = s.party[i - 1]
	s.party[i - 1] = a
	_party()


func _bag() -> void:
	clear_body()
	title_label.text = tr("MENU_BAG")
	var s := GameState.current
	if s.items.is_empty():
		body.add_child(UiTheme.label(tr("BATTLE_BAG_EMPTY")))
	for id in s.items.keys():
		var it := GameData.item(id)
		var row := HBoxContainer.new()
		var v := VBoxContainer.new()
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		v.add_child(UiTheme.label("%s ×%d" % [tr(it["name"]), s.item_count(id)], 22))
		v.add_child(UiTheme.para(tr(it["desc"]), 17, UiTheme.MUTED))
		row.add_child(v)
		if it["kind"] in ["heal", "revive"]:
			row.add_child(UiTheme.button(tr("UI_USE"), func(): _use(id), 140))
		body.add_child(row)
	body.add_child(UiTheme.button(tr("MENU_BACK"), _main))


func _use(id: String) -> void:
	clear_body()
	title_label.text = tr(GameData.item(id)["name"])
	var s := GameState.current
	var it := GameData.item(id)
	for rec in s.party:
		var u := BattleUnit.from_record(rec)
		var ok: bool = (it["kind"] == "heal" and u.hp > 0 and u.hp < u.max_hp) or (it["kind"] == "revive" and u.hp == 0)
		var b := UiTheme.button("%s  %d/%d" % [tr(u.name_key()), u.hp, u.max_hp], func():
			if s.take_item(id):
				if it["kind"] == "heal":
					rec["hp"] = mini(u.max_hp, u.hp + ceili(u.max_hp * float(it["heal_pct"]) / 100.0))
				else:
					rec["hp"] = ceili(u.max_hp * float(it["heal_pct"]) / 100.0)
				Audio.sfx("heal")
			_bag())
		b.disabled = not ok
		body.add_child(b)
	body.add_child(UiTheme.button(tr("MENU_BACK"), _bag))


func _options() -> void:
	var o := OptionsMenu.new()
	add_child(o)
	await o.closed
	o.queue_free()
	_main()


func _save() -> void:
	var ok := GameState.current.save_game(World.AUTOSAVE_SLOT)
	Audio.sfx("coin" if ok else "fail")
	_main()
	body.add_child(UiTheme.label(tr("MSG_SAVED") if ok else tr("MSG_SAVE_FAILED"), 22, UiTheme.JADE))


func _feedback() -> void:
	var f := FeedbackForm.new()
	f.context = "menu"
	add_child(f)
	await f.closed
	f.queue_free()
	_main()


func _to_title() -> void:
	GameState.current.save_game(World.AUTOSAVE_SLOT)
	closed.emit()
	get_tree().change_scene_to_file("res://scenes/main.tscn")
