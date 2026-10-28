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
	t.set_stylebox("normal", "Button", skin("button"))
	t.set_stylebox("hover", "Button", skin("button_hover"))
	t.set_stylebox("pressed", "Button", skin("button_pressed"))
	t.set_stylebox("focus", "Button", skin("focus"))
	t.set_stylebox("disabled", "Button", skin("button_disabled"))
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


static func panel(alpha := 0.92) -> StyleBox:
	var sb := skin("panel")
	sb.modulate_color = Color(1, 1, 1, alpha / 0.92)
	return sb


# --- pixel frames (procedural 9-slice skins) -------------------------------------

const PX := 3  # screen pixels per skin pixel
static var _skins := {}


## Pixel-art frames for panels and buttons: dark indigo with a soft starry
## pattern, a bevelled gold frame and little knot ornaments in the corners.
static func skin(kind: String) -> StyleBoxTexture:
	if _skins.has(kind):
		return _skins[kind].duplicate()
	var size := 24
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var fill := Color("221b30")
	var fill2 := Color("2a2240")
	var gold := Color("e0b04a")
	var gold_hi := Color("f8dc8a")
	var gold_lo := Color("a8782a")
	var dark := Color("120e18")
	match kind:
		"button":
			fill = Color("2e2540")
			fill2 = Color("372d4c")
			gold = Color("b8913f")
			gold_hi = Color("d8b465")
			gold_lo = Color("7a5a2a")
		"button_hover":
			fill = Color("3a2f52")
			fill2 = Color("44385e")
		"button_pressed":
			fill = Color("4a3420")
			fill2 = Color("5a4228")
		"button_disabled":
			fill = Color("1c1724")
			fill2 = Color("1f1a28")
			gold = Color("4a4250")
			gold_hi = Color("5a5260")
			gold_lo = Color("3a3240")
		"focus":
			fill = Color(0, 0, 0, 0)
			fill2 = Color(0, 0, 0, 0)
		"nameplate":
			fill = Color("8e2e23")
			fill2 = Color("a8382b")
	for y in size:
		for x in size:
			var edge := mini(mini(x, y), mini(size - 1 - x, size - 1 - y))
			var c := fill
			if (x * 7 + y * 13) % 29 == 0 and kind in ["panel", "nameplate"]:
				c = fill2
			if y < size / 2 and kind.begins_with("button"):
				c = fill2
			match edge:
				0:
					c = dark
				1:
					c = gold_hi if (x < size / 2 and y < size / 2) else (gold_lo if (x >= size / 2 and y >= size / 2) else gold)
				2:
					c = gold if kind != "focus" else Color(0, 0, 0, 0)
				3:
					c = dark.lerp(fill, 0.4) if kind != "focus" else Color(0, 0, 0, 0)
			img.set_pixel(x, y, c)
	# Rounded corners: cut the outermost corner pixels.
	for p in [Vector2i(0, 0), Vector2i(size - 1, 0), Vector2i(0, size - 1), Vector2i(size - 1, size - 1)]:
		img.set_pixelv(p, Color(0, 0, 0, 0))
	# Corner knots (panels only).
	if kind in ["panel", "nameplate"]:
		for cx in [5, size - 6]:
			for cy in [5, size - 6]:
				img.set_pixel(cx, cy, gold)
				img.set_pixel(cx + (1 if cx < size / 2 else -1), cy, gold_lo)
				img.set_pixel(cx, cy + (1 if cy < size / 2 else -1), gold_lo)
	img.resize(size * PX, size * PX, Image.INTERPOLATE_NEAREST)
	var sb := StyleBoxTexture.new()
	sb.texture = ImageTexture.create_from_image(img)
	var m := 7 * PX
	sb.texture_margin_left = m
	sb.texture_margin_right = m
	sb.texture_margin_top = m
	sb.texture_margin_bottom = m
	sb.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT
	sb.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT
	var content := 14 if kind in ["panel", "nameplate"] else 10
	sb.content_margin_left = content + 4
	sb.content_margin_right = content + 4
	sb.content_margin_top = content
	sb.content_margin_bottom = content
	_skins[kind] = sb
	return sb.duplicate()


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
