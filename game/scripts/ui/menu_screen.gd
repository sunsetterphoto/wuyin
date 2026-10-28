class_name MenuScreen
extends Control
## Base for full-screen menus over the game: dim background, a framed panel
## with title, scrolling body and a close button. Subclasses fill `body`.

signal closed

var body: VBoxContainer
var title_label: Label
var _panel: PanelContainer


func _init() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = UiTheme.get_theme()
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	_panel = PanelContainer.new()
	_panel.set_anchor(SIDE_LEFT, 0.12, true)
	_panel.set_anchor(SIDE_RIGHT, 0.88, true)
	_panel.set_anchor(SIDE_TOP, 0.06, true)
	_panel.set_anchor(SIDE_BOTTOM, 0.94, true)
	add_child(_panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	_panel.add_child(v)
	var top := HBoxContainer.new()
	v.add_child(top)
	title_label = UiTheme.label("", 30, UiTheme.GOLD)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(title_label)
	top.add_child(UiTheme.button("✕", close, 72))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(scroll)
	body = VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 10)
	scroll.add_child(body)


func close() -> void:
	Audio.sfx("back")
	closed.emit()


func clear_body() -> void:
	for c in body.get_children():
		c.queue_free()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST and is_visible_in_tree():
		close()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("menu") or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close()


## A row of a Lingshou: sprite, name, level, element, HP bar, bond.
static func lingshou_row(rec: Dictionary, extra: Array[Control] = []) -> Control:
	var u := BattleUnit.from_record(rec)
	var row := PanelContainer.new()
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 14)
	row.add_child(h)
	var icon := TextureRect.new()
	icon.texture = Sprites.lingshou(rec["species"])
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(96, 96)
	h.add_child(icon)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	var sp := u.species
	v.add_child(UiTheme.label("%s   %s   %s · %s" % [TranslationServer.translate(sp["name"]),
		TranslationServer.translate("BATTLE_LEVEL").format({"level": u.level}), BattleText.element_name(u.element()),
		TranslationServer.translate("TEMPERAMENT_" + String(sp["temperaments"][0]).to_upper())], 22))
	var bar := UiTheme.bar(UiTheme.JADE if u.hp > 0 else UiTheme.VERMILION, 14)
	bar.max_value = u.max_hp
	bar.value = u.hp
	v.add_child(bar)
	v.add_child(UiTheme.label("%s %d/%d   %s %d   %s %d/%d" % [TranslationServer.translate("UI_HP"), u.hp, u.max_hp,
		TranslationServer.translate("UI_BOND"), u.bond, TranslationServer.translate("UI_XP"), u.xp,
		BattleUnit.xp_to_next(u.level)], 17, UiTheme.MUTED))
	for c in extra:
		h.add_child(c)
	return row
