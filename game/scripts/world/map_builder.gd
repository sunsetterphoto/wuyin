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
	var foam: Array = []  # [Vector3 pos, float yrot] strips where water meets land
	var mounds := {}  # surface kind -> [[Transform3D, Color]] (rounded sphere mounds: dunes, boulders)
	var noise := FastNoiseLite.new()

	## Smooth 0..1 value per tile, so neighbouring cliffs have similar heights.
	func height01(x: int, z: int) -> float:
		return clampf(noise.get_noise_2d(x * 9.0, z * 9.0) * 0.5 + 0.5, 0.0, 1.0)

	func mound(kind: String, pos: Vector3, size: Vector3, shade := 1.0, yrot := 0.0) -> void:
		if not mounds.has(kind):
			mounds[kind] = []
		mounds[kind].append([Transform3D(Basis(Vector3.UP, yrot).scaled(size), pos), Color(shade, shade, shade)])

	var cones := {}  # kind -> [[Transform3D, Color]] (unit cone: base radius 1, top 0.3, height 1)

	func cone(kind: String, center: Vector3, h: float, r: float, top: float) -> void:
		if not cones.has(kind):
			cones[kind] = []
		cones[kind].append([Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(r, h, r)), center), Color.WHITE * rng.randf_range(0.92, 1.05)])

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
	if m.def.get("indoor", false):
		_room(c)
		_flush(c, false)
		return {"root": c.root, "lights": c.lights}
	for b in Buildings.find(m):
		Buildings.build(b, c.root, c.lights, MAX_LIGHTS, 0.0 if silent else 1.0)
	for z in m.height:
		for x in m.width:
			_tile(c, x, z)
	# Hand-placed decoration of the map (towns, farm, temple): {"prop", "at": [x, z], "scale", "y"}.
	for d in m.def.get("decor", []):
		var at: Array = d["at"]
		c.prop(d["prop"], Vector3(float(at[0]), float(d.get("y", 0.0)), float(at[1])), float(d.get("scale", 1.0)), float(d.get("shadow", 0.5)))
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
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var n: Array = MapData.LEGEND.get(c.m.tile(x + d.x, z + d.y), MapData.LEGEND["X"])
				if n[0] not in ["water", "pond", "cloud"] and n[1] != "bridge":
					c.foam.append([p + Vector3(d.x * 0.42, -0.245, d.y * 0.42), 0.0 if d.x == 0 else PI / 2.0])
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
			# Karst cone (Li river style): steep rock, rounded green crown, a tree clinging to it.
			var h := 2.2 + c.height01(x, z) * 2.2
			c.cone("karst", p + Vector3(c.rng.randf_range(-0.1, 0.1), h / 2.0, 0), h, c.rng.randf_range(0.78, 0.92), 0.3)
			c.mound("leaves", p + Vector3(0, h - 0.1, 0), Vector3(0.95, 0.8, 0.95), 0.9)
			for k in 2:
				var yy := h * c.rng.randf_range(0.3, 0.75)
				var rr := 0.85 * (1.0 - 0.7 * yy / h) + 0.05
				c.prop(c.pick(["bush_round", "fern", "bush_round"]), p + Vector3(c.rng.randf_range(-0.3, 0.3), yy, rr), 0.7)
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
			elif c.region == "river" and z < 0 and c.rng.randf() < 0.3:
				var h := 3.0 + c.rng.randf() * 3.0
				c.cone("karst", p + Vector3(0, h / 2.0, 0), h, c.rng.randf_range(1.0, 1.3), 0.3)
				c.mound("leaves", p + Vector3(0, h - 0.1, 0), Vector3(1.2, 0.9, 1.2), 0.85)
			elif c.rng.randf() < (0.75 if near_edge else 0.45):
				c.prop(c.pick(c.theme["border"]), p + c.jitter(), c.rng.randf_range(1.0, 1.4))


# --- interiors -------------------------------------------------------------------

const WALL_H := 2.3


## A room in cut-away view: wooden floor, plastered back and side walls with
## posts, beams, lattice windows and scrolls, a low front wall, furniture,
## props and warm lamps.
static func _room(c: Ctx) -> void:
	var m := c.m
	for z in m.height:
		for x in m.width:
			var p := Vector3(x, 0, z)
			var ch := m.tile(x, z)
			c.box("floor", p + Vector3(0, -0.25, 0), Vector3(1, 0.5, 1), c.rng.randf_range(0.94, 1.03))
			if ch != "S":
				continue
			if z == m.height - 1:
				c.box("wood", p + Vector3(0, 0.15, 0), Vector3(1, 0.3, 0.3), 0.8)
			elif z == 0 or x == 0 or x == m.width - 1:
				c.box("plaster", p + Vector3(0, WALL_H / 2.0, 0), Vector3(1, WALL_H, 1), 1.0)
				c.box("wood", p + Vector3(0, 0.12, 0.505 if z == 0 else 0.0), Vector3(1.0, 0.24, 0.02 if z == 0 else 1.02), 0.75)
	# Posts and a beam along the back wall, windows and a scroll painting.
	for x in range(1, m.width - 1, 3):
		c.box("wood", Vector3(x - 0.5, WALL_H / 2.0, 0.52), Vector3(0.14, WALL_H, 0.06), 0.7)
	c.box("wood", Vector3(m.width / 2.0 - 0.5, WALL_H - 0.12, 0.53), Vector3(m.width - 2, 0.16, 0.08), 0.7)
	var lattice := Buildings._lattice_material("H")
	for x in [2, m.width - 3]:
		Buildings._quad(c.root, Vector3(x, 1.35, 0.55), Vector2(0.9, 0.7), lattice)
	for f in m.def.get("furniture", []):
		_furniture(c, f)
	for l in m.def.get("lights", []):
		var lamp := OmniLight3D.new()
		lamp.position = Vector3(float(l[0]), 1.7, float(l[1]) + 0.6)
		lamp.light_color = Color("ffc070")
		lamp.light_energy = 1.4
		lamp.omni_range = 6.0
		c.root.add_child(lamp)
		c.lights.append(lamp)
		c.prop("lantern_red", Vector3(float(l[0]), 1.55, float(l[1]) - 0.2), 1.1)
	for d in m.def.get("decor", []):
		var at: Array = d["at"]
		c.prop(d["prop"], Vector3(float(at[0]), float(d.get("y", 0.0)), float(at[1])), float(d.get("scale", 1.0)), 0.4)


static func _furniture(c: Ctx, f: Dictionary) -> void:
	var r: Array = f["rect"]
	var x0 := float(r[0]) - 0.5
	var z0 := float(r[1]) - 0.5
	var w := float(r[2])
	var d := float(r[3])
	var ctr := Vector3(x0 + w / 2.0, 0, z0 + d / 2.0)
	var wood := Materials.flat_color(Color("8a5b36"))
	var dark := Materials.flat_color(Color("5a3a22"))
	match f["kind"]:
		"bed":
			_fbox(c, ctr + Vector3(0, 0.18, 0), Vector3(w - 0.1, 0.36, d - 0.1), dark)
			_fbox(c, ctr + Vector3(0, 0.42, 0), Vector3(w - 0.2, 0.14, d - 0.2), Materials.flat_color(Color("f4efe6")))
			_fbox(c, ctr + Vector3(0, 0.5, d * 0.12), Vector3(w - 0.16, 0.1, d * 0.62), Materials.flat_color(Color("c8302a")))
			_fbox(c, ctr + Vector3(0, 0.53, d * 0.12), Vector3(w * 0.5, 0.11, d * 0.5), Materials.flat_color(Color("e0b04a")))
			_fbox(c, ctr + Vector3(0, 0.52, -d / 2.0 + 0.3), Vector3(w * 0.6, 0.12, 0.3), Materials.flat_color(Color("fff8e8")))
			_fbox(c, ctr + Vector3(0, 0.55, -d / 2.0 + 0.08), Vector3(w - 0.1, 0.9, 0.12), dark)
		"counter", "workbench":
			_fbox(c, ctr + Vector3(0, 0.42, 0), Vector3(w - 0.06, 0.84, d - 0.2), wood)
			_fbox(c, ctr + Vector3(0, 0.87, 0), Vector3(w + 0.04, 0.08, d - 0.08), dark)
			_fbox(c, ctr + Vector3(0, 0.42, d / 2.0 - 0.08), Vector3(w - 0.3, 0.6, 0.02), Materials.flat_color(Color("a8302a")))
			if f["kind"] == "workbench":
				for i in 3:
					_fbox(c, ctr + Vector3(-w / 2.0 + 0.6 + i * 0.9, 0.98, 0), Vector3(0.3, 0.14, 0.2), Materials.flat_color(Color("a9b1bb")))
		"shelf":
			# Open shelf against the back wall: back panel, sides, three boards with jars and boxes.
			var back := z0 + 0.12
			_fbox(c, Vector3(ctr.x, 0.88, back), Vector3(w - 0.06, 1.76, 0.06), dark)
			for sx in [x0 + 0.06, x0 + w - 0.06]:
				_fbox(c, Vector3(sx, 0.88, back + 0.2), Vector3(0.08, 1.76, 0.42), dark)
			var cols := [Color("3b7e8f"), Color("c8502c"), Color("e0b04a"), Color("7a5a80"), Color("5fae8a"), Color("f4efe6"), Color("8e2e23")]
			for row in 3:
				var by := 0.3 + row * 0.55
				_fbox(c, Vector3(ctr.x, by, back + 0.2), Vector3(w - 0.14, 0.05, 0.4), wood)
				var cx := x0 + 0.22
				while cx < x0 + w - 0.2:
					var hh := c.rng.randf_range(0.14, 0.32)
					var ww := c.rng.randf_range(0.12, 0.2)
					if c.rng.randf() < 0.85:
						_fbox(c, Vector3(cx, by + 0.03 + hh / 2.0, back + 0.22), Vector3(ww, hh, 0.16),
							Materials.flat_color(cols[c.rng.randi_range(0, cols.size() - 1)]))
					cx += ww + c.rng.randf_range(0.04, 0.12)
		"stove":
			_fbox(c, ctr + Vector3(0, 0.38, 0), Vector3(w - 0.1, 0.76, d - 0.15), Materials.surface("stone"))
			_fbox(c, ctr + Vector3(0, 0.25, d / 2.0 - 0.05), Vector3(0.4, 0.25, 0.05), Materials.flat_color(Color("ff8a3a"), 2.0))
			var pot := MeshInstance3D.new()
			var sm := SphereMesh.new()
			sm.radius = 0.24
			sm.height = 0.36
			pot.mesh = sm
			pot.material_override = Materials.flat_color(Color("2a2230"))
			pot.position = ctr + Vector3(-w / 4.0, 0.92, 0)
			c.root.add_child(pot)
			if c.lights.size() < MAX_LIGHTS:
				var glow := OmniLight3D.new()
				glow.position = ctr + Vector3(0, 0.35, d / 2.0 + 0.2)
				glow.light_color = Color("ff8a3a")
				glow.light_energy = 0.8
				glow.omni_range = 2.5
				c.root.add_child(glow)
				c.lights.append(glow)
		"table":
			_fbox(c, ctr + Vector3(0, 0.5, 0), Vector3(w - 0.15, 0.08, d - 0.15), wood)
			for sx in [-1, 1]:
				for sz in [-1, 1]:
					_fbox(c, ctr + Vector3(sx * (w / 2.0 - 0.15), 0.25, sz * (d / 2.0 - 0.15)), Vector3(0.07, 0.5, 0.07), dark)
		"chest":
			_fbox(c, ctr + Vector3(0, 0.25, 0), Vector3(0.8, 0.5, 0.6), Materials.flat_color(Color("a8302a")))
			_fbox(c, ctr + Vector3(0, 0.52, 0), Vector3(0.84, 0.06, 0.64), Materials.flat_color(Color("e0b04a"), 0.2))
		"rug":
			_fbox(c, ctr + Vector3(0, 0.012, 0), Vector3(w - 0.1, 0.02, d - 0.1), Materials.flat_color(Color("e0b04a")))
			_fbox(c, ctr + Vector3(0, 0.02, 0), Vector3(w - 0.3, 0.02, d - 0.3), Materials.flat_color(Color("a8302a")))
		"cushion":
			_fbox(c, ctr + Vector3(0, 0.06, 0), Vector3(0.6, 0.12, 0.6), Materials.flat_color(Color("c8302a")))
		"scroll":
			var img := Image.create(12, 24, false, Image.FORMAT_RGBA8)
			img.fill(Color("f4ead0"))
			img.fill_rect(Rect2i(0, 0, 12, 2), Color("5a3a22"))
			img.fill_rect(Rect2i(0, 22, 12, 2), Color("5a3a22"))
			for i in 9:
				img.set_pixel(2 + i, 16 - int(sin(i * 0.9) * 4.0 + i * 0.3), Color("3a3046"))
				img.set_pixel(2 + i, 17 - int(sin(i * 0.9) * 4.0 + i * 0.3), Color("6a6478"))
			img.fill_rect(Rect2i(8, 4, 2, 2), Color("c8302a"))
			var mat := StandardMaterial3D.new()
			mat.albedo_texture = ImageTexture.create_from_image(img)
			mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
			Buildings._quad(c.root, Vector3(ctr.x, 1.3, 0.56), Vector2(0.5, 1.0), mat)


static func _fbox(c: Ctx, pos: Vector3, size: Vector3, mat: Material) -> void:
	Buildings._box(c.root, pos, size, mat)


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
	if not c.m.def.get("indoor", false):
		_far_land(c)
	_meshes(c, silent)


## Far land under everything, for views past the decorated ring.
static func _far_land(c: Ctx) -> void:
	var far := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(c.m.width + 80, c.m.height + 80)
	var ground: String = REGION_GROUND.get(c.region, "grass")
	plane.material = Materials.surface("cloud" if c.region in ["pillars", "temple"] else ground, Color(0.62, 0.66, 0.62))
	far.mesh = plane
	far.position = Vector3(c.m.width / 2.0 - 0.5, -1.9 if c.region in ["pillars", "temple"] else -0.52, c.m.height / 2.0 - 0.5)
	far.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	c.root.add_child(far)


static func _meshes(c: Ctx, silent: bool) -> void:
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
	for kind in c.cones:
		var cm := CylinderMesh.new()
		cm.bottom_radius = 1.0
		cm.top_radius = 0.3
		cm.height = 1.0
		cm.radial_segments = 9
		cm.rings = 2
		cm.material = Materials.surface(kind, Color(0.66, 0.78, 0.62) if kind == "karst" else Color.WHITE)
		c.root.add_child(_multimesh(cm, c.cones[kind], true))
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
	if not c.foam.is_empty():
		var fm := PlaneMesh.new()
		fm.size = Vector2(1.0, 0.16)
		var mat := ShaderMaterial.new()
		mat.shader = load("res://shaders/foam.gdshader")
		fm.material = mat
		var list := []
		for f in c.foam:
			list.append([Transform3D(Basis(Vector3.UP, f[1]), f[0]), Color.WHITE])
		var fmi := _multimesh(fm, list, false)
		fmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		c.root.add_child(fmi)
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
