class_name MapBuilder
extends RefCounted
## Builds the blocky 3D diorama of a map: one MultiMesh per tile texture,
## billboard tufts for grass and rice, warm lantern lights. Ground top is y = 0.

const MAX_LIGHTS := 10

## Returns {"root": Node3D, "lights": Array[OmniLight3D]}.
static func build(m: MapData) -> Dictionary:
	var root := Node3D.new()
	root.name = "Map_" + m.id
	var boxes := {}  # texture kind -> Array[Transform3D]
	var tufts := {}  # tuft kind -> Array[Transform3D]
	var lights: Array[OmniLight3D] = []
	var add := func(kind: String, pos: Vector3, size: Vector3) -> void:
		if not boxes.has(kind):
			boxes[kind] = []
		boxes[kind].append(Transform3D(Basis.from_scale(size), pos))
	var tuft := func(kind: String, pos: Vector3, scale := 1.0) -> void:
		if not tufts.has(kind):
			tufts[kind] = []
		tufts[kind].append(Transform3D(Basis.from_scale(Vector3.ONE * scale), pos))
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(m.id)
	for z in m.height:
		for x in m.width:
			var c := m.tile(x, z)
			var inf: Array = MapData.LEGEND.get(c, MapData.LEGEND["X"])
			var p := Vector3(x, 0, z)
			match inf[0]:
				"water", "pond":
					add.call(inf[0], p + Vector3(0, -0.4, 0), Vector3(1, 0.3, 1))
				"cloud":
					add.call("cloud", p + Vector3(0, -1.1, 0), Vector3(1, 0.4, 1))
					if rng.randf() < 0.35:
						var s := rng.randf_range(0.5, 0.9)
						add.call("cloud", p + Vector3(rng.randf_range(-0.2, 0.2), -0.75, rng.randf_range(-0.2, 0.2)), Vector3(s, 0.3, s))
				"paddy":
					add.call("paddy", p + Vector3(0, -0.3, 0), Vector3(1, 0.4, 1))
				_:
					add.call(inf[0], p + Vector3(0, -0.25, 0), Vector3(1, 0.5, 1))
			match inf[1]:
				"tallgrass":
					tuft.call("tallgrass", p + Vector3(-0.22, 0, -0.2))
					tuft.call("tallgrass", p + Vector3(0.2, 0, 0.22))
				"rice":
					tuft.call("rice", p + Vector3(-0.2, -0.1, -0.15), 0.9)
					tuft.call("rice", p + Vector3(0.22, -0.1, 0.2), 0.9)
				"flowers":
					tuft.call("flowers", p + Vector3(rng.randf_range(-0.2, 0.2), 0, rng.randf_range(-0.2, 0.2)), 0.8)
				"stone":
					add.call("stone", p + Vector3(0, 0.6, 0), Vector3(1, 1.2, 1))
				"rock":
					var h := rng.randf_range(0.9, 1.6)
					add.call("rock", p + Vector3(0, h / 2.0, 0), Vector3(1, h, 1))
				"bamboo":
					var h := rng.randf_range(2.2, 3.0)
					add.call("bamboo", p + Vector3(0, h / 2.0, 0), Vector3(0.9, h, 0.9))
				"tree":
					add.call("wood", p + Vector3(0, 0.5, 0), Vector3(0.3, 1.0, 0.3))
					add.call("leaves", p + Vector3(0, 1.5, 0), Vector3(1.4, 1.1, 1.4))
				"house", "house_red", "door":
					var wall := "plaster" if inf[1] == "house_red" else "wood"
					if inf[1] == "door":
						wall = "door"
					add.call(wall, p + Vector3(0, 0.8, 0), Vector3(1, 1.6, 1))
					add.call("roof", p + Vector3(0, 1.85, 0), Vector3(1.12, 0.5, 1.12))
				"lantern":
					add.call("wood", p + Vector3(0, 0.6, 0), Vector3(0.12, 1.2, 0.12))
					add.call("lantern", p + Vector3(0, 1.35, 0), Vector3(0.35, 0.4, 0.35))
					if lights.size() < MAX_LIGHTS:
						var lamp := OmniLight3D.new()
						lamp.position = p + Vector3(0, 1.35, 0)
						lamp.light_color = Color("ffb35a")
						lamp.light_energy = 1.6
						lamp.omni_range = 4.5
						root.add_child(lamp)
						lights.append(lamp)
				"fence":
					var along_x := m.tile(x - 1, z) == "F" or m.tile(x + 1, z) == "F"
					add.call("wood", p + Vector3(0, 0.3, 0), Vector3(1, 0.6, 0.14) if along_x else Vector3(0.14, 0.6, 1))
				"pillar":
					add.call("pillar", p + Vector3(0, 1.4, 0), Vector3(0.6, 2.8, 0.6))
					add.call("roof", p + Vector3(0, 2.9, 0), Vector3(0.8, 0.2, 0.8))
				"stall":
					add.call("wood", p + Vector3(0, 0.4, 0), Vector3(0.9, 0.8, 0.9))
					add.call("cloth", p + Vector3(0, 1.5, 0), Vector3(1.1, 0.12, 1.1))
				"well":
					add.call("stone", p + Vector3(0, 0.35, 0), Vector3(0.9, 0.7, 0.9))
					add.call("water", p + Vector3(0, 0.66, 0), Vector3(0.6, 0.05, 0.6))
				"bridge":
					add.call("wood", p + Vector3(0, -0.1, 0), Vector3(1, 0.2, 0.9))
				"drygrass", "reeds", "sapling":
					tuft.call(inf[1], p + Vector3(-0.2, 0, -0.18), 0.9)
					tuft.call(inf[1], p + Vector3(0.2, 0, 0.2), 0.9)
				"dune":
					var h := rng.randf_range(0.35, 0.8)
					add.call("sand", p + Vector3(0, h / 2.0, 0), Vector3(1, h, 1))
				"danxia":
					var h := rng.randf_range(1.4, 2.6)
					add.call("danxia", p + Vector3(0, h / 2.0, 0), Vector3(1, h, 1))
				"karst":
					var h := rng.randf_range(2.0, 3.4)
					add.call("karst", p + Vector3(0, h * 0.3, 0), Vector3(1, h * 0.6, 1))
					add.call("karst", p + Vector3(0, h * 0.75, 0), Vector3(0.7, h * 0.3, 0.7))
					add.call("leaves", p + Vector3(0, h * 0.95, 0), Vector3(0.5, h * 0.15, 0.5))
				"stonepillar":
					var h := rng.randf_range(3.0, 5.0)
					add.call("pillarstone", p + Vector3(0, h / 2.0 - 0.6, 0), Vector3(0.95, h + 1.2, 0.95))
					add.call("pine", p + Vector3(0, h + 0.15, 0), Vector3(0.7, 0.5, 0.7))
				"pine":
					add.call("wood", p + Vector3(0, 0.45, 0), Vector3(0.25, 0.9, 0.25))
					add.call("pine", p + Vector3(0, 1.2, 0), Vector3(1.2, 0.7, 1.2))
					add.call("pine", p + Vector3(0, 1.8, 0), Vector3(0.8, 0.6, 0.8))
					add.call("pine", p + Vector3(0, 2.3, 0), Vector3(0.4, 0.5, 0.4))
				"house_grey":
					add.call("greywall", p + Vector3(0, 0.8, 0), Vector3(1, 1.6, 1))
					add.call("greyroof", p + Vector3(0, 1.85, 0), Vector3(1.12, 0.5, 1.12))
				"altar":
					add.call("stone", p + Vector3(0, 0.4, 0), Vector3(0.95, 0.8, 0.95))
					add.call("gold", p + Vector3(0, 0.85, 0), Vector3(0.5, 0.1, 0.5))
				"nest":
					add.call("wood", p + Vector3(0, 0.25, 0), Vector3(1, 0.5, 1))
					add.call("gold", p + Vector3(0, 0.55, 0), Vector3(0.6, 0.12, 0.6))
	# Land beyond the map edge, so the camera never looks into the void.
	var border := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(m.width + 60, m.height + 60)
	var pm := StandardMaterial3D.new()
	pm.albedo_texture = PixelArt.tile(m.def.get("border", "grass"))
	pm.albedo_color = Color(0.55, 0.6, 0.55)
	pm.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	pm.uv1_triplanar = true
	pm.uv1_world_triplanar = true
	plane.material = pm
	border.mesh = plane
	border.position = Vector3(m.width / 2.0 - 0.5, -0.52, m.height / 2.0 - 0.5)
	root.add_child(border)
	for kind in boxes:
		root.add_child(_boxes(kind, boxes[kind]))
	for kind in tufts:
		root.add_child(_tufts(kind, tufts[kind]))
	return {"root": root, "lights": lights}


static func _boxes(kind: String, transforms: Array) -> MultiMeshInstance3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = PixelArt.tile("bamboo" if kind == "leaves" else kind)
	if kind == "leaves":
		mat.albedo_color = Color(0.85, 1.0, 0.8)
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	mat.uv1_triplanar = true
	mat.uv1_world_triplanar = true
	if kind == "cloud":
		mat.emission_enabled = true
		mat.emission = Color("dfe6ee")
		mat.emission_energy_multiplier = 0.25
	if kind == "lantern":
		mat.emission_enabled = true
		mat.emission = Color("ffb35a")
		mat.emission_energy_multiplier = 2.0
	if kind == "water" or kind == "pond":
		mat.metallic_specular = 0.9
		mat.roughness = 0.15
	var mesh := BoxMesh.new()
	mesh.material = mat
	return _multimesh(mesh, transforms)


static func _tufts(kind: String, transforms: Array) -> MultiMeshInstance3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = PixelArt.tuft(kind)
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
	mat.billboard_keep_scale = true
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	var mesh := QuadMesh.new()
	mesh.size = Vector2(1.0, 0.75)
	mesh.center_offset = Vector3(0, 0.375, 0)
	mesh.material = mat
	var mmi := _multimesh(mesh, transforms)
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mmi


static func _multimesh(mesh: Mesh, transforms: Array) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = transforms.size()
	for i in transforms.size():
		mm.set_instance_transform(i, transforms[i])
	var inst := MultiMeshInstance3D.new()
	inst.multimesh = mm
	return inst
