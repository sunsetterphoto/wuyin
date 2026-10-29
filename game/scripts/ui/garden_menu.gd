class_name GardenMenu
extends MenuScreen
## The feed garden on the farm: plant one crop, harvest it two nights later.


func _ready() -> void:
	_build()


func _build(note := "") -> void:
	clear_body()
	var s := GameState.current
	title_label.text = tr("GARDEN_TITLE")
	if note != "":
		body.add_child(UiTheme.label(note, 20, UiTheme.JADE))
	if not Farm.garden_open(s):
		body.add_child(UiTheme.para(tr("GARDEN_CLOSED"), 19))
		return
	if Farm.garden_ready(s):
		var crop: String = s.home["garden"]["crop"]
		body.add_child(UiTheme.para(tr("GARDEN_READY").format({"item": tr(GameData.item(crop)["name"])}), 20))
		body.add_child(UiTheme.button(tr("GARDEN_HARVEST"), func():
			var n := Farm.harvest(s)
			Audio.sfx("coin")
			_build(tr("MSG_GOT_ITEM").format({"item": tr(GameData.item(crop)["name"]), "n": n}))))
		return
	if s.home.has("garden"):
		var g: Dictionary = s.home["garden"]
		body.add_child(UiTheme.para(tr("GARDEN_GROWING").format({"item": tr(GameData.item(g["crop"])["name"]),
			"n": Farm.GARDEN_NIGHTS - int(g["nights"])}), 20))
		return
	body.add_child(UiTheme.para(tr("GARDEN_PLANT_NOTE"), 18, UiTheme.MUTED))
	for crop in Farm.GARDEN_CROPS:
		var it := GameData.item(crop)
		body.add_child(UiTheme.button(tr(it["name"]), func():
			if Farm.plant(s, crop):
				Audio.sfx("heal")
				_build(tr("GARDEN_PLANTED"))))
