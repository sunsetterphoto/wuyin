class_name AmbientFx
extends Node3D
## Small life in the air around the player, by region and time of day:
## fireflies at night, falling leaves and petals, river mist, embers on the
## ridge, drifting sand, motes above the clouds. Silent regions get only a
## little grey dust - even the air is still there.

const AREA := Vector3(18, 5, 14)

var _systems: Array[GPUParticles3D] = []
var _key := ""


## kind list: which systems run now.
static func kinds_for(region: String, night: bool, silent: bool, weather: String) -> Array[String]:
	if silent:
		return ["dust"]
	if region == "indoor":
		return ["dust_warm"]
	var out: Array[String] = []
	if night and weather not in ["rain", "storm", "snow", "sandstorm"]:
		out.append("fireflies")
	match region:
		"bamboo", "hub":
			out.append("leaves")
			if not night:
				out.append("petals")
				out.append("butterflies")
		"river":
			out.append("mist")
			out.append("leaves")
		"ridge":
			out.append("embers" if night else "dust_warm")
			if not night:
				out.append("butterflies")
		"dunes":
			out.append("sand")
		"pillars", "temple":
			out.append("motes")
			if not night:
				out.append("petals_white")
	return out


func configure(region: String, night: bool, silent: bool, weather: String) -> void:
	var kinds := kinds_for(region, night, silent, weather)
	var key := ",".join(kinds)
	if key == _key:
		return
	_key = key
	for s in _systems:
		s.queue_free()
	_systems.clear()
	for k in kinds:
		var s := _make(k)
		add_child(s)
		_systems.append(s)


func _make(kind: String) -> GPUParticles3D:
	var p := GPUParticles3D.new()
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = AREA / 2.0
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.vertex_color_use_as_albedo = true
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	var quad := QuadMesh.new()
	var size := 0.08
	var color := Color.WHITE
	match kind:
		"fireflies":
			p.amount = 40
			p.lifetime = 6.0
			pm.gravity = Vector3(0, 0.02, 0)
			pm.turbulence_enabled = true
			pm.turbulence_noise_strength = 1.4
			pm.turbulence_noise_scale = 2.0
			pm.emission_box_extents = Vector3(AREA.x / 2.0, 1.0, AREA.z / 2.0)
			color = Color(0.85, 1.0, 0.45)
			mat.emission_enabled = true
			mat.emission = color
			mat.emission_energy_multiplier = 3.0
			size = 0.07
			_fade(pm, color)
		"leaves", "petals", "petals_white":
			p.amount = 14 if kind == "leaves" else 18
			p.lifetime = 8.0
			pm.gravity = Vector3(0.15, -0.25, 0.05)
			pm.angular_velocity_min = -90.0
			pm.angular_velocity_max = 90.0
			pm.turbulence_enabled = true
			pm.turbulence_noise_strength = 0.6
			color = {"leaves": Color("6aa84f"), "petals": Color("f4a0c0"), "petals_white": Color("f4f0f8")}[kind]
			size = 0.09
			mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
			_fade(pm, color)
		"butterflies":
			p.amount = 8
			p.lifetime = 10.0
			pm.gravity = Vector3(0, 0, 0)
			pm.emission_box_extents = Vector3(AREA.x / 2.0, 0.4, AREA.z / 2.0)
			pm.initial_velocity_min = 0.2
			pm.initial_velocity_max = 0.5
			pm.direction = Vector3(1, 0.2, 0)
			pm.spread = 180.0
			pm.turbulence_enabled = true
			pm.turbulence_noise_strength = 2.5
			pm.turbulence_noise_scale = 1.5
			pm.hue_variation_min = -0.5
			pm.hue_variation_max = 0.5
			color = Color("f8e070")
			size = 0.12
			mat.albedo_texture = _butterfly()
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
			_fade(pm, color)
		"mist":
			p.amount = 10
			p.lifetime = 12.0
			pm.gravity = Vector3(0.06, 0.0, 0.0)
			pm.emission_box_extents = Vector3(AREA.x / 2.0, 0.3, AREA.z / 2.0)
			color = Color(0.9, 0.95, 1.0, 0.18)
			size = 2.4
			mat.albedo_texture = _soft_dot()
			_fade(pm, color)
		"embers":
			p.amount = 30
			p.lifetime = 4.0
			pm.gravity = Vector3(0, 0.35, 0)
			pm.turbulence_enabled = true
			pm.turbulence_noise_strength = 0.8
			color = Color(1.0, 0.55, 0.2)
			mat.emission_enabled = true
			mat.emission = color
			mat.emission_energy_multiplier = 2.5
			size = 0.05
			_fade(pm, color)
		"dust", "dust_warm":
			p.amount = 16
			p.lifetime = 7.0
			pm.gravity = Vector3(0.03, -0.02, 0)
			pm.turbulence_enabled = true
			pm.turbulence_noise_strength = 0.4
			color = Color(0.7, 0.7, 0.72, 0.5) if kind == "dust" else Color(1.0, 0.9, 0.7, 0.55)
			size = 0.04
			_fade(pm, color)
		"sand":
			p.amount = 30
			p.lifetime = 3.0
			pm.gravity = Vector3(1.2, -0.05, 0.1)
			pm.emission_box_extents = Vector3(AREA.x / 2.0, 0.6, AREA.z / 2.0)
			color = Color(0.95, 0.82, 0.55, 0.7)
			size = 0.04
			_fade(pm, color)
		"motes":
			p.amount = 20
			p.lifetime = 9.0
			pm.gravity = Vector3(0.05, 0.04, 0)
			pm.turbulence_enabled = true
			pm.turbulence_noise_strength = 0.5
			color = Color(1, 1, 1, 0.6)
			size = 0.05
			_fade(pm, color)
	quad.size = Vector2(size, size)
	quad.material = mat
	p.draw_pass_1 = quad
	p.process_material = pm
	p.visibility_aabb = AABB(-AREA, AREA * 2.0)
	p.preprocess = p.lifetime
	p.position = Vector3(0, AREA.y / 2.0 - 0.5, 0)
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return p


static func _fade(pm: ParticleProcessMaterial, c: Color) -> void:
	var g := Gradient.new()
	g.set_color(0, Color(c.r, c.g, c.b, 0.0))
	g.add_point(0.2, c)
	g.add_point(0.8, c)
	g.set_color(g.get_point_count() - 1, Color(c.r, c.g, c.b, 0.0))
	var gt := GradientTexture1D.new()
	gt.gradient = g
	pm.color_ramp = gt


static var _wing: Texture2D


## Tiny two-winged butterfly (4x3 px look, stretched by the quad).
static func _butterfly() -> Texture2D:
	if _wing == null:
		var img := Image.create(5, 4, false, Image.FORMAT_RGBA8)
		img.fill(Color(0, 0, 0, 0))
		for p in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(3, 0), Vector2i(4, 0), Vector2i(3, 1), Vector2i(4, 1),
				Vector2i(1, 2), Vector2i(3, 2)]:
			img.set_pixelv(p, Color.WHITE)
		img.set_pixel(2, 1, Color(0.2, 0.15, 0.2))
		img.set_pixel(2, 2, Color(0.2, 0.15, 0.2))
		_wing = ImageTexture.create_from_image(img)
	return _wing


static var _dot: Texture2D


static func _soft_dot() -> Texture2D:
	if _dot == null:
		var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
		for y in 32:
			for x in 32:
				var d := Vector2(x - 15.5, y - 15.5).length() / 16.0
				img.set_pixel(x, y, Color(1, 1, 1, clampf(1.0 - d, 0.0, 1.0) ** 2))
		_dot = ImageTexture.create_from_image(img)
	return _dot
