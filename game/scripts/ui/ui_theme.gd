class_name UiTheme
extends RefCounted
## One look for every menu and box: ink-dark panels with a thin gold frame,
## large touch targets (min. 64 px at 720 p), readable font sizes.

const INK := Color("1a1620")
const PANEL := Color(0.10, 0.08, 0.13, 0.92)
const GOLD := Color("e0b04a")
const JADE := Color("5fae8a")
const VERMILION := Color("d8452f")
const TEXT := Color("f4efe6")
const MUTED := Color("a39b8b")
const BUTTON_HEIGHT := 64

static var _theme: Theme


static func get_theme() -> Theme:
	if _theme:
		return _theme
	var t := Theme.new()
	var big: bool = Settings.get_value("big_text")
	t.default_font_size = 26 if big else 22
	t.set_color("font_color", "Label", TEXT)
	t.set_color("font_color", "Button", TEXT)
	t.set_color("font_hover_color", "Button", GOLD)
	t.set_color("font_pressed_color", "Button", GOLD)
	t.set_color("font_focus_color", "Button", GOLD)
	t.set_color("font_disabled_color", "Button", MUTED.darkened(0.3))
	t.set_stylebox("panel", "PanelContainer", panel())
	t.set_stylebox("panel", "Panel", panel())
	t.set_stylebox("normal", "Button", _button(Color(0.17, 0.14, 0.21, 0.95), Color(0.5, 0.42, 0.25)))
	t.set_stylebox("hover", "Button", _button(Color(0.22, 0.18, 0.27, 0.95), GOLD))
	t.set_stylebox("pressed", "Button", _button(Color(0.28, 0.22, 0.15, 0.95), GOLD))
	t.set_stylebox("focus", "Button", _button(Color(0, 0, 0, 0), GOLD))
	t.set_stylebox("disabled", "Button", _button(Color(0.12, 0.1, 0.14, 0.8), Color(0.3, 0.27, 0.25)))
	t.set_stylebox("normal", "LineEdit", _button(Color(0.07, 0.06, 0.09, 0.95), Color(0.5, 0.42, 0.25)))
	t.set_stylebox("focus", "LineEdit", _button(Color(0.07, 0.06, 0.09, 0.95), GOLD))
	t.set_color("font_color", "LineEdit", TEXT)
	t.set_stylebox("background", "ProgressBar", _bar(Color(0.05, 0.04, 0.07)))
	t.set_stylebox("fill", "ProgressBar", _bar(JADE))
	t.set_color("default_color", "RichTextLabel", TEXT)
	_theme = t
	return t


static func reset() -> void:
	_theme = null


static func panel(alpha := 0.92) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(PANEL, alpha)
	s.border_color = GOLD.darkened(0.25)
	s.set_border_width_all(2)
	s.set_corner_radius_all(6)
	s.set_content_margin_all(14)
	return s


static func _button(bg: Color, border: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(2)
	s.set_corner_radius_all(6)
	s.content_margin_left = 16
	s.content_margin_right = 16
	s.content_margin_top = 8
	s.content_margin_bottom = 8
	return s


static func _bar(c: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = c
	s.set_corner_radius_all(3)
	return s


static func button(text: String, cb: Callable, min_width := 0) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(min_width, BUTTON_HEIGHT)
	b.pressed.connect(func(): Audio.sfx("select"))
	b.pressed.connect(cb)
	return b


static func label(text: String, size := 0, color := TEXT) -> Label:
	var l := Label.new()
	l.text = text
	if size > 0:
		l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


## A wrapping paragraph for longer texts in menus.
static func para(text: String, size := 0, color := TEXT) -> Label:
	var l := label(text, size, color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.custom_minimum_size = Vector2(200, 0)
	return l


static func bar(color: Color, height := 14) -> ProgressBar:
	var p := ProgressBar.new()
	p.show_percentage = false
	p.custom_minimum_size = Vector2(0, height)
	p.add_theme_stylebox_override("fill", _bar(color))
	return p
