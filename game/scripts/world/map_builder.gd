class_name MapBuilder
extends RefCounted
## Builds the diorama of a map. Ground is one box per tile (MultiMesh per
## surface, brightness varied a little per tile so it never looks flat);
## houses become whole Chinese buildings (Buildings); trees, bamboo, bushes,
## flowers, rocks and village things are pixel-art props on Y-billboards that
## sway in the wind (Props); the map edge is a natural border in the region's
## look with more of it beyond the edge for depth. Decoration is scattered by
## rules per tile and neighbourhood with a seed per map, so a map always looks
## the same. Ground top is y = 0.

const MAX_LIGHTS := 10
## Chances of decoration per walkable tile.
const P_FLOWERS := 0.11
const P_TUFT := 0.07
const P_BUSH_EDGE := 0.2
const P_VILLAGE := 0.2
const P_REEDS := 0.3
const P_LOTUS := 0.09
const OUTSIDE_RING := 5

## Ground of border tiles and of the land beyond the map, per region.
const REGION_GROUND := {"bamboo": "grass", "hub": "grass", "river": "grass", "ridge": "redrock", "dunes": "sand", "pillars": "cloudstone", "temple": "cloudstone"}
const VILLAGE_PROPS := ["barrel", "crate", "jar", "jars_group", "basket_veg", "firewood", "barrel", "jar"]


class Ctx:
	var boxes := {}  # surface kind -> [[Transform3D, Color]]
	var water: Array = []
	var tufts := {}  # tuft kind -> [Transform3D]
	var props := {}  # prop id -> [[Vector3 pos, float scale, float phase]]
	var flats := {}  # prop id -> [[Vector3 pos, float scale, float rot]]
	var shadows: Array = []  # [Vector3 pos, float radius]
	var lights: Array[OmniLight3D] = []
	var rng := RandomNumberGenerator.new()
	var root: Node3D
	var m: MapData
	var region := "bamboo"
	var theme: Dictionary
	var occupied := {}  # tiles where people, objects, spawns and warps are
	var mounds := {}  # surface kind -> [[Transform3D, Color]] (rounded sphere mounds: dunes, boulders)
	var noise := FastNoiseLite.new()

	## Smooth 0..1 value per tile, so neighbouring cliffs have similar heights.
	func height01(x: int, z: int) -> float:
		return clampf(noise.get_noise_2d(x * 9.0, z * 9.0) * 0.5 + 0.5, 0.0, 1.0)

	func mound(kind: String, pos: Vector3, size: Vector3, shade := 1.0, yrot := 0.0) -> void:
		if not mounds.has(kind):
			mounds[kind] = []
		mounds[kind].append([Transform3D(Basis(Vector3.UP, yrot).scaled(size), pos), Color(shade, shade, shade)])

	## A dune crest: long, low, a little turned, sand ripples on it.
	func dune(pos: Vector3, h: float) -> void:
		if rng.randf() < 0.35:
			return
		mound("sand", pos + Vector3(rng.randf_range(-0.3, 0.3), -0.05, rng.randf_range(-0.2, 0.2)),
			Vector3(rng.randf_range(2.6, 3.6), h * 2.0, rng.randf_range(1.4, 1.9)), rng.randf_range(0.94, 1.04), rng.randf_range(-0.35, 0.35))

	## South edge: the camera looks from there, so nothing tall may stand in front.
	func south(z: int) -> bool:
		return z >= m.height - 2

	func box(kind: String, pos: Vector3, size: Vector3, shade := 1.0, yrot := 0.0) -> void:
		if not boxes.has(kind):
			boxes[kind] = []
		boxes[kind].append([Transform3D(Basis(Vector3.UP, yrot).scaled(size), pos), Color(shade, shade, shade)])

	func prop(id: String, pos: Vector3, scale := 1.0, shadow := 0.0) -> void:
		if Props.texture(id) == null:
			return
		if id in Props.FLAT:
			if not flats.has(id):
				flats[id] = []
			flats[id].append([pos, scale, rng.randf_range(0, TAU)])
			return
		if not props.has(id):
			props[id] = []
		props[id].append([pos, scale, rng.randf()])
		if shadow > 0.0:
			shadows.append([pos, shadow * scale])

	func tuft(kind: String, pos: Vector3, scale := 1.0) -> void:
		if not tufts.has(kind):
			tufts[kind] = []
		tufts[kind].append(Transform3D(Basis.from_scale(Vector3.ONE * scale), pos))

	func pick(list: Array) -> String:
		return "" if list.is_empty() else list[rng.randi_range(0, list.size() - 1)]

	func jitter() -> Vector3:
		return Vector3(rng.randf_range(-0.3, 0.3), 0, rng.randf_range(-0.3, 0.3))


## Returns {"root": Node3D, "lights": Array[OmniLight3D]}.
## silent: the region is still under the silence (still water, no glowing windows).
static func build(m: MapData, silent := false) -> Dictionary:
	var c := Ctx.new()
	c.m = m
	c.root = Node3D.new()
	c.root.name = "Map_" + m.id
	c.region = m.def.get("region", "bamboo")
	c.theme = Props.theme(c.region)
	c.rng.seed = hash(m.id)
	c.noise.seed = hash(m.id)
	c.noise.frequency = 0.012
	_mark_occupied(c)
	for b in Buildings.find(m):
		Buildings.build(b, c.root, c.lights, MAX_LIGHTS, 0.0 if silent else 1.0)
	for z in m.height:
		for x in m.width:
			_tile(c, x, z)
	_outside(c)
	_flush(c, silent)
	return {"root": c.root, "lights": c.lights}


static func _mark_occupied(c: Ctx) -> void:
	for list in ["npcs", "objects", "lingshou"]:
		for e in c.m.def.get(list, []):
			var p: Array = e.get("at", [0, 0])
			c.occupied[Vector2i(int(p[0]), int(p[1]))] = true
	for s in c.m.def.get("spawns", {}).values():
		c.occupied[Vector2i(int(s[0]), int(s[1]))] = true
	for w in c.m.def.get("warps", []):
		var r: Array = w["rect"]
		for z in range(int(r[1]) - 1, int(r[1]) + int(r[3]) + 1):
			for x in range(int(r[0]) - 1, int(r[0]) + int(r[2]) + 1):
				c.occupied[Vector2i(x, z)] = true
	for pen in c.m.def.get("pens", []):
		var r: Array = pen["rect"]
		for z in range(int(r[1]) - 1, int(r[1]) + int(r[3]) + 2):
			for x in range(int(r[0]) - 1, int(r[0]) + int(r[2]) + 1):
				c.occupied[Vector2i(x, z)] = true


static func _is(c: Ctx, x: int, z: int, chars: String) -> bool:
	return c.m.tile(x, z) in chars


static func _near(c: Ctx, x: int, z: int, chars: String, diag := true) -> bool:
	for dz in [-1, 0, 1]:
		for dx in [-1, 0, 1]:
			if (dx == 0 and dz == 0) or (not diag and dx != 0 and dz != 0):
				continue
			if c.m.tile(x + dx, z + dz) in chars:
				return true
	return false


static func _tile(c: Ctx, x: int, z: int) -> void:
	var ch := c.m.tile(x, z)
	var inf: Array = MapData.LEGEND.get(ch, MapData.LEGEND["X"])
	var p := Vector3(x, 0, z)
	var ground: String = inf[0]
	if ch == "S":
		ground = REGION_GROUND.get(c.region, "grass")
	var shade := c.rng.randf_range(0.93, 1.05)
	match ground:
		"water", "pond":
			c.water.append(Transform3D(Basis.from_scale(Vector3(1, 0.3, 1)), p + Vector3(0, -0.4, 0)))
			c.box("path" if c.region != "dunes" else "sand", p + Vector3(0, -0.62, 0), Vector3(1, 0.1, 1), 0.7)
		"paddy":
			c.box("paddy", p + Vector3(0, -0.3, 0), Vector3(1, 0.4, 1), shade)
		"cloud":
			c.box("cloud", p + Vector3(0, -1.6, 0), Vector3(1, 0.4, 1), shade)
		_:
			c.box(ground, p + Vector3(0, -0.25, 0), Vector3(1, 0.5, 1), shade)
	if ch == "S":
		_border(c, x, z)
		return
	# Platforms above the cloud sea get a rocky underside where they meet the clouds.
	if ground != "cloud" and c.region in ["pillars", "temple"] and _near(c, x, z, "uS", false):
		var depth := 1.4 + c.rng.randf() * 1.2
		c.box("karst", p + Vector3(0, -0.5 - depth / 2.0, 0), Vector3(1, depth, 1), 0.8)
		c.box("karst", p + Vector3(0, -0.5 - depth - 0.4, 0), Vector3(0.6, 0.8, 0.6), 0.7)
	# Grass fringe where paths and plazas meet grass.
	if ch in ".fc" and _near(c, x, z, "=_", false) and c.rng.randf() < 0.55:
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			if c.m.tile(x + d.x, z + d.y) in "=_":
				c.tuft("tallgrass", p + Vector3(d.x * 0.45, 0, d.y * 0.45) + Vector3(c.rng.randf_range(-0.3, 0.3), 0, 0) * absf(d.y) + Vector3(0, 0, c.rng.randf_range(-0.3, 0.3)) * absf(d.x), 0.45)
	match inf[1]:
		"":
			_decorate(c, x, z, ch)
		"tallgrass":
			for i in 3:
				c.tuft("tallgrass", p + c.jitter(), c.rng.randf_range(0.85, 1.1))
		"rice":
			c.tuft("rice", p + Vector3(-0.2, -0.1, -0.15), 0.9)
			c.tuft("rice", p + Vector3(0.22, -0.1, 0.2), 0.9)
		"flowers":
			c.prop(c.pick(c.theme["flowers"]), p + c.jitter() * 0.5, 1.0)
			c.prop(c.pick(c.theme["flowers"]), p + c.jitter(), 0.9)
		"drygrass", "reeds", "sapling":
			for i in 2:
				c.tuft(inf[1], p + c.jitter(), 0.9)
			if inf[1] == "sapling" and c.rng.randf() < 0.3:
				c.prop("fern", p + c.jitter() * 0.5, 0.8)
		"rock":
			var h := c.rng.randf_range(0.7, 1.4)
			c.box("rock" if c.region != "ridge" else "redrock", p + Vector3(0, h / 2.0, 0), Vector3(0.95, h, 0.95), shade, c.rng.randf_range(-0.2, 0.2))
			if c.rng.randf() < 0.5:
				c.prop(c.pick(c.theme["rocks"]), p + Vector3(c.rng.randf_range(-0.3, 0.3), 0, 0.45), 1.0)
			if c.rng.randf() < 0.3:
				c.tuft("tallgrass", p + Vector3(0.3, 0, 0.45), 0.7)
		"bamboo":
			c.box("moss" if c.region == "bamboo" else ground, p + Vector3(0, -0.24, 0), Vector3(1, 0.5, 1), 0.8)
			c.prop("bamboo_clump", p + Vector3(c.rng.randf_range(-0.25, 0.25), 0, c.rng.randf_range(-0.2, 0.2)), c.rng.randf_range(0.95, 1.25), 0.5)
			if c.rng.randf() < 0.45:
				c.prop("bamboo_clump", p + Vector3(c.rng.randf_range(-0.4, 0.4), 0, 0.35), c.rng.randf_range(0.8, 1.0))
			if c.rng.randf() < 0.25:
				c.prop("fern", p + Vector3(0, 0, 0.4), 0.9)
		"tree":
			c.prop(c.pick(c.theme["trees"]), p + Vector3(c.rng.randf_range(-0.12, 0.12), 0, 0.05), c.rng.randf_range(0.9, 1.15), 0.9)
			if c.rng.randf() < 0.4:
				c.prop(c.pick(c.theme["bushes"]), p + Vector3(c.rng.randf_range(-0.4, 0.4), 0, 0.4), 0.8)
		"pine":
			c.prop("tree_pine", p, c.rng.randf_range(0.9, 1.1), 0.8)
		"stone":
			c.box("stone", p + Vector3(0, 0.6, 0), Vector3(1, 1.2, 1), shade)
		"lantern":
			c.box("wood", p + Vector3(0, 0.7, 0), Vector3(0.12, 1.4, 0.12), 0.8)
			c.box("wood", p + Vector3(0, 1.38, 0.12), Vector3(0.1, 0.08, 0.34), 0.8)
			c.prop("lantern_red", p + Vector3(0, 0.82, 0.26), 1.2)
			if c.lights.size() < MAX_LIGHTS:
				var lamp := OmniLight3D.new()
				lamp.position = p + Vector3(0, 1.2, 0.3)
				lamp.light_color = Color("ffb35a")
				lamp.light_energy = 1.6
				lamp.omni_range = 4.5
				c.root.add_child(lamp)
				c.lights.append(lamp)
		"fence":
			var along_x := c.m.tile(x - 1, z) == "F" or c.m.tile(x + 1, z) == "F"
			c.box("wood", p + Vector3(0, 0.32, 0), Vector3(0.14, 0.64, 0.14), 0.9)
			for y in [0.22, 0.48]:
				c.box("wood", p + Vector3(0, y, 0), Vector3(1, 0.07, 0.06) if along_x else Vector3(0.06, 0.07, 1), 1.0)
		"pillar":
			_pillar(c, p)
		"stall":
			c.prop("stall", p + Vector3(0, 0, 0.1), 1.0, 0.9)
		"well":
			_well(c, p)
		"bridge":
			c.box("wood", p + Vector3(0, -0.1, 0), Vector3(1, 0.16, 0.9), shade)
			for sx in [-0.42, 0.42]:
				c.box("wood", p + Vector3(sx, 0.12, 0), Vector3(0.08, 0.3, 0.9) if c.m.tile(x, z - 1) == "#" or c.m.tile(x, z + 1) == "#" else Vector3(1, 0.3, 0.08), 0.8)
		"dune":
			var h := 0.5 + c.height01(x, z) * 1.1
			c.dune(p, h)
			if c.rng.randf() < 0.12:
				c.prop("shrub_desert", p + Vector3(0, h * 0.8, 0.2), 0.8)
		"danxia":
			_danxia(c, x, z, 1.2, 2.2)
		"karst":
			var h := c.rng.randf_range(2.0, 3.4)
			c.box("karst", p + Vector3(0, h * 0.3, 0), Vector3(1, h * 0.6, 1), shade)
			c.box("karst", p + Vector3(0, h * 0.75, 0), Vector3(0.7, h * 0.3, 0.7), shade)
			c.box("leaves", p + Vector3(0, h * 0.95, 0), Vector3(0.55, h * 0.15, 0.55), 0.9)
			if c.rng.randf() < 0.35:
				c.prop("tree_round", p + Vector3(0, h * 0.6, 0.3), 0.45)
		"stonepillar":
			var h := 2.6 + c.height01(x, z) * 2.6
			var y := -2.2
			var wdt := 1.0
			while y < h:
				var seg := minf(c.rng.randf_range(0.8, 1.4), h - y)
				c.box("pillarstone", p + Vector3(c.rng.randf_range(-0.05, 0.05), y + seg / 2.0, c.rng.randf_range(-0.05, 0.05)), Vector3(wdt, seg, wdt * 0.96), shade * c.rng.randf_range(0.9, 1.05), c.rng.randf_range(-0.3, 0.3))
				y += seg
				wdt = maxf(0.6, wdt - c.rng.randf_range(0.0, 0.1))
			c.box("moss", p + Vector3(0, h + 0.05, 0), Vector3(wdt + 0.06, 0.12, wdt + 0.06), 1.0)
			c.prop("tree_cloudpine", p + Vector3(0, h + 0.1, 0), 0.7)
			c.tuft("tallgrass", p + Vector3(0.2, h + 0.1, 0.25), 0.5)
		"altar":
			c.box("stone", p + Vector3(0, 0.4, 0), Vector3(0.95, 0.8, 0.95), shade)
			c.box("gold", p + Vector3(0, 0.85, 0), Vector3(0.5, 0.1, 0.5), 1.0)
		"nest":
			c.box("wood", p + Vector3(0, 0.25, 0), Vector3(1, 0.5, 1), 0.9)
			c.box("gold", p + Vector3(0, 0.55, 0), Vector3(0.6, 0.12, 0.6), 1.0)


## Walkable plain tiles: flowers, grass tufts, bushes at the edges, village things near houses.
static func _decorate(c: Ctx, x: int, z: int, ch: String) -> void:
	var p := Vector3(x, 0, z)
	var free: bool = not c.occupied.has(Vector2i(x, z))
	var town: bool = c.m.def.get("town", false) or c.m.id in ["weidendorf", "teeufer", "kreuzweg", "hof"]
	match ch:
		".", "c", "h", "s":
			var flowers: Array = c.theme["flowers"]
			if ch in ["." , "c"] and c.rng.randf() < P_FLOWERS:
				c.prop(c.pick(flowers), p + c.jitter(), c.rng.randf_range(0.8, 1.1))
			elif c.rng.randf() < P_TUFT:
				c.tuft("drygrass" if ch in ["h", "s"] else "tallgrass", p + c.jitter(), 0.55)
			if free and _near(c, x, z, "^BTkyQSmHRO", false) and c.rng.randf() < P_BUSH_EDGE:
				var list: Array = c.theme["bushes"] if ch != "s" else ["shrub_desert", "rock_sand"]
				c.prop(c.pick(list), p + c.jitter() * 0.6, c.rng.randf_range(0.75, 1.0), 0.5)
			elif free and c.rng.randf() < 0.025:
				c.prop(c.pick(c.theme["rocks"]), p + c.jitter(), 0.8)
			if free and town and _near(c, x, z, "HRO", false) and not _near(c, x, z, "D") and c.rng.randf() < P_VILLAGE:
				c.prop(c.pick(VILLAGE_PROPS), p + Vector3(c.rng.randf_range(-0.25, 0.25), 0, -0.25), 1.0, 0.4)
			if ch == "c" and _near(c, x, z, "u") and c.rng.randf() < 0.15:
				c.prop("cloud_wisp", p + Vector3(0, -0.8, 0) + c.jitter(), c.rng.randf_range(0.8, 1.2))
		"=":
			if c.rng.randf() < 0.05:
				c.prop("rock_small", p + c.jitter(), 0.5)
		"_":
			if free and town and _near(c, x, z, "HROL", false) and c.rng.randf() < 0.12:
				c.prop(c.pick(["jar", "jars_group", "basket_veg", "crate"]), p + c.jitter() * 0.5, 1.0, 0.4)
		"~":
			if _near(c, x, z, ".,=_shcfTB", false) and c.rng.randf() < P_REEDS:
				c.prop("reeds" if c.region != "dunes" or c.rng.randf() < 0.6 else "tree_datepalm", p + c.jitter() * 0.6, c.rng.randf_range(0.8, 1.1))
			elif not _near(c, x, z, "#") and c.rng.randf() < P_LOTUS and c.region in ["bamboo", "river", "hub"]:
				c.prop("lotus_pads", p + Vector3(0, -0.24, 0) + c.jitter(), 1.0)
				if c.rng.randf() < 0.4:
					c.prop("lotus_flower", p + Vector3(0, -0.26, 0) + c.jitter() * 0.3, 0.9)


## Map edge in the region's look: forest, bamboo, red rocks, dunes or clouds.
static func _border(c: Ctx, x: int, z: int) -> void:
	var p := Vector3(x, 0, z)
	match c.region:
		"pillars", "temple":
			c.boxes["cloudstone"].pop_back()
			c.box("cloud", p + Vector3(0, -1.6, 0), Vector3(1, 0.4, 1), 1.0)
			if c.rng.randf() < 0.35:
				c.prop("cloud_wisp", p + Vector3(0, -0.9, 0) + c.jitter(), c.rng.randf_range(1.0, 1.6))
		"dunes":
			var h := (0.4 if c.south(z) else 0.7) + c.height01(x, z) * (0.4 if c.south(z) else 1.2)
			c.dune(p, h)
			if c.rng.randf() < 0.15:
				c.prop("shrub_desert" if c.south(z) else c.pick(c.theme["border"]), p + Vector3(0, h * 0.7, 0.3), 0.9)
		"ridge":
			if c.south(z):
				c.mound("redrock", p, Vector3(1.4, 0.7, 1.3), 0.95)
				if c.rng.randf() < 0.4:
					c.prop(c.pick(["shrub_desert", "rock_red"]), p + Vector3(0, 0.25, 0.3), 0.9)
			else:
				_danxia(c, x, z, 1.4, 2.4)
		_:
			c.box("moss" if c.region == "bamboo" else "grass", p + Vector3(0, -0.24, 0), Vector3(1, 0.5, 1), 0.75)
			if c.south(z):
				# Low hedge of bushes and flowers: closes the map without hiding the player.
				c.prop(c.pick(c.theme["bushes"]), p + Vector3(c.rng.randf_range(-0.3, 0.3), 0, 0), c.rng.randf_range(0.9, 1.2), 0.5)
				if c.rng.randf() < 0.6:
					c.prop(c.pick(c.theme["flowers"]), p + Vector3(c.rng.randf_range(-0.4, 0.4), 0, 0.35), 1.0)
				return
			var id := c.pick(c.theme["border"])
			c.prop(id, p + Vector3(c.rng.randf_range(-0.2, 0.2), 0, c.rng.randf_range(-0.2, 0.2)), c.rng.randf_range(1.0, 1.3), 0.9)
			if c.rng.randf() < 0.5:
				c.prop(c.pick(c.theme["bushes"]), p + Vector3(c.rng.randf_range(-0.4, 0.4), 0, 0.42), 0.9)


## Land beyond the map edge: the camera sometimes sees past it, so the world goes on.
static func _outside(c: Ctx) -> void:
	var ground: String = REGION_GROUND.get(c.region, "grass")
	for z in range(-OUTSIDE_RING, c.m.height + OUTSIDE_RING):
		for x in range(-OUTSIDE_RING, c.m.width + OUTSIDE_RING):
			if x >= 0 and z >= 0 and x < c.m.width and z < c.m.height:
				continue
			var p := Vector3(x, 0, z)
			if c.region in ["pillars", "temple"]:
				c.box("cloud", p + Vector3(0, -1.6, 0), Vector3(1, 0.4, 1), 1.0)
				if c.rng.randf() < 0.12:
					c.prop("cloud_wisp", p + Vector3(0, -1.0, 0) + c.jitter(), c.rng.randf_range(1.2, 2.0))
				continue
			var near_edge := x >= -2 and z >= -2 and x <= c.m.width + 1 and z <= c.m.height + 1
			c.box(ground, p + Vector3(0, -0.25, 0), Vector3(1, 0.5, 1), c.rng.randf_range(0.7, 0.85))
			if z >= c.m.height:
				if c.rng.randf() < 0.25 and c.region not in ["dunes", "ridge"]:
					c.prop(c.pick(c.theme["bushes"]), p + c.jitter(), 1.0)
				continue
			if c.region == "dunes":
				var h := 0.3 + c.height01(x, z) * 1.8
				c.dune(p, h)
			elif c.region == "ridge":
				_danxia(c, x, z, 1.6, 3.2)
			elif c.rng.randf() < (0.75 if near_edge else 0.45):
				c.prop(c.pick(c.theme["border"]), p + c.jitter(), c.rng.randf_range(1.0, 1.4))


## Danxia sandstone: terraces of striped rock, heights coherent across neighbours,
## narrowing a little towards the top, with dry grass and the odd tree on top.
static func _danxia(c: Ctx, x: int, z: int, lo: float, span: float) -> void:
	var p := Vector3(x, 0, z)
	# Heights in steps of half a unit: neighbours share them, so the rock reads as terraces.
	var h := lo + snappedf(c.height01(x, z) * span, 0.5)
	c.box("danxia", p + Vector3(0, h / 2.0, 0), Vector3(1, h, 1), 1.0)
	c.box("redrock", p + Vector3(0, h + 0.03, 0), Vector3(1.0, 0.06, 1.0), 1.0)
	if c.rng.randf() < 0.3:
		c.tuft("drygrass", p + Vector3(c.rng.randf_range(-0.3, 0.3), h, c.rng.randf_range(-0.3, 0.3)), 0.6)
	if c.rng.randf() < 0.07:
		c.prop(c.pick(["tree_pine", "tree_maple", "shrub_desert"]), p + Vector3(0, h, 0), 0.7)


static func _pillar(c: Ctx, p: Vector3) -> void:
	var mi := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.24
	cyl.bottom_radius = 0.26
	cyl.height = 2.6
	cyl.radial_segments = 10
	mi.mesh = cyl
	mi.material_override = Materials.flat_color(Color("b02e28"))
	mi.position = p + Vector3(0, 1.4, 0)
	c.root.add_child(mi)
	c.box("stone", p + Vector3(0, 0.08, 0), Vector3(0.7, 0.16, 0.7), 1.0)
	c.box("gold", p + Vector3(0, 2.5, 0), Vector3(0.6, 0.12, 0.6), 1.0)
	c.box("roof_grey", p + Vector3(0, 2.72, 0), Vector3(0.75, 0.3, 0.75), 1.0)


static func _well(c: Ctx, p: Vector3) -> void:
	var mi := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.42
	cyl.bottom_radius = 0.45
	cyl.height = 0.6
	cyl.radial_segments = 12
	mi.mesh = cyl
	mi.material_override = Materials.surface("stone")
	mi.position = p + Vector3(0, 0.3, 0)
	c.root.add_child(mi)
	c.water.append(Transform3D(Basis.from_scale(Vector3(0.6, 0.05, 0.6)), p + Vector3(0, 0.55, 0)))
	for sx in [-0.4, 0.4]:
		c.box("wood", p + Vector3(sx, 0.85, 0), Vector3(0.08, 1.1, 0.08), 0.8)
	c.box("roof_red", p + Vector3(0, 1.45, 0), Vector3(1.05, 0.14, 0.7), 1.0)
	c.prop("well_bucket", p + Vector3(0.25, 0.6, 0.3), 0.8)


# --- meshes -------------------------------------------------------------------

static func _flush(c: Ctx, silent: bool) -> void:
	# Far land under everything, for views past the decorated ring.
	var far := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(c.m.width + 80, c.m.height + 80)
	var ground: String = REGION_GROUND.get(c.region, "grass")
	plane.material = Materials.surface("cloud" if c.region in ["pillars", "temple"] else ground, Color(0.62, 0.66, 0.62))
	far.mesh = plane
	far.position = Vector3(c.m.width / 2.0 - 0.5, -1.9 if c.region in ["pillars", "temple"] else -0.52, c.m.height / 2.0 - 0.5)
	far.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	c.root.add_child(far)
	for kind in c.boxes:
		var mesh := BoxMesh.new()
		mesh.material = Materials.surface(kind)
		if kind == "cloud":
			var mat := Materials.surface("cloud").duplicate() as StandardMaterial3D
			mat.emission_enabled = true
			mat.emission = Color("dfe6ee")
			mat.emission_energy_multiplier = 0.25
			mesh.material = mat
		elif kind == "gold":
			var mat := Materials.surface("gold").duplicate() as StandardMaterial3D
			mat.metallic = 0.6
			mat.roughness = 0.35
			mesh.material = mat
		c.root.add_child(_multimesh(mesh, c.boxes[kind], true))
	for kind in c.mounds:
		var sm := SphereMesh.new()
		sm.radius = 0.5
		sm.height = 1.0
		sm.radial_segments = 12
		sm.rings = 6
		sm.material = Materials.surface(kind)
		c.root.add_child(_multimesh(sm, c.mounds[kind], true))
	if not c.water.is_empty():
		var wm := BoxMesh.new()
		wm.material = Materials.water(not silent)
		var list := []
		for t in c.water:
			list.append([t, Color.WHITE])
		var mmi := _multimesh(wm, list, false)
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		c.root.add_child(mmi)
	for kind in c.tufts:
		c.root.add_child(_tufts(kind, c.tufts[kind]))
	for id in c.props:
		c.root.add_child(_props(id, c.props[id]))
	for id in c.flats:
		var tex := Props.texture(id)
		var pm := PlaneMesh.new()
		pm.size = Vector2(tex.get_width(), tex.get_height()) / CameraRig.PIXELS_PER_UNIT
		pm.material = Materials.flat_prop(id)
		var list := []
		for f in c.flats[id]:
			list.append([Transform3D(Basis(Vector3.UP, f[2]).scaled(Vector3.ONE * f[1]), f[0]), Color.WHITE])
		var mmi := _multimesh(pm, list, false)
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		c.root.add_child(mmi)
	if not c.shadows.is_empty():
		var q := PlaneMesh.new()
		q.size = Vector2(1, 0.7)
		q.material = Materials.blob_shadow()
		var list := []
		for s in c.shadows:
			list.append([Transform3D(Basis.from_scale(Vector3.ONE * float(s[1]) * 1.3), s[0] + Vector3(0, 0.012, 0.05)), Color.WHITE])
		var mmi := _multimesh(q, list, false)
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		c.root.add_child(mmi)


static func _props(id: String, list: Array) -> MultiMeshInstance3D:
	var tex := Props.texture(id)
	var q := QuadMesh.new()
	var size := Vector2(tex.get_width(), tex.get_height()) / CameraRig.PIXELS_PER_UNIT
	q.size = size
	q.center_offset = Vector3(0, size.y / 2.0, 0)
	q.material = Materials.prop(id)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = true
	mm.mesh = q
	mm.instance_count = list.size()
	for i in list.size():
		var e: Array = list[i]
		mm.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3.ONE * float(e[1])), e[0]))
		mm.set_instance_custom_data(i, Color(float(e[2]), 1.0, 0, 0))
	var inst := MultiMeshInstance3D.new()
	inst.multimesh = mm
	var small: bool = size.y < 1.0
	inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF if small or id == "cloud_wisp" else GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	return inst


static func _tufts(kind: String, transforms: Array) -> MultiMeshInstance3D:
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/tuft.gdshader")
	mat.set_shader_parameter("tex", PixelArt.tuft(kind))
	mat.set_shader_parameter("sway", 0.1 if kind in ["tallgrass", "reeds", "drygrass"] else 0.05)
	var mesh := QuadMesh.new()
	mesh.size = Vector2(1.0, 0.75)
	mesh.center_offset = Vector3(0, 0.375, 0)
	mesh.material = mat
	var list := []
	for t in transforms:
		list.append([t, Color.WHITE])
	var mmi := _multimesh(mesh, list, false)
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mmi


static func _multimesh(mesh: Mesh, entries: Array, colors: bool) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = colors
	mm.mesh = mesh
	mm.instance_count = entries.size()
	for i in entries.size():
		mm.set_instance_transform(i, entries[i][0])
		if colors:
			mm.set_instance_color(i, entries[i][1])
	var inst := MultiMeshInstance3D.new()
	inst.multimesh = mm
	return inst
