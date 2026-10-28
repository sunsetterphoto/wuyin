class_name PenMenu
extends MenuScreen
## One pen on the farm (GDD "Gehege"): who lives there and how content they
## are, feeding, moving Lingshou in and out, building or rebuilding the pen.

var pen := 0


static func make(index: int) -> PenMenu:
	var m := PenMenu.new()
	m.pen = index
	return m


func _ready() -> void:
	if pen < Farm.pen_count(GameState.current):
		Farm.visit(GameState.current, pen)
	_build()


func _type_name(type: String) -> String:
	return tr("PEN_" + type.to_upper())


func _build(note := "") -> void:
	clear_body()
	var s := GameState.current
	if note != "":
		body.add_child(UiTheme.label(note, 20, UiTheme.JADE))
	if pen >= Farm.pen_count(s):
		title_label.text = tr("PEN_EMPTY_TITLE")
		body.add_child(UiTheme.para(tr("PEN_BUILD_NOTE").format({"coins": Farm.PEN_COST}), 19))
		for type in Farm.PEN_TYPES:
			var b := UiTheme.button("%s (%s)" % [_type_name(type), BattleText.element_name(Farm.PEN_ELEMENT[type])], func():
				if pen == Farm.pen_count(s) and Farm.build_pen(s, type):
					Audio.sfx("coin")
					_rebuild_world()
					_build(tr("PEN_BUILT"))
				else:
					Audio.sfx("fail"))
			b.disabled = s.coins < Farm.PEN_COST or pen != Farm.pen_count(s)
			body.add_child(b)
		if pen != Farm.pen_count(s):
			body.add_child(UiTheme.para(tr("PEN_BUILD_ORDER"), 17, UiTheme.MUTED))
		return
	var type: String = s.home["pens"][pen]["type"]
	title_label.text = "%s %d · %s" % [tr("PEN_TITLE"), pen + 1, _type_name(type)]
	var res := Farm.residents(s, pen)
	if res.is_empty():
		body.add_child(UiTheme.para(tr("PEN_NOBODY"), 19, UiTheme.MUTED))
	for rec in res:
		body.add_child(_resident_row(rec))
	if res.size() == 2 and Farm.compatible(res[0], res[1]):
		body.add_child(UiTheme.para(tr("PEN_PAIR"), 18, UiTheme.GOLD))
	if res.size() < Farm.PEN_SIZE:
		var others := s.farm.filter(func(r): return int(r.get("pen", -1)) != pen)
		if not others.is_empty():
			body.add_child(UiTheme.label(tr("PEN_MOVE_IN"), 22, UiTheme.GOLD))
			for rec in others:
				var idx := s.farm.find(rec)
				var b := UiTheme.button(_short(rec), func():
					Farm.assign(s, idx, pen)
					_rebuild_world()
					_build(), 0)
				b.alignment = HORIZONTAL_ALIGNMENT_LEFT
				body.add_child(b)
	body.add_child(UiTheme.label(tr("PEN_REBUILD"), 22, UiTheme.GOLD))
	var row := HFlowContainer.new()
	row.add_theme_constant_override("h_separation", 8)
	for t in Farm.PEN_TYPES:
		if t == type:
			continue
		var b := UiTheme.button(_type_name(t), func():
			if s.coins >= 50:
				s.coins -= 50
				Farm.set_pen_type(s, pen, t)
				Audio.sfx("coin")
				_rebuild_world()
				_build()
			else:
				Audio.sfx("fail"), 180)
		b.disabled = s.coins < 50
		row.add_child(b)
	body.add_child(row)
	body.add_child(UiTheme.para(tr("PEN_REBUILD_NOTE"), 16, UiTheme.MUTED))


func _short(rec: Dictionary) -> String:
	var sp := GameData.lingshou(rec["species"])
	return "%s %s · %s · %s" % [tr(sp["name"]), "♀" if rec.get("sex", "") == "f" else "♂", BattleText.element_name(sp["element"]),
		tr("BATTLE_LEVEL").format({"level": int(rec["level"])})]


func _resident_row(rec: Dictionary) -> Control:
	var s := GameState.current
	var extra: Array[Control] = []
	var v := VBoxContainer.new()
	var happy := int(rec.get("happy", Farm.START_HAPPY))
	var bar := UiTheme.bar(UiTheme.GOLD, 12)
	bar.max_value = 100
	bar.value = happy
	bar.custom_minimum_size = Vector2(160, 12)
	v.add_child(UiTheme.label("%s %s" % ["♀" if rec.get("sex", "") == "f" else "♂", tr("PEN_HAPPY")], 16, UiTheme.MUTED))
	v.add_child(bar)
	if not Farm.fits_pen(s, rec):
		v.add_child(UiTheme.label(tr("PEN_WRONG"), 15, UiTheme.VERMILION))
	if rec.get("stage", "adult") == "young":
		v.add_child(UiTheme.label(tr("PEN_YOUNG"), 15, UiTheme.JADE))
	extra.append(v)
	var foods := s.items.keys().filter(func(id): return GameData.item(id).get("kind") == "food")
	if not foods.is_empty():
		var fb := UiTheme.button(tr("PEN_FEED"), func(): _feed_menu(rec), 150)
		extra.append(fb)
	var take := UiTheme.button(tr("INN_TO_PARTY"), func():
		s.move_to_party(s.farm.find(rec))
		_rebuild_world()
		_build(), 150)
	take.disabled = s.party.size() >= s.bells
	extra.append(take)
	return MenuScreen.lingshou_row(rec, extra)


func _feed_menu(rec: Dictionary) -> void:
	clear_body()
	var s := GameState.current
	title_label.text = tr("PEN_FEED")
	for id in s.items.keys():
		var it := GameData.item(id)
		if it.get("kind") != "food":
			continue
		var liked: bool = GameData.lingshou(rec["species"])["element"] in it.get("likes", [])
		body.add_child(UiTheme.button("%s ×%d%s" % [tr(it["name"]), s.item_count(id), "  ♥" if liked else ""], func():
			var n := Farm.feed(s, rec, id)
			Audio.sfx("trust" if n > 0 else "fail")
			_build(tr("PEN_FED").format({"name": tr(GameData.lingshou(rec["species"])["name"])}))))
	body.add_child(UiTheme.button(tr("MENU_BACK"), _build))


## Pens and their residents are part of the map: rebuild it after changes.
func _rebuild_world() -> void:
	var w := World.instance()
	if w and w.map and w.map.def.has("pens"):
		w.set_meta("rebuild_after_menu", true)
