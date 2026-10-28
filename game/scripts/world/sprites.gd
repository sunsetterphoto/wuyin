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


static func character(id: String) -> Texture2D:
	var key := "ch:" + id
	if not _cache.has(key):
		var path := CHARS_DIR + id + ".png"
		_cache[key] = load(path) if ResourceLoader.exists(path) else PixelArt.character(id)
	return _cache[key]


## The hero recoloured with the chosen hair and outfit (hue swap of the base colours).
static func hero(hair: int, outfit: int) -> Texture2D:
	var key := "hero:%d:%d" % [hair, outfit]
	if _cache.has(key):
		return _cache[key]
	var base := character("hero")
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
	var tex := ImageTexture.create_from_image(img)
	_cache[key] = tex
	return tex


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
