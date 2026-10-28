class_name Materials
extends RefCounted
## Shared materials of the diorama. Ground and building surfaces use the
## generated 64-px tiles from res://assets/tiles/ (one texture repeat per two
## game tiles, i.e. 32 texels per unit like the sprites) and fall back to the
## procedural PixelArt tiles (32 px per unit).

const TILE_DIR := "res://assets/tiles/"
## Surface kind -> generated texture id.
const ASSET := {"grass": "grass", "path": "path", "plaza": "plaza", "stone": "stone", "wood": "wood", "plaster": "plaster",
	"timber": "wall_timber", "paddy": "paddy", "sand": "sand", "redrock": "redrock", "danxia": "danxia", "karst": "karst",
	"cloudstone": "cloudstone", "pillarstone": "karst", "pine": "pine", "leaves": "leaves", "bamboo": "bamboo", "floor": "wood",
	"gravel": "cobble", "greywall": "plaster", "roof": "roof_red", "roof_red": "roof_red", "roof_grey": "roof_grey",
	"roof_green": "roof_green", "greyroof": "roof_grey", "rock": "karst", "moss": "moss", "snow": "snow", "water": "water", "pond": "water"}
## Procedural fallback kind when no generated texture exists.
const FALLBACK := {"timber": "plaster", "roof_red": "roof", "roof_grey": "greyroof", "roof_green": "greyroof", "moss": "grass", "snow": "cloud"}

static var _cache := {}


static func tile_texture(kind: String) -> Array:
	var id: String = ASSET.get(kind, kind)
	var path := TILE_DIR + id + ".png"
	if ResourceLoader.exists(path):
		return [load(path), 0.5]
	return [PixelArt.tile(FALLBACK.get(kind, kind)), 1.0]


## Lit, triplanar, pixel-crisp material for boxes of this surface kind.
static func surface(kind: String, tint := Color.WHITE) -> StandardMaterial3D:
	var key := "%s:%s" % [kind, tint.to_html()]
	if _cache.has(key):
		return _cache[key]
	var t := tile_texture(kind)
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = t[0]
	mat.albedo_color = tint
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	mat.uv1_triplanar = true
	mat.uv1_world_triplanar = true
	mat.uv1_scale = Vector3.ONE * float(t[1])
	mat.roughness = 1.0
	mat.vertex_color_use_as_albedo = true
	_cache[key] = mat
	return mat


static func water(flowing: bool) -> ShaderMaterial:
	var key := "water:%s" % flowing
	if _cache.has(key):
		return _cache[key]
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/water.gdshader")
	mat.set_shader_parameter("tex", tile_texture("water")[0])
	mat.set_shader_parameter("flow", 1.0 if flowing else 0.0)
	_cache[key] = mat
	return mat


static func prop(id: String) -> ShaderMaterial:
	var key := "prop:" + id
	if _cache.has(key):
		return _cache[key]
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/prop_billboard.gdshader")
	mat.set_shader_parameter("tex", Props.texture(id))
	mat.set_shader_parameter("sway", float(Props.SWAY.get(id, 0.0)))
	if Props.GLOW.has(id):
		mat.set_shader_parameter("emission", float(Props.GLOW[id]))
	_cache[key] = mat
	return mat


static func flat_prop(id: String) -> StandardMaterial3D:
	var key := "flat:" + id
	if _cache.has(key):
		return _cache[key]
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = Props.texture(id)
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_cache[key] = mat
	return mat


static func blob_shadow() -> ShaderMaterial:
	if not _cache.has("blob"):
		var mat := ShaderMaterial.new()
		mat.shader = load("res://shaders/blob_shadow.gdshader")
		_cache["blob"] = mat
	return _cache["blob"]


static func flat_color(c: Color, emission := 0.0) -> StandardMaterial3D:
	var key := "col:%s:%f" % [c.to_html(), emission]
	if _cache.has(key):
		return _cache[key]
	var mat := StandardMaterial3D.new()
	mat.albedo_color = c
	mat.roughness = 0.8
	if emission > 0.0:
		mat.emission_enabled = true
		mat.emission = c
		mat.emission_energy_multiplier = emission
	_cache[key] = mat
	return mat
