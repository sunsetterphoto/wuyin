class_name CarpenterMenu
extends MenuScreen
## The carpenter in Willowdale builds the farm up from hut to estate (GDD
## "Ausbaustufen"): coins plus materials from the regions.


func _ready() -> void:
	_build()


func _build(note := "") -> void:
	clear_body()
	var s := GameState.current
	var st := Farm.stage(s)
	title_label.text = tr("CARPENTER_TITLE")
	if note != "":
		body.add_child(UiTheme.label(note, 20, UiTheme.JADE))
	body.add_child(UiTheme.para(tr("CARPENTER_NOW").format({"stage": tr(Farm.STAGES[st]["key"]), "pens": Farm.pen_slots(s),
		"built": Farm.pen_count(s)}), 20))
	if st + 1 >= Farm.STAGES.size():
		body.add_child(UiTheme.para(tr("FARM_MAX"), 19, UiTheme.GOLD))
		return
	var next: Dictionary = Farm.STAGES[st + 1]
	var need: Array[String] = ["%d %s" % [int(next.get("coins", 0)), tr("UI_COINS")]]
	for m in next.get("mats", {}):
		need.append("%d× %s (%d)" % [int(next["mats"][m]), tr(GameData.item(m)["name"]), s.item_count(m)])
	body.add_child(UiTheme.label(tr("CARPENTER_NEXT").format({"stage": tr(next["key"]), "pens": int(next["pens"])}), 22, UiTheme.GOLD))
	body.add_child(UiTheme.para(", ".join(need), 18, UiTheme.MUTED))
	var block := Farm.upgrade_block(s)
	if block != "":
		body.add_child(UiTheme.para(tr(block), 18, UiTheme.VERMILION))
	var b := UiTheme.button(tr("CARPENTER_BUILD"), func():
		if Farm.upgrade(s):
			Audio.sfx("level")
			if World.instance():
				World.instance().set_meta("rebuild_after_menu", true)
			_build(tr("CARPENTER_DONE"))
		else:
			Audio.sfx("fail"))
	b.disabled = block != ""
	body.add_child(b)
