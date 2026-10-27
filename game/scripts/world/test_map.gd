extends Control
## M0.6 camera test: a small blocky 3D map with billboard sprites, switchable
## between HD-2D and classic 2D at runtime. The 3D world renders into a
## SubViewport: full resolution in HD-2D, 640x360 scaled by a whole number in
## classic mode (pixel-exact).

const CLASSIC_RES := Vector2i(640, 360)
const MOVE_SPEED := 3.5
const BENCH_SECONDS := 3.0

## Map legend: . grass, = path, ~ water, S stone wall, B bamboo, T tree, H house, L lantern
const MAP := [
	"SSSSSSSSSSSSSSSSSSSSSSSS",
	"S.....BB.......~~~~....S",
	"S.HHH.BB..T....~~~~.T..S",
	"S.HHH..........~~~~....S",
	"S.HHH....L.....~~~.....S",
	"S..=.........====......S",
	"S..===========..===....S",
	"S....L......=....=..BB.S",
	"S..T........=....=..BB.S",
	"S...........=.L..=.....S",
	"S.BB....T...=....====..S",
	"S.BB........=.......=..S",
	"S.......~~~.=..T....=..S",
	"S......~~~~~=.......=L.S",
	"S.......~~~~=..........S",
	"SSSSSSSSSSSSSSSSSSSSSSSS",
]

var _view: SubViewport
var _screen: TextureRect
var _rig: CameraRig
var _env: Environment
var _sun: DirectionalLight3D
var _lanterns: Array[OmniLight3D] = []
var _particles: GPUParticles3D
var _sprites: Array[Sprite3D] = []
var _player: Sprite3D
var _jinli: Sprite3D
var _trail: Array[Vector3] = []
var _blocked := {}
var _fps: Label
var _mode_button: Button
var _bloom_on := true
var _blur_on := true
var _touch_dir := Vector2.ZERO
var _benching := false


func _ready() -> void:
	_build_viewport()
	_build_world()
	_build_ui()
	_rig.mode_changed.connect(_on_mode_changed)
	_on_mode_changed(_rig.mode)
	if "--camera-bench" in OS.get_cmdline_user_args():
		run_bench.call_deferred()


# --- setup -------------------------------------------------------------------

func _build_viewport() -> void:
	var bg := ColorRect.new()
	bg.color = Color.BLACK
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	_view = SubViewport.new()
	_view.size = Vector2i(1280, 720)
	_view.msaa_3d = Viewport.MSAA_DISABLED
	add_child(_view)
	_screen = TextureRect.new()
	_screen.texture = _view.get_texture()
	_screen.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_screen.stretch_mode = TextureRect.STRETCH_SCALE
	_screen.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(_screen)


func _build_world() -> void:
	var we := WorldEnvironment.new()
	_env = Environment.new()
	_env.background_mode = Environment.BG_COLOR
	_env.background_color = Color("9fc3d8")
	_env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	_env.ambient_light_color = Color("c9d6e8")
	_env.glow_enabled = true
	_env.glow_bloom = 0.15
	_env.glow_hdr_threshold = 0.9
	_env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	we.environment = _env
	_view.add_child(we)

	_sun = DirectionalLight3D.new()
	_sun.rotation_degrees = Vector3(-50, -35, 0)
	_sun.light_color = Color("fff1d6")
	_sun.shadow_enabled = true
	_sun.directional_shadow_max_distance = 40.0
	_view.add_child(_sun)

	var tiles := {}  # kind -> Array[Transform3D]
	var add := func(kind: String, pos: Vector3, size: Vector3) -> void:
		if not tiles.has(kind):
			tiles[kind] = []
		tiles[kind].append(Transform3D(Basis.from_scale(size), pos))
	for z in MAP.size():
		var row: String = MAP[z]
		for x in row.length():
			var c := row[x]
			var p := Vector3(x, 0, z)
			match c:
				"~":
					add.call("water", p + Vector3(0, -0.35, 0), Vector3(1, 0.3, 1))
					_blocked[Vector2i(x, z)] = true
				"=", "L":
					add.call("path", p + Vector3(0, -0.25, 0), Vector3(1, 0.5, 1))
				_:
					add.call("grass", p + Vector3(0, -0.25, 0), Vector3(1, 0.5, 1))
			match c:
				"S":
					add.call("stone", p + Vector3(0, 0.75, 0), Vector3(1, 1.5, 1))
					_blocked[Vector2i(x, z)] = true
				"B":
					add.call("bamboo", p + Vector3(0, 1.25, 0), Vector3(0.9, 2.5, 0.9))
					_blocked[Vector2i(x, z)] = true
				"T":
					add.call("wood", p + Vector3(0, 0.5, 0), Vector3(0.35, 1.0, 0.35))
					add.call("bamboo", p + Vector3(0, 1.5, 0), Vector3(1.4, 1.1, 1.4))
					_blocked[Vector2i(x, z)] = true
				"H":
					add.call("wood", p + Vector3(0, 0.75, 0), Vector3(1, 1.5, 1))
					add.call("roof", p + Vector3(0, 1.75, 0), Vector3(1.1, 0.5, 1.1))
					_blocked[Vector2i(x, z)] = true
				"L":
					add.call("wood", p + Vector3(0, 0.6, 0), Vector3(0.12, 1.2, 0.12))
					add.call("lantern", p + Vector3(0, 1.35, 0), Vector3(0.35, 0.4, 0.35))
					var lamp := OmniLight3D.new()
					lamp.position = p + Vector3(0, 1.35, 0)
					lamp.light_color = Color("ffb35a")
					lamp.light_energy = 1.6
					lamp.omni_range = 4.0
					_view.add_child(lamp)
					_lanterns.append(lamp)
	for kind in tiles:
		_view.add_child(_multimesh(kind, tiles[kind]))

	_player = _sprite("hero", Vector3(4, 0, 6))
	_jinli = _sprite("jinli", Vector3(3, 0, 6))
	_sprite("panda", Vector3(9, 0, 9))
	_particles = _fireflies()
	_view.add_child(_particles)

	_rig = CameraRig.new()
	_rig.target = _player
	_rig.classic_view_height = CLASSIC_RES.y / CameraRig.PIXELS_PER_UNIT
	_view.add_child(_rig)


func _multimesh(kind: String, transforms: Array) -> MultiMeshInstance3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = PixelArt.tile(kind)
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	mat.uv1_triplanar = true
	mat.uv1_world_triplanar = true
	if kind == "lantern":
		mat.emission_enabled = true
		mat.emission = Color("ffb35a")
		mat.emission_energy_multiplier = 2.0
	var mesh := BoxMesh.new()
	mesh.material = mat
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = transforms.size()
	for i in transforms.size():
		mm.set_instance_transform(i, transforms[i])
	var inst := MultiMeshInstance3D.new()
	inst.multimesh = mm
	return inst


func _sprite(kind: String, pos: Vector3) -> Sprite3D:
	var s := Sprite3D.new()
	s.texture = PixelArt.character(kind)
	s.pixel_size = 1.0 / CameraRig.PIXELS_PER_UNIT
	s.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	s.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	s.shaded = true
	s.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	s.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	s.offset = Vector2(0, 24)  # feet on the ground
	s.position = pos
	_view.add_child(s)
	_sprites.append(s)
	return s


func _fireflies() -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.amount = 60
	p.lifetime = 5.0
	p.position = Vector3(MAP[0].length() / 2.0, 1.2, MAP.size() / 2.0)
	p.visibility_aabb = AABB(Vector3(-14, -2, -10), Vector3(28, 6, 20))
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(11, 0.8, 7)
	pm.gravity = Vector3.ZERO
	pm.initial_velocity_min = 0.05
	pm.initial_velocity_max = 0.25
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 180.0
	p.process_material = pm
	var quad := QuadMesh.new()
	quad.size = Vector2(0.08, 0.08)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.albedo_color = Color("fff2a8")
	mat.emission_enabled = true
	mat.emission = Color("fff2a8")
	mat.emission_energy_multiplier = 4.0
	quad.material = mat
	p.draw_pass_1 = quad
	return p


func _build_ui() -> void:
	var bar := HBoxContainer.new()
	bar.position = Vector2(16, 16)
	bar.add_theme_constant_override("separation", 8)
	add_child(bar)
	_mode_button = _ui_button(bar, "", _toggle_mode)
	_ui_button(bar, tr("CAM_BLUR"), func(): _blur_on = not _blur_on; _rig.set_blur(0.08 if _blur_on else 0.0))
	_ui_button(bar, tr("CAM_BLOOM"), func(): _bloom_on = not _bloom_on)
	_ui_button(bar, tr("CAM_PARTICLES"), func(): _particles.emitting = not _particles.emitting; _particles.visible = _particles.emitting)
	_ui_button(bar, tr("CAM_BENCH"), run_bench)
	_ui_button(bar, tr("MENU_BACK"), func(): get_tree().change_scene_to_file("res://scenes/main.tscn"))
	_fps = Label.new()
	_fps.position = Vector2(16, 84)
	_fps.add_theme_font_size_override("font_size", 20)
	_fps.add_theme_color_override("font_outline_color", Color.BLACK)
	_fps.add_theme_constant_override("outline_size", 6)
	add_child(_fps)


func _ui_button(parent: Node, text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 56)
	b.add_theme_font_size_override("font_size", 18)
	b.pressed.connect(cb)
	parent.add_child(b)
	return b


# --- per frame ---------------------------------------------------------------

func _process(delta: float) -> void:
	_move_player(delta)
	_follow_jinli()
	var t := _rig.blend()
	# HD-2D look fades into flat, evenly lit classic look.
	_env.glow_enabled = _bloom_on and t < 0.999
	_env.glow_intensity = 0.9 * (1.0 - t)
	_env.ambient_light_energy = lerpf(0.45, 1.0, t)
	_sun.light_energy = lerpf(1.3, 0.6, t)
	_sun.shadow_enabled = t < 0.5
	for l in _lanterns:
		l.light_energy = 1.6 * (1.0 - t)
	var bb := BaseMaterial3D.BILLBOARD_ENABLED if t > 0.5 else BaseMaterial3D.BILLBOARD_FIXED_Y
	for s in _sprites:
		s.billboard = bb
	_layout_screen()
	_fps.text = "%s  %d FPS  %dx%d" % [tr("CAM_MODE_CLASSIC") if _rig.mode == CameraRig.CLASSIC else tr("CAM_MODE_HD2D"),
		Engine.get_frames_per_second(), _view.size.x, _view.size.y]


func _layout_screen() -> void:
	var canvas_scale := get_viewport().get_final_transform().get_scale().x
	var physical := Vector2(get_window().size)
	var logical := size
	if _rig.mode == CameraRig.CLASSIC and _rig.blend() >= 0.999:
		var factor := classic_scale(physical)
		var shown := Vector2(CLASSIC_RES) * factor / canvas_scale
		_screen.size = shown
		_screen.position = (logical - shown) / 2.0
		if _view.size != CLASSIC_RES:
			_view.size = CLASSIC_RES
	else:
		_screen.size = logical
		_screen.position = Vector2.ZERO
		var full := Vector2i(physical)
		if _view.size != full:
			_view.size = full


## Largest whole-number scale of the 640x360 classic image that fits the screen.
static func classic_scale(physical: Vector2) -> int:
	return maxi(1, floori(minf(physical.x / CLASSIC_RES.x, physical.y / CLASSIC_RES.y)))


func _move_player(delta: float) -> void:
	var dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if dir == Vector2.ZERO:
		dir = _touch_dir
	if dir == Vector2.ZERO:
		return
	var step := Vector3(dir.x, 0, dir.y) * MOVE_SPEED * delta
	var next := _player.position + step
	if not _blocked.has(Vector2i(roundi(next.x), roundi(next.z))):
		_player.position = next
		_trail.append(next)
		if _trail.size() > 40:
			_trail.pop_front()


func _follow_jinli() -> void:
	if _trail.size() > 18:
		_jinli.position = _jinli.position.lerp(_trail[0], 0.15)


func _input(event: InputEvent) -> void:
	# Touch: hold and drag anywhere to walk in that direction (Phase 0 stand-in for a virtual stick).
	if event is InputEventScreenTouch:
		if not event.pressed:
			_touch_dir = Vector2.ZERO
	elif event is InputEventScreenDrag:
		_touch_dir = (event.position - size / 2.0).normalized()


# --- modes -------------------------------------------------------------------

func _toggle_mode() -> void:
	_rig.set_mode(CameraRig.HD2D if _rig.mode == CameraRig.CLASSIC else CameraRig.CLASSIC)


func _on_mode_changed(mode: String) -> void:
	_mode_button.text = tr("CAM_MODE_HD2D") if mode == CameraRig.HD2D else tr("CAM_MODE_CLASSIC")
	_screen.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST if mode == CameraRig.CLASSIC else CanvasItem.TEXTURE_FILTER_LINEAR


## Measures average FPS in both modes and prints a WUYIN_BENCH line per mode.
func run_bench() -> void:
	if _benching:
		return
	_benching = true
	var results := {}
	for mode in [CameraRig.HD2D, CameraRig.CLASSIC]:
		_rig.set_mode(mode, false)
		_on_mode_changed(mode)
		for i in 30:
			await get_tree().process_frame
		var frames := 0
		var start := Time.get_ticks_usec()
		var worst := 0.0
		var last := start
		while Time.get_ticks_usec() - start < BENCH_SECONDS * 1_000_000:
			await get_tree().process_frame
			var now := Time.get_ticks_usec()
			worst = maxf(worst, (now - last) / 1000.0)
			last = now
			frames += 1
		var fps := frames / ((Time.get_ticks_usec() - start) / 1_000_000.0)
		results[mode] = fps
		print("WUYIN_BENCH mode=%s fps=%.1f worst_frame_ms=%.1f view=%dx%d renderer=%s" % [
			mode, fps, worst, _view.size.x, _view.size.y, RenderingServer.get_current_rendering_method()])
	_benching = false
	if "--camera-bench" in OS.get_cmdline_user_args():
		get_tree().quit()
