class_name InnMenu
extends MenuScreen
## Inn room (GDD "Unterkunft"): rest (heal and save), and the wind chime
## shrine to swap Lingshou between party and farm.


func _ready() -> void:
	_build()


func _build(note := "") -> void:
	clear_body()
	title_label.text = tr("INN_TITLE")
	if note != "":
		body.add_child(UiTheme.label(note, 21, UiTheme.JADE))
	body.add_child(UiTheme.button(tr("INN_REST"), _rest))
	var s := GameState.current
	if not s.farm.is_empty() or s.party.size() > 1:
		body.add_child(UiTheme.label(tr("INN_SHRINE"), 24, UiTheme.GOLD))
		body.add_child(UiTheme.label(tr("INN_SHRINE_NOTE").format({"bells": s.bells}), 17, UiTheme.MUTED))
		for i in s.party.size():
			var extra: Array[Control] = []
			if s.party.size() > 1:
				extra.append(UiTheme.button(tr("INN_TO_FARM"), func(): s.move_to_farm(i); _build(), 170))
			body.add_child(MenuScreen.lingshou_row(s.party[i], extra))
		if not s.farm.is_empty():
			body.add_child(UiTheme.label(tr("INN_FARM"), 22, UiTheme.MUTED))
		for i in s.farm.size():
			var extra: Array[Control] = []
			var b := UiTheme.button(tr("INN_TO_PARTY"), func(): s.move_to_party(i); _build(), 170)
			b.disabled = s.party.size() >= s.bells
			extra.append(b)
			body.add_child(MenuScreen.lingshou_row(s.farm[i], extra))


func _rest() -> void:
	var s := GameState.current
	s.heal_party()
	Audio.sfx("heal")
	if World.instance():
		s.inn = {"map": s.map, "spawn": World.instance().map.def.get("inn_spawn", "inn")}
	s.save_game(World.AUTOSAVE_SLOT)
	_build(tr("INN_RESTED"))
