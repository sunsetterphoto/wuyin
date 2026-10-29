class_name MapData
extends RefCounted
## One overworld map from res://data/maps/<id>.json (rule 4: maps are data).
## The ground is an ASCII grid (one character per 32 px tile, see LEGEND);
## everything else (spawns, warps, people, Lingshou, triggers, encounters)
## lives in lists next to it. Entries may carry "when" / "unless" flag
## conditions (string or list of strings).

const DIR := "res://data/maps/"

## Character -> [ground kind, block kind or "", walkable, tall grass]
const LEGEND := {
	".": ["grass", "", true, false],
	",": ["grass", "tallgrass", true, true],
	"=": ["path", "", true, false],
	"_": ["plaza", "", true, false],
	"#": ["water", "bridge", true, false],
	"~": ["water", "", false, false],
	"r": ["paddy", "rice", true, true],
	"f": ["grass", "flowers", true, false],
	"S": ["grass", "stone", false, false],
	"^": ["grass", "rock", false, false],
	"B": ["grass", "bamboo", false, false],
	"T": ["grass", "tree", false, false],
	"H": ["grass", "house", false, false],
	"R": ["grass", "house_red", false, false],
	"D": ["path", "door", false, false],
	"L": ["path", "lantern", false, false],
	"F": ["grass", "fence", false, false],
	"P": ["plaza", "pillar", false, false],
	"t": ["plaza", "stall", false, false],
	"W": ["grass", "well", false, false],
	"X": ["grass", "", false, false],
	# Regions after the Bamboo Sea.
	"s": ["sand", "", true, false],
	"z": ["sand", "drygrass", true, true],
	"m": ["sand", "dune", false, false],
	"h": ["redrock", "", true, false],
	"v": ["redrock", "drygrass", true, true],
	"y": ["redrock", "danxia", false, false],
	"k": ["grass", "karst", false, false],
	"q": ["grass", "reeds", true, true],
	"u": ["cloud", "", false, false],
	"c": ["cloudstone", "", true, false],
	"Q": ["cloudstone", "stonepillar", false, false],
	"n": ["grass", "pine", false, false],
	"O": ["grass", "house_grey", false, false],
	"A": ["plaza", "altar", false, false],
	"N": ["plaza", "nest", false, false],
	# Farm pens (GDD "Gehege"): ground by pen type, walkable for the Lingshou inside.
	"p": ["pond", "", true, false],
	"b": ["grass", "sapling", true, false],
	"e": ["ember", "", true, false],
	"g": ["ore", "", true, false],
	"a": ["gravel", "", true, false],
	"w": ["floor", "", true, false],
	"Y": ["floor", "", false, false],
}
## Pen type -> ground character (see LEGEND).
const PEN_TILES := {"pond": "p", "bamboo": "b", "ember": "e", "ore": "g", "rock": "a", "empty": "."}

var id := ""
var def: Dictionary = {}
var rows: Array[String] = []
var width := 0
var height := 0
## Tiles changed at runtime (farm pens): Vector2i -> character.
var overrides := {}
## Ground height per tile in world units (terraces, ramps); built lazily from def "heights".
var _heights := {}
var _heights_built := false


static func exists(map_id: String) -> bool:
	return FileAccess.file_exists(DIR + map_id + ".json")


static func load_map(map_id: String) -> MapData:
	var m := MapData.new()
	m.id = map_id
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(DIR + map_id + ".json")) != OK:
		push_error("map %s: %s (line %d)" % [map_id, json.get_error_message(), json.get_error_line()])
		return null
	m.def = json.data
	for r in m.def.get("rows", []):
		m.rows.append(r)
	m.height = m.rows.size()
	for r in m.rows:
		m.width = maxi(m.width, r.length())
	return m


static func all_ids() -> Array[String]:
	var out: Array[String] = []
	for f in DirAccess.get_files_at(DIR):
		if f.ends_with(".json"):
			out.append(f.get_basename())
	return out


func tile(x: int, z: int) -> String:
	if not overrides.is_empty() and overrides.has(Vector2i(x, z)):
		return overrides[Vector2i(x, z)]
	if z < 0 or z >= height or x < 0 or x >= rows[z].length():
		return "X"
	return rows[z][x]


func info(x: int, z: int) -> Array:
	return LEGEND.get(tile(x, z), LEGEND["X"])


## Height of the ground on a tile: {"rect": [x, z, w, h], "h": units} raises a block,
## {"rect", "h", "ramp": "n"|"s"|"e"|"w"} rises towards that side (stairs, slopes).
func height_at(x: int, z: int) -> float:
	if not _heights_built:
		_heights_built = true
		for e in def.get("heights", []):
			var r: Array = e["rect"]
			var top := float(e.get("h", 0.5))
			var base := float(e.get("from", 0.0))
			for zz in range(int(r[1]), int(r[1]) + int(r[3])):
				for xx in range(int(r[0]), int(r[0]) + int(r[2])):
					var v := top
					match e.get("ramp", ""):
						"n":
							v = lerpf(base, top, float(int(r[1]) + int(r[3]) - zz) / (float(r[3]) + 1.0))
						"s":
							v = lerpf(base, top, float(zz - int(r[1]) + 1) / (float(r[3]) + 1.0))
						"e":
							v = lerpf(base, top, float(xx - int(r[0]) + 1) / (float(r[2]) + 1.0))
						"w":
							v = lerpf(base, top, float(int(r[0]) + int(r[2]) - xx) / (float(r[2]) + 1.0))
					_heights[Vector2i(xx, zz)] = v
	return float(_heights.get(Vector2i(x, z), 0.0))


func walkable(x: int, z: int) -> bool:
	return info(x, z)[2]


func is_grass(x: int, z: int) -> bool:
	return info(x, z)[3]


func spawn(name: String) -> Vector2:
	var s: Array = def.get("spawns", {}).get(name, def.get("spawns", {}).values()[0])
	return Vector2(s[0], s[1])


func name_key() -> String:
	return def.get("name", "")


## Does the entry's when/unless condition hold for the given flags?
static func condition_ok(entry: Dictionary, state: GameState) -> bool:
	for f in _as_list(entry.get("when", [])):
		if not state.flag(f):
			return false
	for f in _as_list(entry.get("unless", [])):
		if state.flag(f):
			return false
	return true


static func _as_list(v: Variant) -> Array:
	if v is String:
		return [] if v == "" else [v]
	return v


static func in_rect(p: Vector2i, rect: Array) -> bool:
	return p.x >= int(rect[0]) and p.y >= int(rect[1]) and p.x < int(rect[0]) + int(rect[2]) and p.y < int(rect[1]) + int(rect[3])


## Shortest walkable path (4-neighbour BFS) from a to b, excluding a; empty when unreachable.
func path(a: Vector2i, b: Vector2i, max_nodes := 4000) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	if a == b or not walkable(b.x, b.y):
		return out
	var prev := {a: a}
	var queue: Array[Vector2i] = [a]
	var head := 0
	while head < queue.size() and head < max_nodes:
		var c: Vector2i = queue[head]
		head += 1
		if c == b:
			break
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var n: Vector2i = c + d
			if not prev.has(n) and walkable(n.x, n.y) and absf(height_at(n.x, n.y) - height_at(c.x, c.y)) <= 0.36:
				prev[n] = c
				queue.append(n)
	if not prev.has(b):
		return out
	var c := b
	while c != a:
		out.push_front(c)
		c = prev[c]
	return out


## Problems in this map's data; empty = valid.
func validate() -> Array[String]:
	var errors: Array[String] = []
	for z in height:
		if rows[z].length() != width:
			errors.append("%s: row %d has length %d, expected %d" % [id, z, rows[z].length(), width])
		for c in rows[z]:
			if not LEGEND.has(c):
				errors.append("%s: unknown tile '%s' in row %d" % [id, c, z])
	if not String(def.get("name", "")).begins_with("MAP_"):
		errors.append("%s: name must be a translation key MAP_*" % id)
	for sname in def.get("spawns", {}):
		var p: Array = def["spawns"][sname]
		if not walkable(int(p[0]), int(p[1])):
			errors.append("%s: spawn %s at %s is not walkable" % [id, sname, p])
	for w in def.get("warps", []):
		if not exists(w.get("to", "")):
			errors.append("%s: warp to unknown map %s" % [id, w.get("to")])
		elif not MapData.load_map(w["to"]).def.get("spawns", {}).has(w.get("spawn", "")):
			errors.append("%s: warp to %s has unknown spawn %s" % [id, w["to"], w.get("spawn")])
	for list_name in ["npcs", "objects", "lingshou"]:
		for e in def.get(list_name, []):
			var p: Array = e.get("at", [0, 0])
			if list_name == "lingshou" and not walkable(int(p[0]), int(p[1])):
				errors.append("%s: lingshou %s stands on a blocked tile" % [id, e.get("species")])
			if e.has("event") and not EventRunner.has_event(e["event"]):
				errors.append("%s: %s refers to unknown event %s" % [id, list_name, e["event"]])
			if list_name == "lingshou" and not e.get("species", "") in GameData.lingshou_ids():
				errors.append("%s: unknown species %s" % [id, e.get("species")])
	for t in def.get("triggers", []):
		if not EventRunner.has_event(t.get("event", "")):
			errors.append("%s: trigger refers to unknown event %s" % [id, t.get("event")])
	for e in def.get("encounters", {}).get("table", []):
		if not e.get("species", "") in GameData.lingshou_ids():
			errors.append("%s: encounter with unknown species %s" % [id, e.get("species")])
	return errors
