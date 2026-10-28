class_name Sprites
extends RefCounted
## Texture lookup for Lingshou and characters: generated art from
## res://assets/sprites when present, procedural placeholders otherwise.

const LINGSHOU_DIR := "res://assets/sprites/lingshou/"
const CHARS_DIR := "res://assets/sprites/chars/"
## Hero look options (GDD character editor, beta: colours only).
const HAIR_COLORS: Array[Color] = [Color("2b2230"), Color("6b3b22"), Color("c9a24a"), Color("8a8f9a")]
const OUTFIT_COLORS: Array[Color] = [Color("2f6f8f"), Color("a8382b"), Color("3f7a3a"), Color("6a4c93")]
const ELEMENT_COLORS := {"wood": Color("4f9a4a"), "fire": Color("d8562c"), "earth": Color("c49a4a"),
	"metal": Color("a9b1bb"), "water": Color("3b7ec2")}

static var _cache := {}


## silenced: the grey variant (<id>_silenced.png) if the art has one.
static func lingshou(id: String, silenced := false) -> Texture2D:
	if silenced and ResourceLoader.exists(LINGSHOU_DIR + id + "_silenced.png"):
		id += "_silenced"
	var key := "ls:" + id
	if not _cache.has(key):
		var path := LINGSHOU_DIR + id + ".png"
		if ResourceLoader.exists(path):
			_cache[key] = load(path)
		else:
			_cache[key] = _placeholder_lingshou(id)
	return _cache[key]


## A Lingshou record's look: rare colour variants are hue-shifted (GDD "Zucht").
static func lingshou_rec(rec: Dictionary) -> Texture2D:
	var base := lingshou(rec["species"])
	if int(rec.get("variant", 0)) == 0:
		return base
	var key := "var:" + String(rec["species"])
	if not _cache.has(key):
		var img := base.get_image()
		img.decompress()
		for y in img.get_height():
			for x in img.get_width():
				var c := img.get_pixel(x, y)
				if c.a > 0.5 and c.s > 0.15:
					img.set_pixel(x, y, Color.from_hsv(fposmod(c.h + 0.45, 1.0), c.s, c.v, c.a))
		_cache[key] = ImageTexture.create_from_image(img)
	return _cache[key]


const PORTRAIT_DIR := "res://assets/portraits/"


## Dialog portrait: generated bust if it exists, otherwise the character (or Lingshou) sprite.
static func portrait(id: String, hair := -1, outfit := -1) -> Texture2D:
	if id in GameData.lingshou_ids() or ResourceLoader.exists(LINGSHOU_DIR + id + ".png"):
		return lingshou(id)
	var key := "pt:%s:%d:%d" % [id, hair, outfit]
	if _cache.has(key):
		return _cache[key]
	var tex: Texture2D
	var path := PORTRAIT_DIR + id + ".png"
	if ResourceLoader.exists(path):
		tex = load(path)
		if hair >= 0:
			tex = _recolor(tex, hair, outfit)
	elif id == "hero" and hair >= 0:
		tex = hero(hair, outfit)
	else:
		tex = character(id)
	_cache[key] = tex
	return tex


## Back or side view of a character if the art has one (<id>_back.png), else null.
static func character_view(id: String, view: String) -> Texture2D:
	var path := CHARS_DIR + id + "_" + view + ".png"
	return load(path) if ResourceLoader.exists(path) else null


static func character(id: String) -> Texture2D:
	var key := "ch:" + id
	if not _cache.has(key):
		var path := CHARS_DIR + id + ".png"
		_cache[key] = load(path) if ResourceLoader.exists(path) else PixelArt.character(id)
	return _cache[key]


## The hero recoloured with the chosen hair and outfit (hue swap of the base colours).
static func hero(hair: int, outfit: int, view := "") -> Texture2D:
	var key := "hero:%d:%d:%s" % [hair, outfit, view]
	if _cache.has(key):
		return _cache[key]
	var base := character("hero") if view == "" else character_view("hero", view)
	if base == null:
		return null
	var tex := _recolor(base, hair, outfit)
	_cache[key] = tex
	return tex


## Hair and outfit colours of the character editor on any hero image (sprite or portrait).
static func _recolor(base: Texture2D, hair: int, outfit: int) -> Texture2D:
	var img := base.get_image()
	img.decompress()
	var hair_c := HAIR_COLORS[hair % HAIR_COLORS.size()]
	var outfit_c := OUTFIT_COLORS[outfit % OUTFIT_COLORS.size()]
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			if c.a < 0.5:
				continue
			# Tunic: teal/blue hues; hair: very dark or brown low-saturation pixels in the top third.
			if c.s > 0.25 and c.h > 0.45 and c.h < 0.62:
				img.set_pixel(x, y, Color.from_hsv(outfit_c.h, outfit_c.s * (0.6 + c.s * 0.5), c.v * (0.6 + outfit_c.v * 0.6), c.a))
			elif y < img.get_height() / 3 and c.v < 0.35:
				img.set_pixel(x, y, Color.from_hsv(hair_c.h, hair_c.s, clampf(hair_c.v * (0.5 + c.v * 1.6), 0.0, 1.0), c.a))
	return ImageTexture.create_from_image(img)


static func element_color(element: String) -> Color:
	return ELEMENT_COLORS.get(element, Color.WHITE)


static func _placeholder_lingshou(id: String) -> Texture2D:
	var size := 48
	var element := "earth"
	if id in GameData.lingshou_ids():
		var sp := GameData.lingshou(id)
		element = sp["element"]
		size = int(sp.get("sprite_size", 48))
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var c := element_color(element)
	var r := size * 0.38
	var centre := Vector2(size / 2.0, size * 0.58)
	for y in size:
		for x in size:
			var d := Vector2(x, y).distance_to(centre)
			if d < r:
				img.set_pixel(x, y, c.darkened(0.25) if d > r - 2 else c)
	for ex in [-0.15, 0.15]:
		img.fill_rect(Rect2i(int(size * (0.5 + ex)) - 2, int(size * 0.5), 4, 4), Color("1a1620"))
	return ImageTexture.create_from_image(img)
