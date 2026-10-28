class_name RestaurantMenu
extends MenuScreen
## Restaurant (GDD "Städte"): regional dishes whose effect lasts until you sleep.

var dishes: Array = []


static func make(ids: Array) -> RestaurantMenu:
	var m := RestaurantMenu.new()
	m.dishes = ids
	return m


func _ready() -> void:
	_build()


func _build(note := "") -> void:
	clear_body()
	var s := GameState.current
	title_label.text = "%s   ·   %s %d" % [tr("FOOD_TITLE"), tr("UI_COINS"), s.coins]
	if note != "":
		body.add_child(UiTheme.label(note, 20, UiTheme.JADE))
	if s.buff_effect() != "":
		body.add_child(UiTheme.para(tr("FOOD_ACTIVE").format({"dish": tr(GameData.item(s.buff["id"])["name"])}), 18, UiTheme.MUTED))
	for id in dishes:
		var it := GameData.item(id)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		var v := VBoxContainer.new()
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		v.add_child(UiTheme.label(tr(it["name"]), 22))
		v.add_child(UiTheme.para(tr(it["desc"]), 17, UiTheme.MUTED))
		row.add_child(v)
		var b := UiTheme.button("%d %s" % [it["price"], tr("UI_COINS")], func(): _eat(id), 180)
		b.disabled = s.coins < int(it["price"])
		row.add_child(b)
		body.add_child(row)


func _eat(id: String) -> void:
	var s := GameState.current
	var it := GameData.item(id)
	if s.coins < int(it["price"]):
		Audio.sfx("fail")
		return
	s.coins -= int(it["price"])
	s.buff = {"id": id, "effect": it.get("effect", ""), "day": s.day}
	Audio.sfx("heal")
	_build(tr("FOOD_EATEN").format({"dish": tr(it["name"])}))
