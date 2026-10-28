class_name Props
extends RefCounted
## Decoration of the diorama: which props each region uses, how much they sway,
## and their textures - generated pixel art from res://assets/props/ when it
## exists, otherwise a hand-written procedural stand-in of the same size, so a
## map never looks empty while art is missing.

const DIR := "res://assets/props/"

## Region look: trees, bushes, flowers, rocks, water plants, border props, ground tint.
const THEMES := {
	"bamboo": {"trees": ["tree_round", "tree_willow", "tree_plum", "bamboo_clump"], "bushes": ["bush_round", "bush_flowering", "fern", "bush_tea"],
		"flowers": ["flowers_red", "flowers_yellow", "flowers_white", "flowers_purple"], "rocks": ["rock_small", "rock_moss"],
		"border": ["bamboo_clump", "tree_round", "bamboo_clump", "tree_willow"], "water": ["reeds", "lotus_pads", "lotus_flower"]},
	"hub": {"trees": ["tree_round", "tree_pine", "tree_plum"], "bushes": ["bush_round", "fern", "bush_flowering"],
		"flowers": ["flowers_yellow", "flowers_white", "flowers_purple"], "rocks": ["rock_small", "rock_big", "rock_moss"],
		"border": ["tree_pine", "tree_round", "tree_cloudpine"], "water": ["reeds"]},
	"river": {"trees": ["tree_willow", "tree_round", "bamboo_clump"], "bushes": ["fern", "bush_round", "fern", "bush_round", "bush_flowering", "fern", "bush_round", "mushrooms"],
		"flowers": ["flowers_white", "flowers_purple"], "rocks": ["rock_karst", "rock_moss", "rock_small"],
		"border": ["tree_willow", "rock_karst", "tree_round", "bamboo_clump"], "water": ["reeds", "lotus_pads", "lotus_flower", "reeds"]},
	"ridge": {"trees": ["tree_maple", "tree_pine"], "bushes": ["shrub_desert", "bush_round"],
		"flowers": ["flowers_yellow", "flowers_red"], "rocks": ["rock_red", "rock_small"],
		"border": ["rock_red", "tree_maple", "tree_pine"], "water": ["reeds"]},
	"dunes": {"trees": ["tree_datepalm"], "bushes": ["shrub_desert"], "flowers": ["flowers_yellow"],
		"rocks": ["rock_sand", "rock_small"], "border": ["rock_sand", "shrub_desert", "tree_datepalm"], "water": ["reeds", "tree_datepalm"]},
	"pillars": {"trees": ["tree_cloudpine", "tree_pine"], "bushes": ["fern", "bush_round"], "flowers": ["flowers_white", "flowers_purple"],
		"rocks": ["rock_moss", "rock_big"], "border": ["cloud_wisp", "tree_cloudpine"], "water": ["reeds"]},
	"temple": {"trees": ["tree_cloudpine"], "bushes": ["fern"], "flowers": ["flowers_white"], "rocks": ["rock_moss"],
		"border": ["cloud_wisp"], "water": []},
}
## Wind sway per prop (world units at the top).
const SWAY := {"tree_round": 0.05, "tree_willow": 0.09, "tree_plum": 0.05, "tree_pine": 0.03, "tree_maple": 0.05,
	"tree_datepalm": 0.07, "tree_cloudpine": 0.02, "bamboo_clump": 0.1, "bush_round": 0.03, "bush_flowering": 0.03,
	"bush_tea": 0.02, "shrub_desert": 0.04, "fern": 0.06, "reeds": 0.1, "flowers_red": 0.05, "flowers_yellow": 0.05,
	"flowers_white": 0.05, "flowers_purple": 0.05, "rice_sheaf": 0.04, "laundry_line": 0.03, "banner_red": 0.05,
	"prayer_flags": 0.04, "cloud_wisp": 0.08, "lantern_red": 0.02, "wind_chime": 0.04,
	"banner_green": 0.05, "banner_yellow": 0.05, "banner_white": 0.05, "banner_black": 0.05}
## Props that lie flat on the ground or water instead of standing up.
const FLAT := ["lotus_pads"]
## Props that glow (lanterns, braziers).
const GLOW := {"lantern_red": 1.6, "lantern_string": 1.4, "brazier": 1.2}
## Size of procedural stand-ins (px), matching the art brief.
const SIZE := {"tree_willow": Vector2i(96, 112), "tree_plum": Vector2i(80, 96), "tree_pine": Vector2i(72, 112),
	"tree_round": Vector2i(80, 96), "tree_maple": Vector2i(80, 96), "tree_datepalm": Vector2i(72, 112),
	"tree_cloudpine": Vector2i(96, 96), "bamboo_clump": Vector2i(64, 128), "bush_round": Vector2i(40, 32),
	"bush_flowering": Vector2i(40, 32), "bush_tea": Vector2i(40, 28), "shrub_desert": Vector2i(40, 32), "fern": Vector2i(32, 24),
	"reeds": Vector2i(32, 40), "lotus_flower": Vector2i(24, 20), "lotus_pads": Vector2i(40, 24), "mushrooms": Vector2i(20, 16),
	"flowers_red": Vector2i(24, 16), "flowers_yellow": Vector2i(24, 16), "flowers_white": Vector2i(24, 16),
	"flowers_purple": Vector2i(24, 16), "rock_small": Vector2i(24, 16), "rock_big": Vector2i(48, 40), "rock_moss": Vector2i(40, 32),
	"rock_red": Vector2i(40, 32), "rock_sand": Vector2i(32, 20), "rock_karst": Vector2i(32, 40), "lantern_red": Vector2i(16, 24),
	"lantern_stone": Vector2i(24, 40), "barrel": Vector2i(24, 28), "crate": Vector2i(24, 24), "jar": Vector2i(20, 24),
	"jars_group": Vector2i(40, 28), "basket_veg": Vector2i(28, 20), "cloud_wisp": Vector2i(64, 32), "haystack": Vector2i(40, 36),
	"firewood": Vector2i(40, 24), "banner_red": Vector2i(24, 56), "stall": Vector2i(64, 64), "drum": Vector2i(32, 36)}

static var _cache := {}


static func theme(region: String) -> Dictionary:
	return THEMES.get(region, THEMES["bamboo"])


static func texture(id: String) -> Texture2D:
	if _cache.has(id):
		return _cache[id]
	var path := DIR + id + ".png"
	var tex: Texture2D = load(path) if ResourceLoader.exists(path) else _procedural(id)
	_cache[id] = tex
	return tex


static func has_art(id: String) -> bool:
	return ResourceLoader.exists(DIR + id + ".png")


# --- procedural stand-ins -------------------------------------------------------

const OUTLINE := Color("2a2230")


static func _procedural(id: String) -> Texture2D:
	if not SIZE.has(id):
		return null
	var s: Vector2i = SIZE[id]
	var img := Image.create(s.x, s.y, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(id)
	match id:
		"tree_round", "tree_plum", "tree_maple", "tree_willow":
			var leaf: Array = {"tree_round": [Color("3f8a3c"), Color("5aa84a"), Color("8acc5c")],
				"tree_plum": [Color("d87aa0"), Color("eea0c0"), Color("fbd0e0")],
				"tree_maple": [Color("c8502c"), Color("e07a3a"), Color("f4b05a")],
				"tree_willow": [Color("4f8a3c"), Color("78b04e"), Color("a8d46a")]}[id]
			_trunk(img, s.x / 2, s.y - 1, s.y * 0.42, 4 if id != "tree_willow" else 5)
			for i in 9:
				var cx := s.x * 0.5 + rng.randf_range(-s.x * 0.28, s.x * 0.28)
				var cy := s.y * 0.38 + rng.randf_range(-s.y * 0.18, s.y * 0.12)
				_blob(img, Vector2(cx, cy), s.x * rng.randf_range(0.16, 0.24), leaf)
			if id == "tree_willow":
				for i in 14:
					var x := rng.randi_range(8, s.x - 8)
					var y0 := int(s.y * 0.4)
					for y in range(y0, y0 + rng.randi_range(18, 40)):
						if y < s.y - 6:
							img.set_pixel(clampi(x + int(sin(y * 0.2) * 1.5), 0, s.x - 1), y, leaf[1] if y % 3 else leaf[2])
			if id == "tree_plum":
				for i in 20:
					img.set_pixel(rng.randi_range(10, s.x - 10), rng.randi_range(8, int(s.y * 0.6)), Color("fff4f8"))
		"tree_pine", "tree_cloudpine":
			_trunk(img, s.x / 2, s.y - 1, s.y * 0.3, 4)
			var cols: Array = [Color("1f4f3a"), Color("2f6b47"), Color("4a8a5a")]
			var layers := 4 if id == "tree_pine" else 3
			for l in layers:
				var cy := s.y * (0.18 + l * 0.17)
				var w := s.x * (0.22 + l * 0.08) * (1.6 if id == "tree_cloudpine" else 1.0)
				for y in int(s.y * 0.14):
					var hw := w * (float(y) / (s.y * 0.14))
					for x in range(int(s.x / 2 - hw), int(s.x / 2 + hw)):
						if x >= 0 and x < s.x:
							var c: Color = cols[0] if x > s.x / 2 + hw * 0.3 else (cols[2] if x < s.x / 2 - hw * 0.4 else cols[1])
							img.set_pixel(x, clampi(int(cy + y), 0, s.y - 1), c)
		"tree_datepalm":
			for y in range(int(s.y * 0.25), s.y):
				var x := int(s.x / 2 + sin(y * 0.05) * 4)
				img.fill_rect(Rect2i(x - 2, y, 5, 1), Color("8a6a44") if y % 4 else Color("6a5034"))
			for a in 8:
				var ang := a * TAU / 8.0
				for r in 30:
					var p := Vector2(s.x / 2, s.y * 0.25) + Vector2(cos(ang), sin(ang) * 0.5 + r * 0.012) * r
					if p.x >= 1 and p.x < s.x - 1 and p.y >= 1 and p.y < s.y:
						img.fill_rect(Rect2i(int(p.x), int(p.y), 2, 2), Color("4f8a3c") if r % 5 else Color("7ab04e"))
		"bamboo_clump":
			for i in 6:
				var x := 8 + i * 9 + rng.randi_range(-2, 2)
				var top := rng.randi_range(4, 30)
				for y in range(top, s.y):
					img.fill_rect(Rect2i(x, y, 4, 1), Color("4f9a4a") if (y - top) % 18 != 0 else Color("2f6b3a"))
					img.set_pixel(x, y, Color("8acc5c"))
				for k in 4:
					_blob(img, Vector2(x + rng.randf_range(-6, 8), top + k * 14 + rng.randf_range(0, 6)), 5, [Color("3d8549"), Color("5aa84a"), Color("9cc26a")])
		"bush_round", "bush_flowering", "bush_tea", "shrub_desert", "fern":
			var cols: Array = {"bush_round": [Color("3f7a3a"), Color("5aa84a"), Color("8acc5c")],
				"bush_flowering": [Color("3f7a3a"), Color("5aa84a"), Color("8acc5c")],
				"bush_tea": [Color("2f6b3a"), Color("3f8a3c"), Color("6aa84f")],
				"shrub_desert": [Color("6a7a4a"), Color("8a9a5a"), Color("b0b070")],
				"fern": [Color("2f6b3a"), Color("4f9a4a"), Color("7ab04e")]}[id]
			for i in 5:
				_blob(img, Vector2(s.x * rng.randf_range(0.3, 0.7), s.y * rng.randf_range(0.45, 0.65)), s.y * 0.32, cols)
			if id == "bush_flowering":
				for i in 12:
					img.fill_rect(Rect2i(rng.randi_range(6, s.x - 8), rng.randi_range(4, s.y - 10), 2, 2), [Color("f4a0c0"), Color("fff4f8")][i % 2])
		"flowers_red", "flowers_yellow", "flowers_white", "flowers_purple":
			var fc: Color = {"flowers_red": Color("e8452f"), "flowers_yellow": Color("ffcf5a"), "flowers_white": Color("f4efe6"),
				"flowers_purple": Color("a070d0")}[id]
			for i in 7:
				var x := rng.randi_range(3, s.x - 4)
				var h := rng.randi_range(5, 12)
				for y in h:
					img.set_pixel(x, s.y - 1 - y, Color("4f8a3c"))
				var c := Vector2i(x, s.y - 1 - h)
				for d in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
					var q: Vector2i = c + d
					if q.x >= 0 and q.x < s.x and q.y >= 0:
						img.set_pixelv(q, fc)
				img.set_pixelv(c, Color("ffcf5a") if id != "flowers_yellow" else Color("e07a3a"))
		"rock_small", "rock_big", "rock_moss", "rock_red", "rock_sand", "rock_karst":
			var cols: Array = {"rock_small": [Color("6b6457"), Color("8c8577"), Color("b5ad9c")], "rock_big": [Color("6b6457"), Color("8c8577"), Color("b5ad9c")],
				"rock_moss": [Color("5e6a57"), Color("7a8a6a"), Color("9ab07a")], "rock_red": [Color("8e3a2a"), Color("c25a3c"), Color("e8a060")],
				"rock_sand": [Color("a08050"), Color("c9a660"), Color("e6c886")], "rock_karst": [Color("5a6a58"), Color("7a8a76"), Color("a0b098")]}[id]
			_blob(img, Vector2(s.x * 0.5, s.y * 0.62), minf(s.x * 0.46, s.y * 0.6), cols)
			if id == "rock_karst":
				_blob(img, Vector2(s.x * 0.5, s.y * 0.35), s.x * 0.32, cols)
			if id == "rock_moss":
				for i in 10:
					img.fill_rect(Rect2i(rng.randi_range(8, s.x - 10), rng.randi_range(6, 12), 3, 2), Color("6aa84f"))
		"reeds":
			for i in 9:
				var x := rng.randi_range(3, s.x - 4)
				var h := rng.randi_range(18, s.y - 2)
				for y in h:
					img.set_pixel(clampi(x + int(y * rng.randf_range(-0.08, 0.08)), 0, s.x - 1), s.y - 1 - y, Color("6a8a4a") if y % 4 else Color("8aa060"))
				if i % 3 == 0:
					img.fill_rect(Rect2i(x - 1, s.y - h, 3, 6), Color("7a4e2d"))
		"lotus_pads":
			for i in 4:
				_blob(img, Vector2(rng.randf_range(8, s.x - 8), rng.randf_range(7, s.y - 7)), 6, [Color("2f7a4a"), Color("4f9a5a"), Color("7ac07a")])
		"lotus_flower":
			_blob(img, Vector2(s.x / 2, s.y - 5), 6, [Color("2f7a4a"), Color("4f9a5a"), Color("7ac07a")])
			_blob(img, Vector2(s.x / 2, s.y - 11), 5, [Color("d87aa0"), Color("f4a0c0"), Color("fff0f6")])
		"mushrooms":
			for i in 3:
				var x := 4 + i * 6
				img.fill_rect(Rect2i(x, s.y - 6, 2, 6), Color("f4efe6"))
				_blob(img, Vector2(x + 1, s.y - 8), 3.5, [Color("a8382b"), Color("d8562c"), Color("f4efe6")])
		"lantern_red":
			img.fill_rect(Rect2i(7, 0, 2, 4), Color("553520"))
			_blob(img, Vector2(8, 13), 7, [Color("a8382b"), Color("e8452f"), Color("ffb070")])
			img.fill_rect(Rect2i(4, 5, 8, 2), Color("e0b04a"))
			img.fill_rect(Rect2i(4, 20, 8, 2), Color("e0b04a"))
			img.fill_rect(Rect2i(7, 22, 2, 2), Color("e8452f"))
		"lantern_stone":
			img.fill_rect(Rect2i(9, 22, 6, 18), Color("8c8577"))
			img.fill_rect(Rect2i(5, 14, 14, 9), Color("a39b8b"))
			img.fill_rect(Rect2i(8, 16, 8, 5), Color("ffcf5a"))
			img.fill_rect(Rect2i(3, 10, 18, 4), Color("7a7365"))
			img.fill_rect(Rect2i(10, 6, 4, 4), Color("7a7365"))
		"barrel":
			img.fill_rect(Rect2i(3, 4, 18, 23), Color("8a5b36"))
			for y in [7, 15, 23]:
				img.fill_rect(Rect2i(3, y, 18, 2), Color("553520"))
			img.fill_rect(Rect2i(5, 4, 3, 22), Color("a8784e"))
		"crate":
			img.fill_rect(Rect2i(2, 4, 20, 19), Color("a8784e"))
			img.fill_rect(Rect2i(2, 4, 20, 2), Color("c9a070"))
			for x in [2, 11, 20]:
				img.fill_rect(Rect2i(x, 4, 2, 19), Color("7a4e2d"))
		"jar", "jars_group":
			var n := 1 if id == "jar" else 3
			for i in n:
				var cx := s.x / 2.0 if n == 1 else 8.0 + i * 12.0
				_blob(img, Vector2(cx, s.y - 9), 8, [Color("5a3a50"), Color("7a5a80"), Color("b0a0c8")] if i % 2 else [Color("2f5f6f"), Color("3b7e8f"), Color("8fc2c8")])
				img.fill_rect(Rect2i(int(cx) - 3, s.y - 20, 6, 3), Color("553520"))
		"basket_veg":
			img.fill_rect(Rect2i(3, 9, 22, 10), Color("b08a4a"))
			for x in range(3, 25, 3):
				img.fill_rect(Rect2i(x, 9, 1, 10), Color("8a6a34"))
			for i in 4:
				_blob(img, Vector2(7 + i * 5, 7), 3.5, [Color("3f8a3c"), Color("7ac05a"), Color("c8f09a")])
		"cloud_wisp":
			for i in 6:
				_blob(img, Vector2(rng.randf_range(14, s.x - 14), rng.randf_range(12, s.y - 10)), rng.randf_range(8, 12),
					[Color(0.86, 0.9, 0.95, 0.9), Color(0.95, 0.97, 1.0, 0.95), Color(1, 1, 1, 1)])
			return ImageTexture.create_from_image(img)
		"haystack":
			_blob(img, Vector2(s.x / 2, s.y * 0.6), 16, [Color("b08a3a"), Color("d8b45a"), Color("f0d880")])
		"firewood":
			for i in 5:
				img.fill_rect(Rect2i(4 + i * 6, 6 + (i % 2) * 2, 6, 16), Color("7a4e2d"))
				img.fill_rect(Rect2i(5 + i * 6, 7 + (i % 2) * 2, 4, 3), Color("c9a070"))
		"banner_red":
			img.fill_rect(Rect2i(3, 0, 2, s.y), Color("553520"))
			img.fill_rect(Rect2i(5, 4, 16, 40), Color("c8302a"))
			img.fill_rect(Rect2i(8, 12, 10, 10), Color("e0b04a"))
			img.fill_rect(Rect2i(5, 4, 16, 2), Color("e0b04a"))
		"stall":
			img.fill_rect(Rect2i(6, 28, 52, 30), Color("8a5b36"))
			img.fill_rect(Rect2i(6, 28, 52, 3), Color("a8784e"))
			for x in range(2, 62, 10):
				img.fill_rect(Rect2i(x, 10, 5, 14), Color("c8302a"))
				img.fill_rect(Rect2i(x + 5, 10, 5, 14), Color("f4efe6"))
			img.fill_rect(Rect2i(6, 24, 3, 34), Color("553520"))
			img.fill_rect(Rect2i(55, 24, 3, 34), Color("553520"))
			for i in 6:
				_blob(img, Vector2(14 + i * 7, 33), 3, [Color("c8502c"), Color("e8902c"), Color("ffd070")])
		"drum":
			img.fill_rect(Rect2i(4, 24, 3, 12), Color("553520"))
			img.fill_rect(Rect2i(25, 24, 3, 12), Color("553520"))
			_blob(img, Vector2(16, 16), 12, [Color("8e2e23"), Color("c8302a"), Color("e8604a")])
			img.fill_rect(Rect2i(8, 12, 16, 8), Color("e8d8b0"))
		_:
			return null
	_outline(img)
	return ImageTexture.create_from_image(img)


static func _blob(img: Image, c: Vector2, r: float, cols: Array) -> void:
	var w := img.get_width()
	var h := img.get_height()
	for y in range(int(c.y - r), int(c.y + r) + 1):
		for x in range(int(c.x - r), int(c.x + r) + 1):
			if x < 0 or y < 0 or x >= w or y >= h:
				continue
			var d := Vector2(x, y).distance_to(c) / r
			if d > 1.0:
				continue
			# Light from the top left: highlight, mid, shadow.
			var lit := (x - c.x) / r * 0.6 + (y - c.y) / r * 0.8
			var col: Color = cols[2] if lit < -0.45 and d < 0.85 else (cols[0] if lit > 0.35 else cols[1])
			if cols[0].a < 1.0:
				col.a = cols[1].a
			img.set_pixel(x, y, col)


static func _trunk(img: Image, x: int, bottom: int, height: float, w: int) -> void:
	for y in range(int(bottom - height), bottom + 1):
		img.fill_rect(Rect2i(x - w / 2, y, w, 1), Color("6a4226"))
		img.set_pixel(x - w / 2, y, Color("8a5b36"))


static func _outline(img: Image) -> void:
	var w := img.get_width()
	var h := img.get_height()
	var src := img.duplicate() as Image
	for y in h:
		for x in w:
			if src.get_pixel(x, y).a > 0.5:
				continue
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var q: Vector2i = Vector2i(x, y) + d
				if q.x >= 0 and q.y >= 0 and q.x < w and q.y < h and src.get_pixelv(q).a > 0.5:
					img.set_pixel(x, y, OUTLINE)
					break
