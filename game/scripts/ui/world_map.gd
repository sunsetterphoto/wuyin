class_name WorldMap
extends MenuScreen
## The map of Yunhai in the menu, drawn like a painted scroll: the five
## regions around the Cloud Pillars, every place as a little seal (bright when
## visited), the roads between them, which tones are back, where you are
## (Jinli's face) and where the current task waits (a gold star).

## Place -> position on the scroll (0..1), region.
const PLACES := {
	"weidendorf": [0.86, 0.62, "bamboo"], "hof": [0.95, 0.66, "bamboo"], "flussufer": [0.93, 0.52, "bamboo"],
	"bambuspfad": [0.82, 0.48, "bamboo"], "teeufer": [0.74, 0.44, "bamboo"], "reisterrassen": [0.76, 0.3, "bamboo"],
	"drachenschrein": [0.8, 0.17, "bamboo"],
	"kreuzweg": [0.55, 0.52, "hub"],
	"karstufer": [0.47, 0.36, "river"], "nebelhafen": [0.42, 0.23, "river"], "schildkroetenbucht": [0.33, 0.13, "river"],
	"danxiapfad": [0.55, 0.68, "ridge"], "rotfels": [0.52, 0.81, "ridge"], "feuergipfel": [0.47, 0.92, "ridge"],
	"duenenweg": [0.38, 0.55, "dunes"], "mondquell": [0.24, 0.58, "dunes"], "singender_kamm": [0.11, 0.5, "dunes"],
	"saeulenpfad": [0.6, 0.36, "pillars"], "kiefernhang": [0.63, 0.22, "pillars"], "qilin_plateau": [0.7, 0.12, "pillars"],
	"phoenixtempel": [0.6, 0.07, "temple"],
}
const ROADS := [["hof", "weidendorf"], ["weidendorf", "flussufer"], ["weidendorf", "bambuspfad"], ["bambuspfad", "teeufer"],
	["teeufer", "reisterrassen"], ["reisterrassen", "drachenschrein"], ["teeufer", "kreuzweg"], ["kreuzweg", "karstufer"],
	["karstufer", "nebelhafen"], ["nebelhafen", "schildkroetenbucht"], ["kreuzweg", "danxiapfad"], ["danxiapfad", "rotfels"],
	["rotfels", "feuergipfel"], ["kreuzweg", "duenenweg"], ["duenenweg", "mondquell"], ["mondquell", "singender_kamm"],
	["kreuzweg", "saeulenpfad"], ["saeulenpfad", "kiefernhang"], ["kiefernhang", "qilin_plateau"], ["kiefernhang", "phoenixtempel"]]
const REGION_COLOR := {"bamboo": Color("5aa84a"), "hub": Color("b8a070"), "river": Color("3b7ec2"), "ridge": Color("d8562c"),
	"dunes": Color("d8b060"), "pillars": Color("9a8f80"), "temple": Color("e0b04a")}
const REGION_TONE := {"bamboo": ["tone_jue", "角"], "river": ["tone_yu", "羽"], "ridge": ["tone_zhi", "徵"], "dunes": ["tone_shang", "商"],
	"pillars": ["tone_gong", "宫"]}

var _canvas: Control
var _here := ""
var _goal_place := ""


func _ready() -> void:
	title_label.text = tr("MENU_MAP")
	_canvas = Control.new()
	_canvas.custom_minimum_size = Vector2(0, 470)
	_canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_canvas.draw.connect(_draw_map)
	body.add_child(_canvas)
	var s := GameState.current
	var here := _place_of(s.map)
	_here = here
	var g = World.instance().current_goal() if World.instance() else s.flag("goal", null)
	_goal_place = _place_of(g[0]) if g is Array and g.size() == 3 else ""
	var legend := "%s: %s" % [tr("MAP_YOU_ARE"), tr("MAP_" + here.to_upper())] if here != "" else ""
	body.add_child(UiTheme.para(legend, 19, UiTheme.MUTED))


## Interiors count as the town they belong to.
static func _place_of(map_id: String) -> String:
	if PLACES.has(map_id):
		return map_id
	if MapData.exists(map_id):
		return MapData.load_map(map_id).def.get("parent", "")
	return ""


const ARRIVE := {"flussufer": "river_arrived", "reisterrassen": "terraces_arrived", "drachenschrein": "shrine_arrived",
	"bambuspfad": "prologue_done", "schildkroetenbucht": "bucht_arrived", "feuergipfel": "gipfel_arrived",
	"singender_kamm": "kamm_arrived", "qilin_plateau": "plateau_arrived", "phoenixtempel": "temple_arrived", "hof": "hof_arrived"}
const TOWNS := ["weidendorf", "teeufer", "kreuzweg", "nebelhafen", "rotfels", "mondquell", "kiefernhang"]


func _visited(id: String) -> bool:
	var s := GameState.current
	if id == "weidendorf" or _place_of(s.map) == id:
		return true
	if s.flag("visited_" + id) or s.flag(id + "_arrived"):
		return true
	return ARRIVE.has(id) and bool(s.flag(ARRIVE[id]))


func _draw_map() -> void:
	var c := _canvas
	var sz := c.size
	var s := GameState.current
	# Scroll paper with rolled ends.
	c.draw_rect(Rect2(Vector2(14, 4), sz - Vector2(28, 8)), Color("efe0bd"))
	for i in 40:
		var rng := RandomNumberGenerator.new()
		rng.seed = i
		var rr := rng.randf_range(10, 30)
		c.draw_circle(Vector2(rng.randf_range(20 + rr, sz.x - 20 - rr), rng.randf_range(8 + rr, sz.y - 8 - rr)), rr, Color(0.85, 0.75, 0.55, 0.12))
	c.draw_rect(Rect2(Vector2(0, 0), Vector2(18, sz.y)), Color("8e2e23"))
	c.draw_rect(Rect2(Vector2(sz.x - 18, 0), Vector2(18, sz.y)), Color("8e2e23"))
	c.draw_rect(Rect2(Vector2(14, 4), sz - Vector2(28, 8)), Color("8a6a3a"), false, 3.0)
	# Cloud sea in the middle under the pillars, region washes.
	for id in PLACES:
		var p: Array = PLACES[id]
		var col: Color = REGION_COLOR[p[2]]
		col.a = 0.13 if _visited(id) else 0.05
		c.draw_circle(_pos(p), 40, col)
	# Roads.
	for r in ROADS:
		var a := _pos(PLACES[r[0]])
		var b := _pos(PLACES[r[1]])
		var known: bool = _visited(r[0]) or _visited(r[1])
		_dashed(a, b, Color("6a4a2a", 0.85 if known else 0.25))
	# Places.
	var here := _here
	var goal_place := _goal_place
	var font := ThemeDB.fallback_font
	for id in PLACES:
		var p: Array = PLACES[id]
		var at := _pos(p)
		var seen := _visited(id)
		var col: Color = REGION_COLOR[p[2]] if seen else Color("b8ad98")
		var r := 9.0 if id in TOWNS else 6.0
		c.draw_circle(at, r + 2, Color("3a2a1a"))
		c.draw_circle(at, r, col)
		if seen:
			c.draw_string(font, at + Vector2(-60, r + 18), tr("MAP_" + id.to_upper()), HORIZONTAL_ALIGNMENT_CENTER, 120, 15, Color("3a2a1a"))
		if id == goal_place:
			_star(at + Vector2(14, -14), Color("e0b04a"))
	# Tones per region.
	var tone_at := {"bamboo": Vector2(0.86, 0.08), "river": Vector2(0.24, 0.08), "ridge": Vector2(0.62, 0.92), "dunes": Vector2(0.1, 0.7),
		"pillars": Vector2(0.53, 0.2)}
	for reg in REGION_TONE:
		var t: Array = REGION_TONE[reg]
		var v: Vector2 = tone_at[reg] * sz
		var back: bool = s.flag(t[0])
		c.draw_circle(v, 17, Color("8e2e23") if back else Color("a39b8b"))
		c.draw_string(font, v + Vector2(-12, 7), t[1], HORIZONTAL_ALIGNMENT_CENTER, 24, 18, Color("fff4e0"))
	# You are here: Jinli's face.
	if here != "":
		var at := _pos(PLACES[here])
		var bob := sin(Time.get_ticks_msec() / 300.0) * 2.0
		var jinli := Sprites.character("jinli")
		c.draw_texture_rect(jinli, Rect2(at + Vector2(-20, -50 + bob), Vector2(40, 40)), false)


func _pos(p: Array) -> Vector2:
	return Vector2(28 + float(p[0]) * (_canvas.size.x - 56), 16 + float(p[1]) * (_canvas.size.y - 40))


func _dashed(a: Vector2, b: Vector2, col: Color) -> void:
	var n := int(a.distance_to(b) / 10.0)
	for i in n:
		if i % 2 == 0:
			_canvas.draw_line(a.lerp(b, float(i) / n), a.lerp(b, float(i + 1) / n), col, 3.0)


func _star(at: Vector2, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 10:
		var r := 11.0 if i % 2 == 0 else 5.0
		var ang := -PI / 2.0 + i * PI / 5.0
		pts.append(at + Vector2(cos(ang), sin(ang)) * r)
	_canvas.draw_colored_polygon(pts, col)
	pts.append(pts[0])
	_canvas.draw_polyline(pts, Color("3a2a1a"), 2.0)


func _process(_delta: float) -> void:
	if _canvas:
		_canvas.queue_redraw()
