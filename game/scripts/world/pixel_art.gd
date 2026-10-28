class_name PixelArt
extends RefCounted
## Procedural placeholder pixel art for Phase 0 tests (32 px grid). Real tiles
## and sprites come from the asset pipeline in Phase 1; these only need the
## right size, palette discipline and crisp pixels.

const TILE := 32


static func _noise_tile(base: Color, accents: Array[Color], seed_value: int, density := 0.12) -> Image:
	var img := Image.create(TILE, TILE, false, Image.FORMAT_RGBA8)
	img.fill(base)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	for i in int(TILE * TILE * density):
		img.set_pixel(rng.randi_range(0, TILE - 1), rng.randi_range(0, TILE - 1), accents[rng.randi_range(0, accents.size() - 1)])
	return img


static func tile(kind: String) -> ImageTexture:
	var img: Image
	match kind:
		"grass":
			img = _noise_tile(Color("4f8a3c"), [Color("5f9c46"), Color("3f7232"), Color("6aa84f")], 1)
		"path":
			img = _noise_tile(Color("b89a6a"), [Color("a68858"), Color("c9ad7d"), Color("94784c")], 2, 0.18)
		"water":
			img = _noise_tile(Color("3b6ea5"), [Color("4a80b8"), Color("335f90"), Color("8fb8de")], 3, 0.08)
		"stone":
			img = _noise_tile(Color("8c8577"), [Color("7a7365"), Color("a39b8b"), Color("6b6457")], 4, 0.2)
			for y in [0, 15, 31]:
				for x in TILE:
					img.set_pixel(x, y, Color("5e584c"))
		"bamboo":
			img = _noise_tile(Color("2f6b3a"), [Color("3d8549"), Color("24532d"), Color("9cc26a")], 5, 0.25)
		"wood":
			img = _noise_tile(Color("7a4e2d"), [Color("8a5b36"), Color("6a4226")], 6, 0.15)
			for x in [7, 15, 23, 31]:
				for y in TILE:
					img.set_pixel(x, y, Color("553520"))
		"roof":
			img = _noise_tile(Color("a8382b"), [Color("b84536"), Color("8e2e23")], 7, 0.1)
			for y in range(3, TILE, 6):
				for x in TILE:
					img.set_pixel(x, y, Color("7a241b"))
		"plaza":
			img = _noise_tile(Color("a39b8b"), [Color("8c8577"), Color("b5ad9c"), Color("948c7c")], 8, 0.15)
			for i in TILE:
				img.set_pixel(i, 0, Color("7a7365"))
				img.set_pixel(0, i, Color("7a7365"))
				img.set_pixel(i, 16, Color("857e70"))
				img.set_pixel(16 if i < 16 else 0, i, Color("857e70"))
		"paddy":
			img = _noise_tile(Color("4f8f7a"), [Color("6aa88a"), Color("3f7a6a"), Color("8fc2a8")], 9, 0.12)
		"plaster":
			img = _noise_tile(Color("e8dcc4"), [Color("d9cbb0"), Color("f2e8d4")], 10, 0.08)
			for x in TILE:
				img.set_pixel(x, 31, Color("7a4e2d"))
				img.set_pixel(x, 0, Color("7a4e2d"))
		"door":
			img = _noise_tile(Color("7a4e2d"), [Color("8a5b36"), Color("6a4226")], 11, 0.1)
			_rect(img, 8, 6, 16, 26, Color("4a2c18"))
			_rect(img, 10, 8, 12, 24, Color("8e2e23"))
			_rect(img, 19, 18, 2, 2, Color("e0b04a"))
		"pillar":
			img = _noise_tile(Color("a8382b"), [Color("b84536"), Color("8e2e23")], 12, 0.08)
			for x in [3, 28]:
				for y in TILE:
					img.set_pixel(x, y, Color("e0b04a"))
		"rock":
			img = _noise_tile(Color("7a7365"), [Color("8c8577"), Color("5e584c"), Color("a39b8b")], 13, 0.3)
		"cloth":
			img = _noise_tile(Color("2f6f8f"), [Color("3a80a0")], 14, 0.05)
			for x in range(0, TILE, 8):
				_rect(img, x, 0, 4, TILE, Color("e8dcc4"))
		"lantern":
			img = Image.create(TILE, TILE, false, Image.FORMAT_RGBA8)
			img.fill(Color("e8452f"))
			for y in range(4, TILE - 4):
				for x in range(10, 22):
					img.set_pixel(x, y, Color("ffcf5a"))
		"sand":
			img = _noise_tile(Color("d9b874"), [Color("e6c886"), Color("c9a660"), Color("efd69a")], 15, 0.18)
		"redrock":
			img = _noise_tile(Color("b8644a"), [Color("c97656"), Color("a3543c"), Color("d9895e")], 16, 0.16)
		"danxia":
			img = _noise_tile(Color("c25a3c"), [Color("b04c30")], 17, 0.1)
			var bands: Array[Color] = [Color("e0a050"), Color("c25a3c"), Color("d97a4a"), Color("8e3a2a"), Color("e8c070")]
			for y in TILE:
				var c: Color = bands[(y / 5) % bands.size()]
				for x in TILE:
					if (x + y * 3) % 7 != 0:
						img.set_pixel(x, y, c)
		"karst":
			img = _noise_tile(Color("6f8a6a"), [Color("5a7458"), Color("8aa080"), Color("4f8a3c")], 18, 0.3)
		"cloud":
			img = _noise_tile(Color("eef2f6"), [Color("dfe6ee"), Color("ffffff"), Color("cfd8e2")], 19, 0.2)
		"cloudstone":
			img = _noise_tile(Color("a6a29a"), [Color("b8b4ac"), Color("948f86"), Color("c4c0b6")], 20, 0.15)
			for i in TILE:
				img.set_pixel(i, 0, Color("858076"))
				img.set_pixel(0, i, Color("858076"))
		"pillarstone":
			img = _noise_tile(Color("8f8a80"), [Color("a39e93"), Color("7a756b"), Color("6a8a5a")], 21, 0.28)
			for y in range(5, TILE, 9):
				for x in TILE:
					img.set_pixel(x, y, Color("6b675f"))
		"pine":
			img = _noise_tile(Color("2a4f3a"), [Color("356247"), Color("1f3d2d"), Color("4a7a52")], 22, 0.3)
		"greywall":
			img = _noise_tile(Color("b9b6ae"), [Color("a8a59d"), Color("c8c5bd")], 23, 0.08)
			for x in TILE:
				img.set_pixel(x, 31, Color("5e584c"))
				img.set_pixel(x, 0, Color("5e584c"))
		"greyroof":
			img = _noise_tile(Color("5e6470"), [Color("6e7480"), Color("4e5460")], 24, 0.1)
			for y in range(3, TILE, 6):
				for x in TILE:
					img.set_pixel(x, y, Color("3e4450"))
		"ember":
			img = _noise_tile(Color("4a3a34"), [Color("e8452f"), Color("ffb35a"), Color("3a2c28")], 25, 0.14)
		"ore":
			img = _noise_tile(Color("6b6875"), [Color("a9b1bb"), Color("4e4c58"), Color("c9d0d8")], 26, 0.2)
		"gravel":
			img = _noise_tile(Color("a39880"), [Color("8c826c"), Color("bdb39a"), Color("766c58")], 27, 0.35)
		"pond":
			img = _noise_tile(Color("4a86b0"), [Color("5a98c2"), Color("8fb8de"), Color("3f9a52")], 28, 0.1)
		"floor":
			img = _noise_tile(Color("9a6a42"), [Color("8a5b36"), Color("a8784e")], 29, 0.12)
			for y in [0, 8, 16, 24]:
				for x in TILE:
					img.set_pixel(x, y, Color("6a4226"))
		"gold":
			img = _noise_tile(Color("e0b04a"), [Color("f0c860"), Color("c99a3a")], 30, 0.15)
		_:
			img = _noise_tile(Color.MAGENTA, [Color.BLACK], 0)
	return ImageTexture.create_from_image(img)


## Billboard tufts (32x24, transparent): tall grass, rice, flowers.
static func tuft(kind: String) -> ImageTexture:
	var img := Image.create(32, 24, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(kind)
	var cols: Array = {
		"tallgrass": [Color("3f7232"), Color("5f9c46"), Color("6aa84f"), Color("2f5a28")],
		"rice": [Color("7fb069"), Color("9cc26a"), Color("c9c26a"), Color("5f9c46")],
		"flowers": [Color("5f9c46"), Color("3f7232")],
		"drygrass": [Color("c9a24a"), Color("b08a3a"), Color("dcbc6a"), Color("8e6e2e")],
		"reeds": [Color("6a8a4a"), Color("8aa060"), Color("4f6a3a"), Color("b0b070")],
		"sapling": [Color("3d8549"), Color("9cc26a"), Color("2f6b3a")],
	}.get(kind, [Color("3f7232"), Color("5f9c46")])
	for blade in 14:
		var x := rng.randi_range(2, 29)
		var h := rng.randi_range(10, 23)
		var lean := rng.randf_range(-0.25, 0.25)
		var c: Color = cols[rng.randi_range(0, cols.size() - 1)]
		for y in h:
			var px := clampi(x + roundi(lean * y), 0, 31)
			img.set_pixel(px, 23 - y, c if y < h - 2 else c.lightened(0.25))
	if kind == "flowers":
		for i in 6:
			var fx := rng.randi_range(3, 28)
			var fy := rng.randi_range(4, 14)
			var fc: Color = [Color("e8452f"), Color("ffcf5a"), Color("f4efe6"), Color("d86aa0")][i % 4]
			img.fill_rect(Rect2i(fx - 1, fy - 1, 3, 3), fc)
			img.set_pixel(fx, fy, Color("ffcf5a"))
	if kind == "rice":
		for i in 8:
			var rx := rng.randi_range(3, 28)
			img.fill_rect(Rect2i(rx, rng.randi_range(1, 6), 2, 3), Color("e0c46a"))
	return ImageTexture.create_from_image(img)


## Placeholder people: hair, tunic, legs colours (until generated sprites exist).
const PEOPLE := {
	"meister": [Color("e8e4dc"), Color("7a4e2d"), Color("553520")],
	"yao": [Color("1c1a1f"), Color("b8352a"), Color("3a3046")],
	"wusheng": [Color("8c8577"), Color("5e584c"), Color("3a3046")],
	"villager_a": [Color("2b2230"), Color("c9a24a"), Color("6b3b22")],
	"villager_b": [Color("6b3b22"), Color("4f9a4a"), Color("3a3046")],
	"shopkeeper": [Color("2b2230"), Color("e0b04a"), Color("553520")],
	"innkeeper": [Color("a39b8b"), Color("8e2e23"), Color("3a3046")],
	"teahouse": [Color("1c1a1f"), Color("3f7a3a"), Color("553520")],
	"monk": [Color("f1c9a5"), Color("d8682c"), Color("d8682c")],
	"order_a": [Color("b9b6ae"), Color("a8a59d"), Color("6b675f")],
	"order_b": [Color("e8e4dc"), Color("a8a59d"), Color("6b675f")],
	"yao_order": [Color("1c1a1f"), Color("a8a59d"), Color("6b675f")],
	"fisher": [Color("c9a24a"), Color("3b6ea5"), Color("553520")],
	"boatwoman": [Color("3b6ea5"), Color("2f6f8f"), Color("3a3046")],
	"trader": [Color("e8dcc4"), Color("c49a4a"), Color("6b3b22")],
	"carpenter": [Color("6b3b22"), Color("8a5b36"), Color("3a3046")],
	"cook": [Color("f4efe6"), Color("e8e4dc"), Color("553520")],
	"elder": [Color("e8e4dc"), Color("5e584c"), Color("3a3046")],
	"girl_c": [Color("1c1a1f"), Color("e8452f"), Color("3a3046")],
	"man_c": [Color("2b2230"), Color("8a5b36"), Color("553520")],
	"meister_free": [Color("e8e4dc"), Color("7a4e2d"), Color("553520")],
}


## 32x48 character: simple silhouette from rows of a tiny pattern.
static func character(kind: String) -> ImageTexture:
	var img := Image.create(32, 48, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	if PEOPLE.has(kind) or kind not in ["hero", "jinli", "panda"]:
		var c: Array = PEOPLE.get(kind, [Color("2b2230"), Color("8c8577"), Color("3a3046")])
		_rect(img, 11, 6, 10, 10, Color("f1c9a5"))
		_rect(img, 10, 3, 12, 5, c[0])
		_rect(img, 13, 10, 2, 2, Color("2b2230"))
		_rect(img, 18, 10, 2, 2, Color("2b2230"))
		_rect(img, 9, 16, 14, 18 if kind in ["wusheng", "meister", "monk"] else 16, c[1])
		_rect(img, 6, 17, 3, 11, c[1])
		_rect(img, 23, 17, 3, 11, c[1])
		if kind == "meister":
			_rect(img, 12, 14, 8, 6, c[0])  # beard
		_rect(img, 10, 32, 5, 12, c[2])
		_rect(img, 17, 32, 5, 12, c[2])
		return ImageTexture.create_from_image(img)
	match kind:
		"hero":
			_rect(img, 11, 6, 10, 10, Color("f1c9a5"))   # face
			_rect(img, 10, 3, 12, 5, Color("2b2230"))    # hair
			_rect(img, 13, 10, 2, 2, Color("2b2230"))    # eyes
			_rect(img, 18, 10, 2, 2, Color("2b2230"))
			_rect(img, 9, 16, 14, 16, Color("2f6f8f"))   # tunic
			_rect(img, 9, 24, 14, 2, Color("e0b04a"))    # belt
			_rect(img, 10, 32, 5, 12, Color("3a3046"))   # legs
			_rect(img, 17, 32, 5, 12, Color("3a3046"))
			_rect(img, 6, 17, 3, 11, Color("2f6f8f"))    # arms
			_rect(img, 23, 17, 3, 11, Color("2f6f8f"))
		"jinli":
			# Tortoiseshell cat: black, red-orange, white patches; koi bell.
			_rect(img, 8, 28, 16, 12, Color("f4efe6"))
			_rect(img, 8, 28, 6, 6, Color("1c1a1f"))
			_rect(img, 17, 33, 7, 7, Color("d8682c"))
			_rect(img, 10, 18, 12, 11, Color("f4efe6"))
			_rect(img, 10, 18, 6, 5, Color("d8682c"))
			_rect(img, 17, 18, 5, 4, Color("1c1a1f"))
			_rect(img, 10, 15, 3, 4, Color("1c1a1f"))   # ears
			_rect(img, 19, 15, 3, 4, Color("d8682c"))
			_rect(img, 12, 22, 2, 2, Color("3f9a52"))   # eyes
			_rect(img, 18, 22, 2, 2, Color("3f9a52"))
			_rect(img, 15, 28, 2, 2, Color("e35b2e"))   # koi bell
			_rect(img, 24, 30, 6, 2, Color("1c1a1f"))   # tail
			_rect(img, 10, 40, 3, 4, Color("f4efe6"))
			_rect(img, 19, 40, 3, 4, Color("f4efe6"))
		"panda":
			_rect(img, 7, 22, 18, 20, Color("f2f2ee"))
			_rect(img, 7, 30, 18, 6, Color("1d1c20"))
			_rect(img, 8, 10, 16, 13, Color("f2f2ee"))
			_rect(img, 7, 8, 4, 4, Color("1d1c20"))
			_rect(img, 21, 8, 4, 4, Color("1d1c20"))
			_rect(img, 11, 14, 4, 4, Color("1d1c20"))
			_rect(img, 17, 14, 4, 4, Color("1d1c20"))
			_rect(img, 15, 19, 2, 2, Color("1d1c20"))
			_rect(img, 8, 42, 6, 4, Color("1d1c20"))
			_rect(img, 18, 42, 6, 4, Color("1d1c20"))
	return ImageTexture.create_from_image(img)


static func _rect(img: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	img.fill_rect(Rect2i(x, y, w, h), c)
