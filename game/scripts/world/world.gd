class_name World
extends Control
## The overworld: loads maps from data/maps, lets the player walk with touch,
## keyboard or controller, runs conversations and scripted events, starts
## battles (visible Lingshou, tall grass, events) and moves between maps.
## The 3D diorama renders into a SubViewport like the M0.6 camera test:
## HD-2D at 720 p internal height, classic 2D at 640x360 scaled by whole numbers.

const CLASSIC_RES := Vector2i(640, 360)
const HD2D_HEIGHT := 720
const MOVE_SPEED := 3.6
const PLAYER_RADIUS := 0.28
const TALK_RANGE := 1.35
const ENCOUNTER_GRACE_STEPS := 4
const JINLI_IDLE_GUIDE_S := 6.0
const AUTOSAVE_SLOT := 0

static var _instance: World

var state: GameState
var map: MapData
var busy := false  # an event, menu or battle has control

var dialog: DialogBox
var events: EventRunner
var touch: TouchControls

var _view: SubViewport
var _screen: TextureRect
var _rig: CameraRig
var _env: Environment
var _sun: DirectionalLight3D
var _map_root: Node3D
var _lights: Array[OmniLight3D] = []
var _actors := {}  # id -> Actor
var _wild: Array[Actor] = []
var _player: Actor
var _jinli: Actor
var _follower: Actor
var _trail: Array[Vector3] = []
var _facing := Vector2(0, 1)
var _last_tile := Vector2i(-1, -1)
var _grace := 0
var _idle_s := 0.0
var _guiding := false
var _fade: ColorRect
var _hud_name: Label
var _hud_quest: Label
var _ui_layer: CanvasLayer
var _overlay_layer: CanvasLayer
var _rng := RandomNumberGenerator.new()
var _wander_t := {}
var _silent := false


static func instance() -> World:
	return _instance


func _ready() -> void:
	_instance = self
	Inputs.ensure()
	state = GameState.current if GameState.current else GameState.new_game("Mei")
	GameState.current = state
	_rng.seed = Time.get_ticks_usec()
	theme = UiTheme.get_theme()
	_build_viewport()
	_build_ui()
	events = EventRunner.new(self)
	add_child(events)
	var start_map := state.map if state.map != "" and MapData.exists(state.map) else "weidendorf"
	if state.map == "" or not MapData.exists(state.map):
		await enter_map(start_map, "start", Vector2(-1, -1), false)
	else:
		await enter_map(start_map, "", state.pos, false)


func _exit_tree() -> void:
	if _instance == self:
		_instance = null


# --- setup -------------------------------------------------------------------

func _build_viewport() -> void:
	var bg := ColorRect.new()
	bg.color = Color.BLACK
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	_view = SubViewport.new()
	_view.size = Vector2i(1280, 720)
	_view.msaa_3d = Viewport.MSAA_DISABLED
	add_child(_view)
	_screen = TextureRect.new()
	_screen.texture = _view.get_texture()
	_screen.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_screen.stretch_mode = TextureRect.STRETCH_SCALE
	_screen.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(_screen)
	var we := WorldEnvironment.new()
	_env = Environment.new()
	_env.background_mode = Environment.BG_COLOR
	_env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	_env.glow_enabled = true
	_env.glow_bloom = 0.15
	_env.glow_hdr_threshold = 0.9
	_env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	_env.adjustment_enabled = true
	we.environment = _env
	_view.add_child(we)
	_sun = DirectionalLight3D.new()
	_sun.rotation_degrees = Vector3(-50, -35, 0)
	_sun.shadow_enabled = true
	_sun.directional_shadow_max_distance = 30.0
	_view.add_child(_sun)
	_rig = CameraRig.new()
	_view.add_child(_rig)
	_rig.set_mode(Settings.get_value("camera"), false)


func _build_ui() -> void:
	_ui_layer = CanvasLayer.new()
	_ui_layer.layer = 5
	add_child(_ui_layer)
	var hud := VBoxContainer.new()
	hud.position = Vector2(20, 16)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui_layer.add_child(hud)
	_hud_name = UiTheme.label("", 24, UiTheme.GOLD)
	_hud_name.add_theme_color_override("font_outline_color", Color.BLACK)
	_hud_name.add_theme_constant_override("outline_size", 8)
	hud.add_child(_hud_name)
	_hud_quest = UiTheme.label("", 18)
	_hud_quest.add_theme_color_override("font_outline_color", Color.BLACK)
	_hud_quest.add_theme_constant_override("outline_size", 6)
	hud.add_child(_hud_quest)
	touch = TouchControls.new()
	touch.interact.connect(_on_interact)
	touch.menu.connect(open_menu)
	_ui_layer.add_child(touch)
	dialog = DialogBox.new()
	_ui_layer.add_child(dialog)
	_overlay_layer = CanvasLayer.new()
	_overlay_layer.layer = 10
	add_child(_overlay_layer)
	var fade_layer := CanvasLayer.new()
	fade_layer.layer = 20
	add_child(fade_layer)
	_fade = ColorRect.new()
	_fade.color = Color.BLACK
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_layer.add_child(_fade)


# --- maps --------------------------------------------------------------------

## Loads a map and places the player at a named spawn (or at `pos` when given).
func enter_map(map_id: String, spawn := "", pos := Vector2(-1, -1), fade_out := true) -> void:
	busy = true
	touch.release()
	if fade_out:
		await fade(true)
	if _map_root:
		_map_root.queue_free()
	_actors.clear()
	_wild.clear()
	_trail.clear()
	map = MapData.load_map(map_id)
	state.map = map_id
	_map_root = Node3D.new()
	_view.add_child(_map_root)
	var built := MapBuilder.build(map)
	_map_root.add_child(built["root"])
	_lights = built["lights"]
	var start := pos if pos.x >= 0 else map.spawn(spawn)
	state.pos = start
	var p3 := Vector3(start.x, 0, start.y)
	_player = Actor.make(Sprites.hero(int(state.player["hair"]), int(state.player["outfit"])), p3, "player")
	_map_root.add_child(_player)
	_jinli = Actor.make(Sprites.character("jinli"), p3 + Vector3(-0.6, 0, 0.3), "jinli")
	_jinli.event = "jinli_talk"
	_map_root.add_child(_jinli)
	_actors["jinli"] = _jinli
	_jinli.visible = state.flag("jinli_follows")
	_update_follower()
	_rig.target = _player
	_rig.bounds = Rect2(-0.5, -0.5, map.width, map.height)
	_spawn_people()
	_spawn_wild()
	_apply_ambience()
	_hud_name.text = tr(map.name_key())
	update_quest()
	_last_tile = _tile_of(_player.position)
	_grace = ENCOUNTER_GRACE_STEPS
	if map.def.has("music") and not _silent_music_override():
		Audio.play(map.def["music"])
	await get_tree().process_frame
	await fade(false)
	busy = false
	state.save_game(AUTOSAVE_SLOT)
	if map.def.has("on_enter"):
		var ev: Dictionary = map.def["on_enter"]
		if MapData.condition_ok(ev, state):
			await events.run(ev["event"])


func _silent_music_override() -> bool:
	# Before the first tone returns, the silence is audible everywhere outside the prologue festival.
	if map.def.has("music_when_silent") and state.flag("silence_fell") and not state.flag("tone_jue"):
		Audio.play(map.def["music_when_silent"])
		return true
	return false


func _spawn_people() -> void:
	for e in map.def.get("npcs", []):
		var tex := Sprites.lingshou(e["lingshou"]) if e.has("lingshou") else Sprites.character(e.get("sprite", e["id"]))
		var a := Actor.make(tex, _v3(e["at"]), e["id"])
		a.event = e.get("event", "")
		a.entry = e
		a.scale = Vector3.ONE * float(e.get("scale", 1.0))
		_map_root.add_child(a)
		_actors[e["id"]] = a
	for e in map.def.get("objects", []):
		var a := Actor.make(_object_texture(e.get("kind", "sign")), _v3(e["at"]), e.get("id", "obj"))
		a.event = e.get("event", "")
		a.entry = e
		a.billboard = BaseMaterial3D.BILLBOARD_DISABLED if e.get("kind") == "invisible" else a.billboard
		a.visible = e.get("kind") != "invisible"
		_map_root.add_child(a)
		_actors[e.get("id", "obj%d" % _actors.size())] = a
	refresh_people()


func _object_texture(kind: String) -> Texture2D:
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	match kind:
		"sign":
			img.fill_rect(Rect2i(14, 16, 4, 16), Color("553520"))
			img.fill_rect(Rect2i(5, 6, 22, 13), Color("8a5b36"))
			img.fill_rect(Rect2i(7, 8, 18, 9), Color("c9ad7d"))
		"chest":
			img.fill_rect(Rect2i(6, 14, 20, 16), Color("7a4e2d"))
			img.fill_rect(Rect2i(6, 14, 20, 4), Color("a8382b"))
			img.fill_rect(Rect2i(15, 18, 3, 4), Color("e0b04a"))
		"shrine":
			img.fill_rect(Rect2i(8, 10, 16, 22), Color("8c8577"))
			img.fill_rect(Rect2i(4, 6, 24, 5), Color("a8382b"))
			img.fill_rect(Rect2i(13, 16, 6, 8), Color("e0b04a"))
		"chime":
			img.fill_rect(Rect2i(15, 0, 2, 10), Color("553520"))
			for i in 3:
				img.fill_rect(Rect2i(8 + i * 7, 10, 3, 12 + i * 2), Color("e0b04a"))
	return ImageTexture.create_from_image(img)


## Shows or hides people and objects after flags changed.
func refresh_people() -> void:
	for id in _actors:
		var a: Actor = _actors[id]
		if a == _jinli:
			a.visible = state.flag("jinli_follows")
			continue
		if not a.entry.is_empty():
			var ok := MapData.condition_ok(a.entry, state)
			a.visible = ok and a.entry.get("kind", "") != "invisible"
			a.set_meta("active", ok)
	for a in _wild.duplicate():
		if not MapData.condition_ok(a.entry, state):
			_wild.erase(a)
			a.queue_free()


func _spawn_wild() -> void:
	for e in map.def.get("lingshou", []):
		if not MapData.condition_ok(e, state):
			continue
		var a := Actor.make(Sprites.lingshou(e["species"]), _v3(e["at"]), e.get("id", e["species"]))
		a.entry = e
		a.scale = Vector3.ONE * float(e.get("scale", 0.85))
		_map_root.add_child(a)
		_wild.append(a)


func _update_follower() -> void:
	if _follower:
		_follower.queue_free()
		_follower = null
	if state.party.is_empty() or not _player:
		return
	_follower = Actor.make(Sprites.lingshou(state.party[0]["species"]), _player.position + Vector3(-1, 0, 0.5), "follower")
	_follower.scale = Vector3.ONE * 0.7
	_map_root.add_child(_follower)


func _apply_ambience() -> void:
	var time: String = map.def.get("time", "day")
	var ambience: Array = {
		"day": [Color("9fc3d8"), Color("c9d6e8"), Color("fff1d6"), 1.3, 0.5, 0.0],
		"dusk": [Color("d89a7a"), Color("b8a0b0"), Color("ffc890"), 0.9, 0.45, 1.0],
		"night": [Color("1a2238"), Color("4a5a88"), Color("9fb0e0"), 0.35, 0.35, 1.6],
	}.get(time, [Color("9fc3d8"), Color("c9d6e8"), Color("fff1d6"), 1.3, 0.5, 0.0])
	_env.background_color = ambience[0]
	_env.ambient_light_color = ambience[1]
	_sun.light_color = ambience[2]
	_sun.set_meta("energy", ambience[3])
	_env.set_meta("ambient", ambience[4])
	for l in _lights:
		l.set_meta("energy", ambience[5])
	set_silent(state.flag("silence_fell") and not state.flag("tone_jue") and map.def.get("silent", true))


## The stolen song drains the colour from the world until a tone returns.
func set_silent(on: bool) -> void:
	_silent = on
	_env.adjustment_saturation = 0.45 if on else 1.0
	_env.adjustment_brightness = 0.92 if on else 1.0


# --- frame -------------------------------------------------------------------

func _process(delta: float) -> void:
	if map == null or _player == null:
		return
	state.play_seconds += delta
	var t := _rig.blend()
	_env.glow_enabled = t < 0.999
	_env.glow_intensity = 0.9 * (1.0 - t)
	_env.ambient_light_energy = lerpf(float(_env.get_meta("ambient", 0.45)), 1.0, t)
	_sun.light_energy = lerpf(float(_sun.get_meta("energy", 1.3)), 0.6, t)
	_sun.shadow_enabled = t < 0.5
	for l in _lights:
		l.light_energy = float(l.get_meta("energy", 1.6)) * (1.0 - t)
	var bb := BaseMaterial3D.BILLBOARD_ENABLED if t > 0.5 else BaseMaterial3D.BILLBOARD_FIXED_Y
	for a in _map_root.get_children():
		if a is Actor:
			a.billboard = bb
	_layout_screen()
	touch.visible = not busy and not dialog.is_open()
	if not busy:
		_move_player(delta)
	else:
		_player.animate(delta, _player.moving)
	_follow(delta)
	_wander(delta)


func _layout_screen() -> void:
	var physical := Vector2(get_window().size)
	var canvas_scale := get_viewport().get_final_transform().get_scale().x
	var logical := size
	if _rig.mode == CameraRig.CLASSIC and _rig.blend() >= 0.999:
		var factor := maxi(1, floori(minf(physical.x / CLASSIC_RES.x, physical.y / CLASSIC_RES.y)))
		var shown := Vector2(CLASSIC_RES) * factor / canvas_scale
		_screen.size = shown
		_screen.position = (logical - shown) / 2.0
		_screen.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		if _view.size != CLASSIC_RES:
			_view.size = CLASSIC_RES
	else:
		_screen.size = logical
		_screen.position = Vector2.ZERO
		_screen.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		var h := mini(HD2D_HEIGHT, int(physical.y))
		var want := Vector2i(roundi(h * physical.x / maxf(1.0, physical.y)), h)
		if _view.size != want:
			_view.size = want


func _move_player(delta: float) -> void:
	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if dir == Vector2.ZERO:
		dir = touch.direction
	if dir == Vector2.ZERO:
		_player.animate(delta, false)
		_idle_s += delta
		if _idle_s > JINLI_IDLE_GUIDE_S and not _guiding:
			_guide()
		return
	_idle_s = 0.0
	_guiding = false
	if dir.length() > 1.0:
		dir = dir.normalized()
	_facing = dir.normalized()
	var step := Vector3(dir.x, 0, dir.y) * MOVE_SPEED * delta
	var p := _player.position
	# Axis-separated so the player slides along walls.
	var nx := p + Vector3(step.x, 0, 0)
	if _free(nx):
		p = nx
	var nz := p + Vector3(0, 0, step.z)
	if _free(nz):
		p = nz
	_player.position = p
	_player.animate(delta, true, dir.x)
	state.pos = Vector2(p.x, p.z)
	_trail.append(p)
	if _trail.size() > 60:
		_trail.pop_front()
	var tile := _tile_of(p)
	if tile != _last_tile:
		_last_tile = tile
		_on_new_tile(tile)
	_check_wild_contact()


func _free(p: Vector3) -> bool:
	for off in [Vector2(-PLAYER_RADIUS, -PLAYER_RADIUS * 0.5), Vector2(PLAYER_RADIUS, -PLAYER_RADIUS * 0.5),
			Vector2(-PLAYER_RADIUS, PLAYER_RADIUS * 0.6), Vector2(PLAYER_RADIUS, PLAYER_RADIUS * 0.6)]:
		var t := Vector2i(roundi(p.x + off.x), roundi(p.z + off.y))
		if not map.walkable(t.x, t.y):
			return false
	for id in _actors:
		var a: Actor = _actors[id]
		if a != _jinli and a.get_meta("active", false) and a.entry.get("solid", true) \
				and Vector2(a.position.x - p.x, a.position.z - p.z).length() < 0.55:
			return false
	return true


func _follow(delta: float) -> void:
	if _guiding:
		return
	if _jinli.visible and not _jinli.moving and _trail.size() > 14:
		var goal := _trail[_trail.size() - 14]
		var d := goal - _jinli.position
		if d.length() > 0.05:
			_jinli.position = _jinli.position.lerp(goal, minf(1.0, delta * 8.0))
			_jinli.animate(delta, d.length() > 0.02, d.x)
		else:
			_jinli.animate(delta, false)
	if _follower and _trail.size() > 28:
		var goal := _trail[_trail.size() - (28 if _jinli.visible else 14)]
		var d := goal - _follower.position
		_follower.position = _follower.position.lerp(goal, minf(1.0, delta * 8.0))
		_follower.animate(delta, d.length() > 0.02, d.x)


## Jinli runs ahead towards the current goal, sits and rings her bell.
func _guide() -> void:
	var goal = state.flag("goal", null)
	if not _jinli.visible or goal == null or busy:
		return
	var target := _goal_on_this_map(goal)
	if target.x < 0:
		return
	var from := _tile_of(_jinli.position)
	var route := map.path(from, target)
	if route.is_empty() or route.size() < 3:
		return
	_guiding = true
	var pts: Array[Vector3] = []
	for i in mini(5, route.size()):
		pts.append(Vector3(route[i].x, 0, route[i].y))
	_jinli.walk_path(pts, 3.2)
	await _jinli.arrived
	if _guiding:
		Audio.sfx("bell")


## goal: [map, x, z] or a list of such; returns the tile on this map (or the warp leading there).
func _goal_on_this_map(goal) -> Vector2i:
	if goal is Array and goal.size() == 3 and goal[0] is String:
		if goal[0] == map.id:
			return Vector2i(int(goal[1]), int(goal[2]))
		for w in map.def.get("warps", []):
			if w.get("to") == goal[0] or (w.has("toward") and goal[0] in w["toward"]):
				var r: Array = w["rect"]
				return Vector2i(int(r[0]) + int(r[2]) / 2, int(r[1]) + int(r[3]) / 2)
	return Vector2i(-1, -1)


func _wander(delta: float) -> void:
	for id in _actors:
		var a: Actor = _actors[id]
		var radius := int(a.entry.get("wander", 0))
		if radius <= 0 or a.moving or not a.visible or busy:
			continue
		_wander_t[id] = float(_wander_t.get(id, _rng.randf_range(1.0, 4.0))) - delta
		if _wander_t[id] > 0.0:
			continue
		_wander_t[id] = _rng.randf_range(2.5, 6.0)
		var home := Vector2i(int(a.entry["at"][0]), int(a.entry["at"][1]))
		var to := home + Vector2i(_rng.randi_range(-radius, radius), _rng.randi_range(-radius, radius))
		var route := map.path(_tile_of(a.position), to, 400)
		if not route.is_empty() and route.size() <= radius * 3:
			var pts: Array[Vector3] = []
			for r in route:
				pts.append(Vector3(r.x, 0, r.y))
			a.walk_path(pts, 1.4)
	for a in _wild:
		if a.moving or busy or a.entry.get("static", false):
			continue
		var key := "wild:%d" % a.get_instance_id()
		_wander_t[key] = float(_wander_t.get(key, _rng.randf_range(1.0, 3.0))) - delta
		if _wander_t[key] > 0.0:
			continue
		_wander_t[key] = _rng.randf_range(2.0, 4.5)
		var home := Vector2i(int(a.entry["at"][0]), int(a.entry["at"][1]))
		var to := home + Vector2i(_rng.randi_range(-2, 2), _rng.randi_range(-2, 2))
		if map.walkable(to.x, to.y):
			a.walk_to(Vector3(to.x, 0, to.y), 1.2)


# --- tiles, warps, triggers, encounters ---------------------------------------

func _tile_of(p: Vector3) -> Vector2i:
	return Vector2i(roundi(p.x), roundi(p.z))


func _on_new_tile(tile: Vector2i) -> void:
	for w in map.def.get("warps", []):
		if MapData.in_rect(tile, w["rect"]):
			if MapData.condition_ok(w, state):
				enter_map(w["to"], w["spawn"])
				return
			elif w.has("blocked_event"):
				_push_back()
				events.run(w["blocked_event"])
				return
	var i := 0
	for t in map.def.get("triggers", []):
		var once_flag := "trig_%s_%d" % [map.id, i]
		i += 1
		if MapData.in_rect(tile, t["rect"]) and MapData.condition_ok(t, state) and not state.flag(once_flag):
			if t.get("once", true):
				state.set_flag(once_flag)
			touch.release()
			events.run(t["event"])
			return
	if _grace > 0:
		_grace -= 1
		return
	if map.is_grass(tile.x, tile.y) and map.def.has("encounters") and MapData.condition_ok(map.def["encounters"], state):
		var enc: Dictionary = map.def["encounters"]
		if _rng.randf() < float(enc.get("rate", 0.1)):
			_random_encounter(enc)


func _push_back() -> void:
	if _trail.size() > 8:
		_player.position = _trail[_trail.size() - 8]
		_last_tile = _tile_of(_player.position)


func _random_encounter(enc: Dictionary) -> void:
	var table: Array = enc.get("table", [])
	var total := 0
	for e in table:
		total += int(e.get("weight", 1))
	if total == 0:
		return
	var roll := _rng.randi_range(1, total)
	for e in table:
		roll -= int(e.get("weight", 1))
		if roll <= 0:
			var lv: Array = e.get("levels", [3, 5])
			_grace = ENCOUNTER_GRACE_STEPS
			start_wild_battle(e["species"], _rng.randi_range(int(lv[0]), int(lv[1])), null)
			return


func _check_wild_contact() -> void:
	for a in _wild:
		if a.visible and Vector2(a.position.x - _player.position.x, a.position.z - _player.position.z).length() < 0.7:
			if a.entry.has("event"):
				events.run(a.entry["event"])
			else:
				var lv: Array = a.entry.get("levels", [a.entry.get("level", 4), a.entry.get("level", 4)])
				start_wild_battle(a.entry["species"], _rng.randi_range(int(lv[0]), int(lv[1])), a)
			return


func start_wild_battle(species: String, level: int, actor: Actor) -> void:
	busy = true
	touch.release()
	var role := "silenced" if GameData.lingshou(species)["alignment"] == "silenced" or (actor and actor.entry.get("role") == "silenced") else ""
	if role == "" and GameData.lingshou(species)["alignment"] in ["wild", "free"]:
		role = "wild"
	var r := await battle({"enemies": [{"id": species, "level": level, "role": role}], "active": 1})
	if actor and r["outcome"] in ["win", "tamed", "freed"]:
		actor.visible = false
		if actor.entry.has("id"):
			state.set_flag("gone_" + actor.entry["id"])
		_wild.erase(actor)
		actor.queue_free()
	elif actor:
		actor.position = Vector3(actor.entry["at"][0], 0, actor.entry["at"][1])
		_player.position = _trail[maxi(0, _trail.size() - 10)] if _trail.size() > 0 else _player.position
	busy = false


# --- battles -----------------------------------------------------------------

## Runs a battle over the world and applies the result to the game state.
## setup: {"enemies": [...], "active": 1|2, "bg", "music", "allow_lose", "foe"}
## Returns {"outcome", "battle"}.
func battle(setup: Dictionary) -> Dictionary:
	busy = true
	touch.release()
	Audio.sfx("encounter")
	await fade(true, 0.25)
	var prev_music := Audio.current()
	Audio.play(setup.get("music", "battle"))
	var view := BattleView.new()
	setup = setup.duplicate(true)
	setup["bg"] = setup.get("bg", map.def.get("battle_bg", "river"))
	_overlay_layer.add_child(view)
	_screen.visible = false
	fade(false, 0.25)
	var result: Dictionary = await view.run(setup, state)
	await fade(true, 0.3)
	view.queue_free()
	_screen.visible = true
	state.count("battles")
	var b: Battle = result["battle"]
	state.sync_party(b.sides[0]["party"])
	for u in b.sides[0]["party"]:
		state.add_bond(u.uid, 2 if result["outcome"] in ["win", "tamed", "freed"] else 1)
	_update_follower()
	if result["outcome"] == "lose" and not setup.get("allow_lose", false):
		var lost := state.apply_defeat()
		await enter_map(state.inn["map"], state.inn["spawn"], Vector2(-1, -1), false)
		await events.say_key("narrator", "MSG_DEFEAT", {"coins": lost})
	else:
		if result["outcome"] == "lose":
			for rec in state.party:
				rec["hp"] = maxi(1, int(rec["hp"]))
		Audio.play(prev_music)
		await fade(false, 0.3)
		state.save_game(AUTOSAVE_SLOT)
	busy = false
	return result


## Taming scene without a battle (prologue tutorial).
func befriend(species: String, level: int) -> Dictionary:
	busy = true
	touch.release()
	await fade(true, 0.25)
	var view := BefriendView.new()
	_overlay_layer.add_child(view)
	_screen.visible = false
	fade(false, 0.25)
	var r: Dictionary = await view.run(species, level, state)
	await fade(true, 0.3)
	view.queue_free()
	_screen.visible = true
	_update_follower()
	await fade(false, 0.3)
	state.save_game(AUTOSAVE_SLOT)
	busy = false
	return r


# --- interaction -------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if busy or dialog.is_open():
		return
	if event.is_action_pressed("interact"):
		_on_interact()
	elif event.is_action_pressed("menu"):
		open_menu()


func _on_interact() -> void:
	if busy or dialog.is_open():
		return
	var best: Actor = null
	var best_score := INF
	var p := Vector2(_player.position.x, _player.position.z)
	for id in _actors:
		var a: Actor = _actors[id]
		if a.event == "" or not (a.visible or a.entry.get("kind") == "invisible"):
			continue
		if a != _jinli and not a.get_meta("active", false):
			continue
		var to := Vector2(a.position.x, a.position.z) - p
		var d := to.length()
		if d > TALK_RANGE:
			continue
		var score := d - (0.5 if to.normalized().dot(_facing) > 0.3 else 0.0)
		if score < best_score:
			best_score = score
			best = a
	if best:
		_idle_s = 0.0
		touch.release()
		if best.entry.has("face") or best == _jinli:
			best.flip_h = best.position.x < _player.position.x
		events.run(best.event, best.actor_id)


func open_menu() -> void:
	if busy or dialog.is_open():
		return
	busy = true
	touch.release()
	var menu := GameMenu.new()
	_overlay_layer.add_child(menu)
	await menu.closed
	menu.queue_free()
	_update_follower()
	_rig.set_mode(Settings.get_value("camera"))
	update_quest()
	busy = false


## Opens any UI control on the overlay and waits for its `closed` signal.
func show_ui(control: Control) -> void:
	_overlay_layer.add_child(control)
	if DialogBox.autopilot:
		await get_tree().process_frame
		DialogBox.transcript.append("  [ui] " + control.get_class() + " " + str(control.get_script().get_global_name()))
		control.queue_free()
		return
	await control.closed
	control.queue_free()


func update_quest() -> void:
	var q: String = state.flag("quest", "")
	_hud_quest.text = ("◆ " + tr(q)) if q != "" else ""


# --- helpers for events ------------------------------------------------------

func actor(id: String) -> Actor:
	match id:
		"player":
			return _player
		"jinli":
			return _jinli
	return _actors.get(id)


func player_name() -> String:
	return String(state.player.get("name", ""))


func fade(to_black: bool, seconds := 0.35) -> void:
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 1.0 if to_black else 0.0, seconds)
	await tw.finished


func teleport_player(tile: Vector2) -> void:
	_player.position = Vector3(tile.x, 0, tile.y)
	_trail.clear()
	_last_tile = _tile_of(_player.position)
	if _jinli.visible:
		_jinli.position = _player.position + Vector3(-0.7, 0, 0.2)
	if _follower:
		_follower.position = _player.position + Vector3(-1.2, 0, 0.4)


func refresh_party_follower() -> void:
	_update_follower()


func _v3(at: Array) -> Vector3:
	return Vector3(float(at[0]), 0, float(at[1]))
