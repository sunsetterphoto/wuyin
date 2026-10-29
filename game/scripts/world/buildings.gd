class_name Buildings
extends RefCounted
## Houses of the diorama in Chinese style, one building per block of house
## tiles (H = timber house, R = red-pillared hall, O = the grey Order hall):
## stone plinth, plastered walls with wooden posts and beams, lattice windows,
## a red double door with steps, and a hip roof with concave slopes and
## upturned eave corners, ridge and ridge ornaments. Red halls get paper
## lanterns under the eaves.

const HOUSE_TILES := ["H", "R", "O", "D"]
const WALL_H := 1.25
const PLINTH_H := 0.18
const OVERHANG := 0.38
const STYLE := {
	"H": {"post": Color("6a4226"), "roof": "roof_grey", "wall": "plaster", "lanterns": false, "trim": Color("553520")},
	"R": {"post": Color("a8302a"), "roof": "roof_red", "wall": "plaster", "lanterns": true, "trim": Color("e0b04a")},
	"O": {"post": Color("4e5460"), "roof": "roof_grey", "wall": "greywall", "lanterns": false, "trim": Color("8c8577")},
}


## Blocks of connected house tiles: [{"rect": Rect2i, "kind": String, "doors": Array[Vector2i]}]
static func find(m: MapData) -> Array:
	var seen := {}
	var out := []
	for z in m.height:
		for x in m.width:
			var p := Vector2i(x, z)
			if seen.has(p) or m.tile(x, z) not in HOUSE_TILES:
				continue
			var stack: Array[Vector2i] = [p]
			seen[p] = true
			var r := Rect2i(p, Vector2i.ONE)
			var counts := {}
			var doors: Array[Vector2i] = []
			while not stack.is_empty():
				var c: Vector2i = stack.pop_back()
				r = r.expand(c).expand(c + Vector2i.ONE)
				var ch := m.tile(c.x, c.y)
				if ch == "D":
					doors.append(c)
				else:
					counts[ch] = int(counts.get(ch, 0)) + 1
				for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
					var n: Vector2i = c + d
					if not seen.has(n) and m.tile(n.x, n.y) in HOUSE_TILES:
						seen[n] = true
						stack.append(n)
			var kind := "H"
			var best := 0
			for k in counts:
				if counts[k] > best:
					best = counts[k]
					kind = k
			out.append({"rect": r, "kind": kind, "doors": doors})
	return out


static func build(b: Dictionary, parent: Node3D, lights: Array[OmniLight3D], max_lights: int, glow := 1.0) -> void:
	var r: Rect2i = b["rect"]
	var st: Dictionary = STYLE.get(b["kind"], STYLE["H"])
	var x0 := r.position.x - 0.5
	var z0 := r.position.y - 0.5
	var w := float(r.size.x)
	var d := float(r.size.y)
	var cx := x0 + w / 2.0
	var cz := z0 + d / 2.0
	var root := Node3D.new()
	root.name = "Building"
	parent.add_child(root)
	# Plinth and walls.
	_box(root, Vector3(cx, PLINTH_H / 2.0, cz), Vector3(w + 0.16, PLINTH_H, d + 0.16), Materials.surface("stone"))
	var wy := PLINTH_H + WALL_H / 2.0
	_box(root, Vector3(cx, wy, cz), Vector3(w - 0.2, WALL_H, d - 0.2), Materials.surface(st["wall"]))
	# Posts at the corners and along the front, a beam under the eaves.
	var post_mat := Materials.flat_color(st["post"])
	var front := z0 + d - 0.1
	var n_front := maxi(2, int(w / 1.4) + 1)
	for i in n_front:
		var px := x0 + 0.1 + (w - 0.2) * float(i) / float(n_front - 1)
		_box(root, Vector3(px, wy, front), Vector3(0.14, WALL_H, 0.14), post_mat)
	for px in [x0 + 0.1, x0 + w - 0.1]:
		_box(root, Vector3(px, wy, z0 + 0.1), Vector3(0.14, WALL_H, 0.14), post_mat)
	_box(root, Vector3(cx, PLINTH_H + WALL_H - 0.08, front + 0.01), Vector3(w - 0.1, 0.16, 0.1), post_mat)
	_box(root, Vector3(cx, PLINTH_H + 0.06, front + 0.01), Vector3(w - 0.1, 0.1, 0.08), post_mat)
	# Doors and windows on the front.
	var door_x: Array[float] = []
	for door in b["doors"]:
		door_x.append(float(door.x))
		_door(root, Vector3(door.x, 0, front + 0.06), st)
	var lattice := _lattice_material(b["kind"])
	var slots := int(w)
	for i in slots:
		var wx := x0 + 0.5 + i
		if door_x.any(func(dx): return absf(dx - wx) < 0.9):
			continue
		_quad(root, Vector3(wx, PLINTH_H + WALL_H * 0.55, front + 0.075), Vector2(0.52, 0.42), lattice)
	# Roof.
	_roof(root, x0 - OVERHANG, z0 - OVERHANG * 0.7, w + OVERHANG * 2.0, d + OVERHANG * 1.7, PLINTH_H + WALL_H, st)
	# A string of little lanterns along the front eave of bigger houses.
	if b["kind"] != "O" and w >= 4:
		root.add_child(_prop_sprite("lantern_string", Vector3(cx, PLINTH_H + WALL_H - 0.2, front + 0.36), minf(1.4, (w - 1.0) / 2.0)))
	# Lanterns under the front eaves.
	if st["lanterns"] or b["kind"] == "H" and w >= 5:
		for lx in [x0 + 0.45, x0 + w - 0.45]:
			var lantern := _prop_sprite("lantern_red", Vector3(lx, PLINTH_H + WALL_H - 0.55, front + 0.32), 1.0)
			root.add_child(lantern)
			if lights.size() < max_lights:
				var l := OmniLight3D.new()
				l.position = Vector3(lx, PLINTH_H + WALL_H - 0.3, front + 0.5)
				l.light_color = Color("ffb35a")
				l.light_energy = 1.2 * glow
				l.omni_range = 3.2
				l.shadow_enabled = false
				root.add_child(l)
				lights.append(l)


static func _door(root: Node3D, at: Vector3, st: Dictionary) -> void:
	var frame := Materials.flat_color(Color("3a2418"))
	var leaf := Materials.flat_color(Color("b8352a"))
	var gold := Materials.flat_color(Color("e0b04a"), 0.3)
	_box(root, at + Vector3(0, PLINTH_H + 0.5, -0.02), Vector3(0.82, 1.0, 0.06), frame)
	_box(root, at + Vector3(-0.19, PLINTH_H + 0.48, 0.0), Vector3(0.36, 0.92, 0.05), leaf)
	_box(root, at + Vector3(0.19, PLINTH_H + 0.48, 0.0), Vector3(0.36, 0.92, 0.05), leaf)
	for sx in [-0.06, 0.06]:
		_box(root, at + Vector3(sx, PLINTH_H + 0.5, 0.03), Vector3(0.05, 0.05, 0.03), gold)
	_box(root, at + Vector3(0, PLINTH_H + 1.05, 0.02), Vector3(0.6, 0.16, 0.05), Materials.flat_color(st["trim"]))
	_box(root, at + Vector3(0, 0.05, 0.28), Vector3(0.9, 0.1, 0.35), Materials.surface("stone"))


## Hip roof with concave slopes and upturned corners (SurfaceTool grid per face).
static func _roof(root: Node3D, x0: float, z0: float, w: float, d: float, eave_y: float, st: Dictionary) -> void:
	var short_side := minf(w, d)
	var rise := clampf(0.45 + short_side * 0.22, 0.7, 1.5)
	var ridge_y := eave_y + rise
	var along_x := w >= d
	var half_ridge := maxf(0.12, (absf(w - d)) / 2.0 + 0.15)
	var cx := x0 + w / 2.0
	var cz := z0 + d / 2.0
	var r0 := Vector3(cx - half_ridge, ridge_y, cz) if along_x else Vector3(cx, ridge_y, cz - half_ridge)
	var r1 := Vector3(cx + half_ridge, ridge_y, cz) if along_x else Vector3(cx, ridge_y, cz + half_ridge)
	var c00 := Vector3(x0, eave_y, z0)
	var c10 := Vector3(x0 + w, eave_y, z0)
	var c11 := Vector3(x0 + w, eave_y, z0 + d)
	var c01 := Vector3(x0, eave_y, z0 + d)
	var faces := []
	if along_x:
		faces = [[c01, c11, r0, r1], [c10, c00, r1, r0], [c00, c01, r0, r0], [c11, c10, r1, r1]]
	else:
		faces = [[c00, c01, r0, r1], [c11, c10, r1, r0], [c10, c00, r0, r0], [c01, c11, r1, r1]]
	var surf := SurfaceTool.new()
	surf.begin(Mesh.PRIMITIVE_TRIANGLES)
	var nu := 8
	var nv := 5
	for f in faces:
		var e0: Vector3 = f[0]
		var e1: Vector3 = f[1]
		var q0: Vector3 = f[2]
		var q1: Vector3 = f[3]
		var grid := []
		for iv in nv + 1:
			var row := []
			var v := float(iv) / nv
			for iu in nu + 1:
				var u := float(iu) / nu
				var e := e0.lerp(e1, u)
				var q := q0.lerp(q1, u)
				var p := e.lerp(q, v)
				p.y = eave_y + rise * pow(v, 1.7)
				var corner := pow(absf(u * 2.0 - 1.0), 5.0) * pow(1.0 - v, 2.0)
				p.y += 0.28 * corner
				# Eaves reach a little further out at the corners.
				var out := (e - Vector3(cx, eave_y, cz)) * Vector3(1, 0, 1)
				p += out.normalized() * 0.1 * corner
				row.append(p)
			grid.append(row)
		for iv in nv:
			for iu in nu:
				var a: Vector3 = grid[iv][iu]
				var b: Vector3 = grid[iv][iu + 1]
				var c: Vector3 = grid[iv + 1][iu + 1]
				var dd: Vector3 = grid[iv + 1][iu]
				for p in [a, b, c, a, c, dd]:
					surf.add_vertex(p)
	surf.generate_normals()
	var mesh := surf.commit()
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	var mat := Materials.surface(st["roof"]).duplicate() as StandardMaterial3D
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mi.material_override = mat
	root.add_child(mi)
	# Ridge beam and its upturned ends.
	var ridge_mat := Materials.flat_color(Color("3e3a40"))
	var ridge_len := (r1 - r0).length() + 0.3
	var mid := (r0 + r1) / 2.0 + Vector3(0, 0.06, 0)
	_box(root, mid, Vector3(ridge_len, 0.14, 0.14) if along_x else Vector3(0.14, 0.14, ridge_len), ridge_mat)
	for end in [r0, r1]:
		var dir: Vector3 = (end - mid).normalized() * 0.16
		var orn := _box(root, end + dir + Vector3(0, 0.16, 0), Vector3(0.1, 0.28, 0.1), Materials.flat_color(st["trim"]))
		orn.rotation = Vector3(0, 0, -0.5 * signf(dir.x)) if along_x else Vector3(0.5 * signf(dir.z), 0, 0)


static func _box(root: Node3D, pos: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	root.add_child(mi)
	return mi


static func _quad(root: Node3D, pos: Vector3, size: Vector2, mat: Material) -> void:
	var mi := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = size
	mi.mesh = q
	mi.material_override = mat
	mi.position = pos
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(mi)


static var _lattice := {}


## Wooden lattice window with warm paper behind it (glows a little at night).
static func _lattice_material(kind: String) -> StandardMaterial3D:
	if _lattice.has(kind):
		return _lattice[kind]
	var img := Image.create(16, 14, false, Image.FORMAT_RGBA8)
	img.fill(Color("f0dcae"))
	var wood := Color("6a4226") if kind != "R" else Color("8e2e23")
	if kind == "O":
		wood = Color("4e5460")
		img.fill(Color("c8c8c0"))
	img.fill_rect(Rect2i(0, 0, 16, 1), wood)
	img.fill_rect(Rect2i(0, 13, 16, 1), wood)
	img.fill_rect(Rect2i(0, 0, 1, 14), wood)
	img.fill_rect(Rect2i(15, 0, 1, 14), wood)
	for x in [5, 10]:
		img.fill_rect(Rect2i(x, 0, 1, 14), wood)
	for y in [4, 9]:
		img.fill_rect(Rect2i(0, y, 16, 1), wood)
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = ImageTexture.create_from_image(img)
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	mat.emission_enabled = kind != "O"
	mat.emission = Color("ffc070")
	mat.emission_energy_multiplier = 0.25
	mat.emission_texture = mat.albedo_texture
	_lattice[kind] = mat
	return mat


## A single standing prop (lanterns under eaves etc.).
static func _prop_sprite(id: String, pos: Vector3, scale: float) -> Sprite3D:
	var s := Sprite3D.new()
	s.texture = Props.texture(id)
	s.pixel_size = 1.0 / CameraRig.PIXELS_PER_UNIT * scale
	s.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	s.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	s.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	s.shaded = false
	s.modulate = Color(1.15, 1.0, 0.9)
	s.position = pos
	return s
