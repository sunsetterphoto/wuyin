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
	var q: String = s.flag("quest", "")
	if q != "":
		body.add_child(UiTheme.para("◆ " + tr(q), 22))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	body.add_child(grid)
	for entry in [["MENU_PARTY", _party], ["MENU_BAG", _bag], ["MENU_OPTIONS", _options],
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
		body.add_child(MenuScreen.lingshou_row(s.party[i], extra))
	if not s.farm.is_empty():
		body.add_child(UiTheme.para(tr("MENU_FARM_NOTE").format({"n": s.farm.size()}), 18, UiTheme.MUTED))
	body.add_child(UiTheme.button(tr("MENU_BACK"), _main))


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
