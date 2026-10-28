class_name InnMenu
extends MenuScreen
## Inn room or the hut at home (GDD "Unterkunft"): sleep until morning (or
## rest during the prologue), travel to towns already visited, and the wind
## chime shrine to swap Lingshou between party and farm. At home also the eggs.
## Sleeping and travelling happen after the menu closes (see EventRunner).

## Towns and rest places the wind chime can carry you to (GDD "Schnellreise"), map -> spawn.
const DESTINATIONS := [["weidendorf", "home"], ["teeufer", "inn"], ["kreuzweg", "inn"], ["nebelhafen", "inn"],
	["rotfels", "inn"], ["mondquell", "inn"], ["kiefernhang", "inn"]]

var home := false


static func make(at_home: bool) -> InnMenu:
	var m := InnMenu.new()
	m.home = at_home
	return m


func _ready() -> void:
	GameState.current.flags.erase("_inn_action")
	_build()


func _build(note := "") -> void:
	clear_body()
	var s := GameState.current
	title_label.text = tr("HOME_TITLE" if home else "INN_TITLE")
	if note != "":
		body.add_child(UiTheme.label(note, 21, UiTheme.JADE))
	if s.flag("prologue_done"):
		body.add_child(UiTheme.button(tr("INN_SLEEP"), func(): _act("sleep")))
	else:
		body.add_child(UiTheme.button(tr("INN_REST"), _rest))
	if home and not s.home["eggs"].is_empty():
		body.add_child(UiTheme.label(tr("HOME_EGGS"), 22, UiTheme.GOLD))
		for egg in s.home["eggs"]:
			body.add_child(UiTheme.para(tr("HOME_EGG_ROW").format({"name": tr(GameData.lingshou(egg["species"])["name"]),
				"n": Farm.HATCH_NIGHTS - int(egg["nights"])}), 18, UiTheme.MUTED))
	if s.flag("prologue_done"):
		var row := HFlowContainer.new()
		row.add_theme_constant_override("h_separation", 8)
		row.add_theme_constant_override("v_separation", 8)
		var any := false
		for d in DESTINATIONS:
			var here: bool = World.instance() != null and World.instance().map.id == d[0]
			if (s.flag("visited_" + d[0]) or d[0] == "weidendorf") and not here:
				any = true
				row.add_child(UiTheme.button(tr("MAP_" + String(d[0]).to_upper()), func(): _act("travel:%s:%s" % [d[0], d[1]]), 200))
		if any:
			body.add_child(UiTheme.label(tr("INN_TRAVEL"), 22, UiTheme.GOLD))
			body.add_child(row)
	if not s.farm.is_empty() or s.party.size() > 1:
		body.add_child(UiTheme.label(tr("INN_SHRINE"), 24, UiTheme.GOLD))
		body.add_child(UiTheme.para(tr("INN_SHRINE_NOTE").format({"bells": s.bells}), 17, UiTheme.MUTED))
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


func _act(what: String) -> void:
	GameState.current.set_flag("_inn_action", what)
	close()


func _rest() -> void:
	var s := GameState.current
	s.heal_party()
	Audio.sfx("heal")
	if World.instance():
		s.inn = {"map": s.map, "spawn": World.instance().map.def.get("inn_spawn", "inn")}
	s.save_game(World.AUTOSAVE_SLOT)
	_build(tr("INN_RESTED"))
