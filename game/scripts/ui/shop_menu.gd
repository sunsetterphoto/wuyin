class_name ShopMenu
extends MenuScreen
## Shop: buy food and remedies with coins.

var stock: Array = []


static func make(items: Array) -> ShopMenu:
	var m := ShopMenu.new()
	m.stock = items
	return m


func _ready() -> void:
	_build()


func _build(note := "") -> void:
	clear_body()
	var s := GameState.current
	title_label.text = "%s   ·   %s %d" % [tr("SHOP_TITLE"), tr("UI_COINS"), s.coins]
	if note != "":
		body.add_child(UiTheme.label(note, 20, UiTheme.JADE))
	for id in stock:
		var it := GameData.item(id)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		var v := VBoxContainer.new()
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		v.add_child(UiTheme.label("%s   (%s %d)" % [tr(it["name"]), tr("UI_OWNED"), s.item_count(id)], 22))
		v.add_child(UiTheme.para(tr(it["desc"]), 17, UiTheme.MUTED))
		row.add_child(v)
		var b := UiTheme.button("%d %s" % [it["price"], tr("UI_COINS")], func():
			if s.buy(id):
				Audio.sfx("coin")
				_build(tr("SHOP_BOUGHT").format({"item": tr(it["name"])}))
			else:
				Audio.sfx("fail")
				_build(tr("SHOP_NO_MONEY")), 180)
		b.disabled = s.coins < int(it["price"])
		row.add_child(b)
		body.add_child(row)
