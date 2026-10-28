class_name NewGameMenu
extends MenuScreen
## New game: the hero's name and colours (beta part of the character editor).
## Emits `finished` with {"name", "hair", "outfit"} or {} when cancelled.

signal finished(result: Dictionary)

var _name: LineEdit
var _hair := 0
var _outfit := 0
var _preview: TextureRect


func _ready() -> void:
	title_label.text = tr("NEW_TITLE")
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 30)
	body.add_child(h)
	_preview = TextureRect.new()
	_preview.custom_minimum_size = Vector2(192, 288)
	_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	h.add_child(_preview)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 12)
	h.add_child(v)
	v.add_child(UiTheme.label(tr("NEW_NAME"), 22))
	_name = LineEdit.new()
	_name.text = tr("NEW_DEFAULT_NAME")
	_name.max_length = 12
	_name.custom_minimum_size = Vector2(0, 60)
	_name.add_theme_font_size_override("font_size", 26)
	v.add_child(_name)
	v.add_child(UiTheme.label(tr("NEW_HAIR"), 22))
	v.add_child(_swatches(Sprites.HAIR_COLORS, func(i): _hair = i; _update()))
	v.add_child(UiTheme.label(tr("NEW_OUTFIT"), 22))
	v.add_child(_swatches(Sprites.OUTFIT_COLORS, func(i): _outfit = i; _update()))
	if GameState.has_save(World.AUTOSAVE_SLOT):
		v.add_child(UiTheme.label(tr("NEW_OVERWRITE"), 18, UiTheme.VERMILION))
	var go := UiTheme.button(tr("NEW_START"), _start)
	go.add_theme_font_size_override("font_size", 26)
	v.add_child(go)
	_update()


func _swatches(colors: Array[Color], cb: Callable) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	for i in colors.size():
		var b := Button.new()
		b.custom_minimum_size = Vector2(72, 64)
		var s := StyleBoxFlat.new()
		s.bg_color = colors[i]
		s.border_color = UiTheme.GOLD
		s.set_border_width_all(2)
		s.set_corner_radius_all(6)
		b.add_theme_stylebox_override("normal", s)
		b.add_theme_stylebox_override("hover", s)
		b.add_theme_stylebox_override("pressed", s)
		b.pressed.connect(func(): Audio.sfx("select"); cb.call(i))
		row.add_child(b)
	return row


func _update() -> void:
	_preview.texture = Sprites.hero(_hair, _outfit)


func _start() -> void:
	var n := _name.text.strip_edges()
	if n == "":
		n = tr("NEW_DEFAULT_NAME")
	finished.emit({"name": n, "hair": _hair, "outfit": _outfit})


func close() -> void:
	Audio.sfx("back")
	finished.emit({})
