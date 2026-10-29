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
## Game minutes per real second: a day of 06:00-24:00 takes about 16 minutes (GDD "Zeit").
const CLOCK_SPEED := 1.1
const BIKE_SPEED := 1.75
## Ambience presets: sky, ambient, sun colour, sun energy, ambient energy, lantern energy.
const AMBIENCE := {
	"day": [Color("9fc3d8"), Color("c9d6e8"), Color("fff1d6"), 1.3, 0.5, 0.0],
	"dawn": [Color("e0b0a0"), Color("c0b0c8"), Color("ffd8b0"), 0.9, 0.45, 0.6],
	"dusk": [Color("d89a7a"), Color("b8a0b0"), Color("ffc890"), 0.9, 0.45, 1.0],
	"night": [Color("1a2238"), Color("5a6a98"), Color("9fb0e0"), 0.5, 0.5, 1.6],
	"indoor": [Color("120e18"), Color("e0c8a8"), Color("ffe0b0"), 0.35, 0.8, 1.4],
}

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
var _follower2: Actor
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
var _fps_log_t := 0.0
var _clock_acc := 0.0
var _ambience_t := 0.0
var _weather_fx: WeatherFx
var _ambient: AmbientFx
var _cloud_shadows: Decal
var _sounds: Ambience
var _sound_key := ""
var _bubble: Sprite3D
var _emote_t := 4.0
var _dust: CPUParticles3D
var _hud_time: Label
static var _graph := {}  # map id -> [{"to", "rect", "warp"}] (Jinli's route finding)


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
	_sounds = Ambience.new()
	add_child(_sounds)
	var start_map := state.map if state.map != "" and MapData.exists(state.map) else "weidendorf"
	if state.map == "" or not MapData.exists(state.map):
		await enter_map(start_map, "start", Vector2(-1, -1), false)
	else:
		await enter_map(start_map, "", state.pos, false)


func _notification(what: int) -> void:
	# Phones kill paused apps without warning: save whenever the game leaves the foreground.
	if what in [NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_WM_CLOSE_REQUEST, NOTIFICATION_APPLICATION_FOCUS_OUT]:
		if state and map:
			state.save_game(AUTOSAVE_SLOT)
	elif what == NOTIFICATION_WM_GO_BACK_REQUEST:
		# Android back button: open the menu (menus close themselves on "menu"/ui_cancel).
		if not busy and not dialog.is_open():
			open_menu()


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
	var hud_box := PanelContainer.new()
	var hud_skin := UiTheme.skin("panel")
	hud_skin.modulate_color = Color(1, 1, 1, 0.82)
	hud_box.add_theme_stylebox_override("panel", hud_skin)
	hud_box.position = Vector2(14, 12)
	hud_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui_layer.add_child(hud_box)
	var hud := VBoxContainer.new()
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_theme_constant_override("separation", 0)
	hud_box.add_child(hud)
	_hud_name = UiTheme.label("", 24, UiTheme.GOLD)
	_hud_name.add_theme_color_override("font_outline_color", Color.BLACK)
	_hud_name.add_theme_constant_override("outline_size", 8)
	hud.add_child(_hud_name)
	_hud_time = UiTheme.label("", 16, UiTheme.MUTED)
	_hud_time.add_theme_color_override("font_outline_color", Color.BLACK)
	_hud_time.add_theme_constant_override("outline_size", 6)
	hud.add_child(_hud_time)
	_hud_quest = UiTheme.label("", 18)
	_hud_quest.add_theme_color_override("font_outline_color", Color.BLACK)
	_hud_quest.add_theme_constant_override("outline_size", 6)
	_hud_quest.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hud_quest.custom_minimum_size = Vector2(460, 0)
	hud.add_child(_hud_quest)
	_weather_fx = WeatherFx.new()
	var fx_layer := CanvasLayer.new()
	fx_layer.layer = 3
	add_child(fx_layer)
	fx_layer.add_child(_weather_fx)
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
	if map.def.get("town", false) or map_id in ["weidendorf", "kreuzweg"]:
		state.set_flag("visited_" + map_id)
	if map.def.has("pens"):
		_apply_pens()
	_map_root = Node3D.new()
	_view.add_child(_map_root)
	var built := MapBuilder.build(map, state.region_silent(map.def.get("region", "bamboo")))
	_map_root.add_child(built["root"])
	_lights = built["lights"]
	var start := pos if pos.x >= 0 else map.spawn(spawn)
	state.pos = start
	var p3 := Vector3(start.x, 0, start.y)
	_player = Actor.make(Sprites.hero(int(state.player["hair"]), int(state.player["outfit"])), p3, "player")
	_player.breathe = false
	_player.set_directions(Sprites.hero(int(state.player["hair"]), int(state.player["outfit"]), "back"),
		Sprites.hero(int(state.player["hair"]), int(state.player["outfit"]), "side"))
	_map_root.add_child(_player)
	_player.add_silhouette()
	_jinli = Actor.make(Sprites.character("jinli"), p3 + Vector3(-0.6, 0, 0.3), "jinli")
	_jinli.set_directions(Sprites.character_view("jinli", "back"), Sprites.character_view("jinli", "side"))
	_jinli.event = "jinli_talk"
	_map_root.add_child(_jinli)
	_actors["jinli"] = _jinli
	_jinli.visible = state.flag("jinli_follows")
	_update_follower()
	_rig.target = _player
	_rig.bounds = Rect2(-0.5, -0.5, map.width, map.height)
	_ambient = AmbientFx.new()
	_map_root.add_child(_ambient)
	_cloud_shadows = _make_cloud_shadows()
	_map_root.add_child(_cloud_shadows)
	_bubble = _make_bubble()
	_map_root.add_child(_bubble)
	_dust = _make_dust()
	_map_root.add_child(_dust)
	_spawn_people()
	_spawn_wild()
	_spawn_farm()
	_apply_ambience()
	_hud_name.text = tr(map.name_key())
	update_quest()
	_last_tile = _tile_of(_player.position)
	_grace = ENCOUNTER_GRACE_STEPS
	_play_map_music()
	await get_tree().process_frame
	await fade(false)
	busy = false
	state.save_game(AUTOSAVE_SLOT)
	if state.flags.has("_dev_event"):
		var ev: String = state.flags["_dev_event"]
		state.flags.erase("_dev_event")
		await events.run(ev)
	var entries = map.def.get("on_enter", [])
	for ev in (entries if entries is Array else [entries]):
		if MapData.condition_ok(ev, state):
			await events.run(ev["event"])
			break


## Map music; in silent regions the special silence track or a muffled version of the region's music.
func _play_map_music() -> void:
	var silent := state.region_silent(map.def.get("region", "bamboo"))
	if silent and map.def.has("music_when_silent"):
		Audio.set_muffled(false)
		Audio.play(map.def["music_when_silent"])
	elif map.def.has("music"):
		Audio.set_muffled(silent)
		Audio.play(map.def["music"])


func region() -> String:
	return map.def.get("region", "bamboo") if map else "bamboo"


func _spawn_people() -> void:
	for e in map.def.get("npcs", []):
		if e.has("prop") and Props.texture(e["prop"]) == null:
			continue  # critter art not there yet
		var tex := Sprites.lingshou(e["lingshou"]) if e.has("lingshou") else (Props.texture(e["prop"]) if e.has("prop") else Sprites.character(e.get("sprite", e["id"])))
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


## Farm: pen ground by type (built pens) and pen signs.
func _apply_pens() -> void:
	var pens: Array = map.def["pens"]
	for i in pens.size():
		var r: Array = pens[i]["rect"]
		var type: String = state.home["pens"][i]["type"] if i < Farm.pen_count(state) else "empty"
		for z in range(int(r[1]), int(r[1]) + int(r[3])):
			for x in range(int(r[0]), int(r[0]) + int(r[2])):
				map.overrides[Vector2i(x, z)] = MapData.PEN_TILES[type]
		if i < Farm.pen_slots(state):
			var sign := {"id": "pen_%d" % i, "kind": "sign", "at": pens[i]["sign"], "event": "pen_sign", "solid": false}
			map.def["objects"] = map.def.get("objects", []) + [sign]


func _spawn_farm() -> void:
	if not map.def.has("pens"):
		return
	var pens: Array = map.def["pens"]
	var count := {}
	for rec in state.farm:
		var pen := int(rec.get("pen", -1))
		var at: Vector2
		if pen >= 0 and pen < pens.size():
			var r: Array = pens[pen]["rect"]
			var n := int(count.get(pen, 0))
			count[pen] = n + 1
			at = Vector2(int(r[0]) + (0 if n == 0 else int(r[2]) - 1), int(r[1]) + n % 2)
		else:
			var n := int(count.get(-1, 0))
			count[-1] = n + 1
			at = Vector2(28 - n, 6)
		var a := Actor.make(Sprites.lingshou_rec(rec), Vector3(at.x, 0, at.y), "farm_" + String(rec["uid"]))
		a.scale = Vector3.ONE * (0.55 if rec.get("stage", "adult") == "young" else 0.75)
		a.event = "pen_sign"
		a.entry = {"at": [at.x, at.y], "wander": 1, "pen": pen, "solid": false}
		_map_root.add_child(a)
		_actors[a.actor_id] = a


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
		var a := Actor.make(Sprites.lingshou(e["species"], e.get("role") == "silenced"), _v3(e["at"]), e.get("id", e["species"]))
		a.entry = e
		a.scale = Vector3.ONE * float(e.get("scale", 0.85))
		if e.get("role") == "silenced" and a.texture == Sprites.lingshou(e["species"]):
			a.modulate = Color(0.6, 0.6, 0.68)
		_map_root.add_child(a)
		_wild.append(a)


func _update_follower() -> void:
	for f in [_follower, _follower2]:
		if f:
			f.queue_free()
	_follower = null
	_follower2 = null
	if state.party.is_empty() or not _player:
		return
	_follower = Actor.make(Sprites.lingshou_rec(state.party[0]), _player.position + Vector3(-1, 0, 0.5), "follower")
	_follower.scale = Vector3.ONE * 0.7
	_map_root.add_child(_follower)
	if state.party.size() > 1 and not map.def.get("indoor", false):
		_follower2 = Actor.make(Sprites.lingshou_rec(state.party[1]), _player.position + Vector3(-1.6, 0, 0.8), "follower2")
		_follower2.scale = Vector3.ONE * 0.62
		_map_root.add_child(_follower2)


## Uses the game clock once the journey has begun; before that (and on maps
## with "fixed_time") the map's own time of day.
func uses_clock() -> bool:
	return state.flag("prologue_done") and not map.def.get("fixed_time", false) and not map.def.get("indoor", false)


func _ambience_now() -> Array:
	if not uses_clock():
		return AMBIENCE.get(map.def.get("time", "day"), AMBIENCE["day"])
	var h := state.minute / 60.0
	var keys := [[0.0, "night"], [5.0, "night"], [6.5, "dawn"], [8.0, "day"], [17.0, "day"], [19.0, "dusk"], [21.0, "night"], [24.0, "night"]]
	for i in keys.size() - 1:
		if h >= keys[i][0] and h < keys[i + 1][0]:
			var a: Array = AMBIENCE[keys[i][1]]
			var b: Array = AMBIENCE[keys[i + 1][1]]
			var t: float = (h - keys[i][0]) / (keys[i + 1][0] - keys[i][0])
			var out := []
			for k in a.size():
				out.append(a[k].lerp(b[k], t) if a[k] is Color else lerpf(a[k], b[k], t))
			return out
	return AMBIENCE["day"]


func _apply_ambience() -> void:
	var ambience := _ambience_now()
	var w := Weather.current(state, map)
	_env.background_color = ambience[0]
	_env.ambient_light_color = ambience[1]
	_sun.light_color = ambience[2]
	var sun_energy: float = ambience[3]
	if w in ["cloudy", "rain", "fog", "snow"]:
		sun_energy *= 0.7
	elif w in ["storm", "sandstorm"]:
		sun_energy *= 0.5
	_sun.set_meta("energy", sun_energy)
	_env.set_meta("ambient", ambience[4])
	for l in _lights:
		l.set_meta("energy", ambience[5])
	# Light haze in the region's colour for depth (aerial perspective); weather makes it thicker.
	var haze: Array = {"bamboo": [Color("cfe0c8"), 0.006], "hub": [Color("dde0d0"), 0.005], "river": [Color("d0dce4"), 0.014],
		"ridge": [Color("f0d0b0"), 0.005], "dunes": [Color("f0dcb0"), 0.008], "pillars": [Color("e8eef4"), 0.012],
		"temple": [Color("f8e8d0"), 0.01]}.get(region(), [Color.WHITE, 0.0])
	var night_dim := 0.35 if uses_clock() and state.is_night() else 1.0
	_env.fog_enabled = not map.def.get("indoor", false)
	_env.fog_light_color = {"fog": Color("c8d0d8"), "sandstorm": Color("d8b878"), "snow": Color("e8eef4")}.get(w, haze[0]) * night_dim
	_env.fog_sky_affect = 0.0
	if w in ["fog", "sandstorm", "snow"]:
		_env.fog_mode = Environment.FOG_MODE_EXPONENTIAL
		_env.fog_density = {"fog": 0.05, "sandstorm": 0.06, "snow": 0.025}[w]
	else:
		# Depth haze: clear up to the player, fading towards the far edge of the view.
		_env.fog_mode = Environment.FOG_MODE_DEPTH
		_env.fog_depth_begin = 17.0
		_env.fog_depth_end = 42.0
		_env.fog_depth_curve = 1.4
		_env.fog_density = clampf(float(haze[1]) * 40.0, 0.0, 0.55)
	_weather_fx.set_kind(w)
	set_silent(state.region_silent(region()) and map.def.get("silent", true))
	if _sounds:
		var night: bool = uses_clock() and state.is_night() or map.def.get("time", "") == "night"
		var town: bool = map.def.get("town", false) or map.id in ["weidendorf", "teeufer", "kreuzweg"] or map.def.has("parent")
		var water := false
		for row in map.rows:
			if "~" in row:
				water = true
				break
		var mix := Ambience.mix(region(), town, map.def.get("indoor", false), night, _silent, water, w)
		var key := str(mix)
		if key != _sound_key:
			_sound_key = key
			_sounds.apply(mix)
	if _ambient:
		var h: float = state.minute / 60.0 if uses_clock() else {"night": 23.0, "dusk": 19.5}.get(map.def.get("time", "day"), 12.0)
		_ambient.configure("indoor" if map.def.get("indoor", false) else region(), h >= 20.0 or h < 5.0, _silent, w)
	_update_time_label()


func _update_time_label() -> void:
	_hud_time.visible = state.flag("prologue_done")
	if not state.flag("prologue_done"):
		_hud_time.text = ""
		return
	var w := Weather.current(state, map)
	_hud_time.text = "%s · %02d:%02d %s" % [tr("UI_DAY_N").format({"n": state.day}), state.minute / 60, state.minute % 60, Weather.icon(w)]


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
	if OS.is_debug_build():
		_fps_log_t += delta
		if _fps_log_t > 10.0:
			_fps_log_t = 0.0
			print("WUYIN_FPS map=%s fps=%d view=%dx%d mode=%s" % [map.id, Engine.get_frames_per_second(), _view.size.x, _view.size.y, _rig.mode])
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
	if not busy and not dialog.is_open() and uses_clock():
		_clock_acc += delta * CLOCK_SPEED
		if _clock_acc >= 1.0:
			var m := int(_clock_acc)
			_clock_acc -= m
			state.minute = (state.minute + m) % 1440
	_ambience_t += delta
	if _ambience_t > 1.0:
		_ambience_t = 0.0
		_apply_ambience()
	_layout_screen()
	touch.visible = not busy and not dialog.is_open()
	if not busy:
		_move_player(delta)
	else:
		_player.animate(delta, _player.moving)
	_follow(delta)
	_wander(delta)
	_settle_heights(delta)
	if _ambient:
		_ambient.position = _player.position
	if _cloud_shadows:
		# Cloud shadows drift over the land on fine days (HD-2D diorama feel).
		var ct := Time.get_ticks_msec() / 1000.0
		_cloud_shadows.position = Vector3(_player.position.x - fmod(ct * 0.35, 24.0) + 12.0, 2.0, _player.position.z - fmod(ct * 0.12, 24.0) + 12.0)
		var w := Weather.current(state, map)
		_cloud_shadows.visible = uses_clock() and not state.is_night() and w in ["sun", "cloudy", ""] and not map.def.get("indoor", false) \
			and region() not in ["pillars", "temple"]
	_update_bubble()
	_emotes(delta)
	if _dust:
		var tile := _tile_of(_player.position)
		var ground: String = map.info(tile.x, tile.y)[0]
		_dust.position = _player.position + Vector3(0, 0.05, 0.1)
		_dust.emitting = not busy and (Input.get_vector("move_left", "move_right", "move_up", "move_down") != Vector2.ZERO \
			or touch.direction != Vector2.ZERO) and ground in ["path", "sand", "redrock", "plaza", "cloudstone"]


## Everyone stands on the ground of their tile (terraces, stairs); smooth steps.
func _settle_heights(delta: float) -> void:
	if map.def.get("heights", []).is_empty():
		return
	var k := minf(1.0, delta * 14.0)
	for a in [_player, _jinli, _follower, _follower2]:
		if a:
			a.position.y = lerpf(a.position.y, map.height_at(roundi(a.position.x), roundi(a.position.z)), k)
	for id in _actors:
		var a: Actor = _actors[id]
		a.position.y = lerpf(a.position.y, map.height_at(roundi(a.position.x), roundi(a.position.z)), k)
	for a in _wild:
		a.position.y = lerpf(a.position.y, map.height_at(roundi(a.position.x), roundi(a.position.z)), k)


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
	var speed := MOVE_SPEED * (BIKE_SPEED if state.item_count("fahrrad") > 0 and not map.def.get("indoor", false) else 1.0)
	var step := Vector3(dir.x, 0, dir.y) * speed * delta
	var p := _player.position
	# Axis-separated so the player slides along walls.
	var nx := p + Vector3(step.x, 0, 0)
	if _free(nx):
		p = nx
	var nz := p + Vector3(0, 0, step.z)
	if _free(nz):
		p = nz
	_player.position = p
	if dir.y < -0.6 and absf(dir.x) < 0.5 and not _free(_player.position + Vector3(0, 0, -0.12)):
		var door_tile := Vector2i(roundi(p.x), roundi(p.z - 0.7))
		if map.tile(door_tile.x, door_tile.y) == "D":
			for id in _actors:
				var a: Actor = _actors[id]
				if a.entry.has("enter") and Vector2i(roundi(a.position.x), roundi(a.position.z)) == door_tile:
					_enter_door(a)
					return
	_player.animate(delta, true, dir.x, dir.y)
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
	var here := map.height_at(roundi(_player.position.x), roundi(_player.position.z))
	for off in [Vector2(-PLAYER_RADIUS, -PLAYER_RADIUS * 0.5), Vector2(PLAYER_RADIUS, -PLAYER_RADIUS * 0.5),
			Vector2(-PLAYER_RADIUS, PLAYER_RADIUS * 0.6), Vector2(PLAYER_RADIUS, PLAYER_RADIUS * 0.6)]:
		var t := Vector2i(roundi(p.x + off.x), roundi(p.z + off.y))
		if not map.walkable(t.x, t.y):
			return false
		# Cliffs: only small steps up or down (stairs and ramps are built in small steps).
		if absf(map.height_at(t.x, t.y) - here) > 0.36:
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
			_jinli.animate(delta, d.length() > 0.02, d.x, d.z)
		else:
			_jinli.animate(delta, false)
	if _follower and _trail.size() > 28:
		var goal := _trail[_trail.size() - (28 if _jinli.visible else 14)]
		var d := goal - _follower.position
		_follower.position = _follower.position.lerp(goal, minf(1.0, delta * 8.0))
		_follower.animate(delta, d.length() > 0.02, d.x, d.z)
	if _follower2 and _trail.size() > 44:
		var goal := _trail[_trail.size() - (44 if _jinli.visible else 30)]
		var d := goal - _follower2.position
		_follower2.position = _follower2.position.lerp(goal, minf(1.0, delta * 8.0))
		_follower2.animate(delta, d.length() > 0.02, d.x, d.z)


## Jinli runs ahead towards the current goal, sits and rings her bell.
func _guide() -> void:
	var goal = current_goal()
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


## The goal Jinli leads to: the region's own task first, else the main one.
func current_goal():
	var rg: Dictionary = state.flag("rgoal", {})
	if rg.has(region()):
		return rg[region()]
	return state.flag("goal", null)


func current_quest() -> String:
	var rq: Dictionary = state.flag("rquest", {})
	if rq.has(region()):
		return rq[region()]
	return state.flag("quest", "")


## goal: [map, x, z]; returns the tile on this map, or the warp on the shortest way there.
func _goal_on_this_map(goal) -> Vector2i:
	if goal is Array and goal.size() == 3 and goal[0] is String:
		if goal[0] == map.id:
			return Vector2i(int(goal[1]), int(goal[2]))
		var w := next_warp_toward(map.id, goal[0])
		if not w.is_empty():
			var r: Array = w["rect"]
			return Vector2i(int(r[0]) + int(r[2]) / 2, int(r[1]) + int(r[3]) / 2)
	return Vector2i(-1, -1)


## First warp on the shortest open route from map `from` to map `to` (breadth-first over all maps).
func next_warp_toward(from: String, to: String) -> Dictionary:
	if _graph.is_empty():
		for id in MapData.all_ids():
			_graph[id] = MapData.load_map(id).def.get("warps", [])
	var first := {from: {}}
	var queue: Array[String] = [from]
	while not queue.is_empty():
		var cur: String = queue.pop_front()
		if cur == to:
			return first[cur]
		for w in _graph.get(cur, []):
			if not MapData.condition_ok(w, state) or first.has(w["to"]):
				continue
			first[w["to"]] = w if cur == from else first[cur]
			queue.append(w["to"])
	return {}


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
	var night := uses_clock() and state.is_night()
	var table: Array = enc.get("table", []).filter(func(e): return bool(e.get("night", night)) == night or not e.has("night"))
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
			# Silenced ones roam only while their region is still under the silence.
			var silenced: bool = e.get("silenced", false) and state.region_silent(region())
			start_wild_battle(e["species"], _rng.randi_range(int(lv[0]), int(lv[1])), null, silenced)
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


func start_wild_battle(species: String, level: int, actor: Actor, silenced := false) -> void:
	busy = true
	touch.release()
	var role := "silenced" if silenced or GameData.lingshou(species)["alignment"] == "silenced" or (actor and actor.entry.get("role") == "silenced") else ""
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
	await _exclaim()
	await _wipe(true)
	var prev_music := Audio.current()
	Audio.play(setup.get("music", "battle"))
	var view := BattleView.new()
	setup = setup.duplicate(true)
	setup["bg"] = setup.get("bg", map.def.get("battle_bg", "river"))
	setup["mods"] = battle_mods()
	var avg := 0.0
	for rec in state.party:
		avg += int(rec["level"])
	avg /= maxf(1.0, state.party.size())
	for e in setup["enemies"]:
		if e.has("scale"):
			e["level"] = clampi(maxi(int(e.get("level", 5)), roundi(avg) + int(e["scale"])), 1, BattleUnit.MAX_LEVEL)
	_overlay_layer.add_child(view)
	_screen.visible = false
	_wipe(false)
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


## Weather and today's dish as battle modifiers (see Battle.mods).
func battle_mods() -> Dictionary:
	var mods := {"weather": Weather.current(state, map)}
	match state.buff_effect():
		"xp":
			mods["xp_mult"] = 1.3
		"atk":
			mods["atk_mult"] = {0: 1.12}
		"def":
			mods["def_mult"] = {0: 1.12}
		"trust":
			mods["trust_bonus"] = 8
		"coins":
			mods["coin_mult"] = 1.4
	return mods


## Talking someone round outside of battle (see Persuader); true on success.
func persuade(spec: Dictionary) -> bool:
	busy = true
	touch.release()
	dialog.hide_box()
	var view := PersuadeView.new()
	_overlay_layer.add_child(view)
	var ok: bool = await view.run(spec, state)
	view.queue_free()
	return ok


## Sleeping in a bed ends the day (GDD "Zeit"): farm night, diary, new weather.
func sleep() -> void:
	busy = true
	await fade(true, 0.6)
	var diary := state.sleep()
	Audio.sfx("heal")
	_apply_ambience()
	_play_map_music()
	await get_tree().create_timer(0.4).timeout
	await fade(false, 0.6)
	await events.say_key("narrator", "MSG_MORNING", {"day": state.day})
	var lines := await FarmDiary.lines(diary, state)
	for line in lines:
		await events.say_text("narrator", line)
	state.save_game(AUTOSAVE_SLOT)


## Taming scene without a battle (prologue tutorial, Wusheng's crane).
func befriend(species: String, level: int, join := true) -> Dictionary:
	busy = true
	touch.release()
	await fade(true, 0.25)
	var view := BefriendView.new()
	_overlay_layer.add_child(view)
	_screen.visible = false
	fade(false, 0.25)
	var r: Dictionary = await view.run(species, level, state, join)
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


static var _emote_tex := {}


## Pixel emotes: a gold note, a pink heart, grey dots (silence).
static func _emote_texture(kind: String) -> Texture2D:
	if _emote_tex.has(kind):
		return _emote_tex[kind]
	var img := Image.create(12, 12, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var o := Color("2a2230")
	match kind:
		"note":
			var c := Color("f0c050")
			img.fill_rect(Rect2i(6, 1, 2, 8), o)
			img.fill_rect(Rect2i(7, 1, 3, 2), o)
			img.fill_rect(Rect2i(3, 7, 5, 4), o)
			img.fill_rect(Rect2i(4, 8, 3, 2), c)
			img.fill_rect(Rect2i(7, 2, 2, 1), c)
		"heart":
			var c := Color("e8607a")
			for y in 12:
				for x in 12:
					var px := (x - 5.5) / 5.0
					var py := (y - 4.5) / 5.0
					var v := pow(px * px + py * py - 0.6, 3.0) - px * px * py * py * py
					if v <= 0.0:
						img.set_pixel(x, 11 - y, c)
			img.set_pixel(3, 4, Color("ffd0d8"))
		"dots":
			for x in [2, 5, 8]:
				img.fill_rect(Rect2i(x, 6, 2, 2), Color("9a9fa8"))
	_emote_tex[kind] = ImageTexture.create_from_image(img)
	return _emote_tex[kind]


## Little puffs of dust under the feet on paths and sand.
func _make_dust() -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.amount = 10
	p.lifetime = 0.6
	p.emitting = false
	p.direction = Vector3(0, 1, 0)
	p.spread = 70.0
	p.initial_velocity_min = 0.3
	p.initial_velocity_max = 0.7
	p.gravity = Vector3(0, -0.6, 0)
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.2
	var q := QuadMesh.new()
	q.size = Vector2(0.09, 0.09)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.vertex_color_use_as_albedo = true
	q.material = mat
	p.mesh = q
	var g := Gradient.new()
	g.set_color(0, Color(0.85, 0.78, 0.62, 0.7))
	g.set_color(1, Color(0.85, 0.78, 0.62, 0.0))
	p.color_ramp = g
	return p


## Now and then someone nearby shows how they feel: a note where the song is
## back, three dots where it is still silent, a heart from Lingshou on the farm.
func _emotes(delta: float) -> void:
	_emote_t -= delta
	if _emote_t > 0.0 or busy:
		return
	_emote_t = _rng.randf_range(3.0, 7.0)
	var near: Array[Actor] = []
	for id in _actors:
		var a: Actor = _actors[id]
		if a == _jinli or not a.visible or a.entry.get("kind", "") != "" or a.entry.has("enter"):
			continue
		if a.position.distance_to(_player.position) < 7.0:
			near.append(a)
	if near.is_empty():
		return
	var who: Actor = near[_rng.randi_range(0, near.size() - 1)]
	emote(who, "dots" if _silent else ("heart" if String(who.actor_id).begins_with("farm_") else "note"))


## A small floating emote over someone (note, heart, dots).
func emote(who: Actor, kind: String) -> void:
	if who == null:
		return
	var l := Sprite3D.new()
	l.texture = _emote_texture(kind)
	l.pixel_size = 1.0 / CameraRig.PIXELS_PER_UNIT
	l.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.shaded = false
	l.render_priority = 2
	var h := who.texture.get_height() / CameraRig.PIXELS_PER_UNIT * who.scale.y if who.texture else 1.0
	l.position = who.position + Vector3(0.2, h + 0.2, 0)
	_map_root.add_child(l)
	var tw := l.create_tween()
	tw.tween_property(l, "position:y", l.position.y + 0.45, 1.6).set_trans(Tween.TRANS_SINE)
	tw.parallel().tween_property(l, "modulate:a", 0.0, 1.6).set_delay(0.6)
	tw.tween_callback(l.queue_free)


func _make_cloud_shadows() -> Decal:
	var d := Decal.new()
	d.size = Vector3(48, 6, 48)
	var noise := FastNoiseLite.new()
	noise.frequency = 0.035
	noise.fractal_octaves = 2
	var img := Image.create(128, 128, false, Image.FORMAT_RGBA8)
	for y in 128:
		for x in 128:
			var n := noise.get_noise_2d(x, y) * 0.5 + 0.5
			var a := clampf((n - 0.55) * 4.0, 0.0, 1.0)
			a = floorf(a * 4.0) / 4.0
			img.set_pixel(x, y, Color(0.08, 0.1, 0.18, a * 0.28))
	var tex := ImageTexture.create_from_image(img)
	d.texture_albedo = tex
	d.upper_fade = 0.1
	d.lower_fade = 0.1
	d.cull_mask = 1
	return d


## Speech bubble over the person or thing the A button would talk to.
func _make_bubble() -> Sprite3D:
	var img := Image.create(14, 12, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	img.fill_rect(Rect2i(1, 0, 12, 8), Color("2a2230"))
	img.fill_rect(Rect2i(0, 1, 14, 6), Color("2a2230"))
	img.fill_rect(Rect2i(2, 1, 10, 6), Color("fff8e8"))
	img.fill_rect(Rect2i(1, 2, 12, 4), Color("fff8e8"))
	img.fill_rect(Rect2i(4, 8, 3, 2), Color("2a2230"))
	img.fill_rect(Rect2i(4, 8, 2, 1), Color("fff8e8"))
	img.fill_rect(Rect2i(4, 10, 1, 1), Color("2a2230"))
	for x in [4, 7, 10]:
		img.fill_rect(Rect2i(x - 1, 3, 2, 2), Color("8e2e23"))
	var b := Sprite3D.new()
	b.texture = ImageTexture.create_from_image(img)
	b.pixel_size = 1.0 / CameraRig.PIXELS_PER_UNIT
	b.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	b.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	b.no_depth_test = true
	b.shaded = false
	b.render_priority = 2
	b.visible = false
	return b


func _talk_target() -> Actor:
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
		if a == _jinli:
			score += 1.5  # people and objects first; Jinli only when nothing else is near
		if score < best_score:
			best_score = score
			best = a
	return best


func _update_bubble() -> void:
	if _bubble == null:
		return
	var t: Actor = null if busy or dialog.is_open() else _talk_target()
	_bubble.visible = t != null and t != _jinli
	if _bubble.visible:
		var h := 1.0 if t.entry.get("kind") == "invisible" else t.texture.get_height() / CameraRig.PIXELS_PER_UNIT * t.scale.y
		_bubble.position = t.position + Vector3(0, h + 0.25 + absf(sin(Time.get_ticks_msec() / 220.0)) * 0.08, 0)


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
		if a == _jinli:
			score += 1.5  # people and objects first; Jinli only when nothing else is near
		if score < best_score:
			best_score = score
			best = a
	if best and best.entry.has("enter"):
		_enter_door(best)
		return
	if best:
		_idle_s = 0.0
		touch.release()
		if best.entry.has("face") or best == _jinli:
			best.flip_h = best.position.x < _player.position.x
		events.run(best.event, best.actor_id)


## Doors lead into rooms (interiors); a little knock and the room fades in.
func _enter_door(door: Actor) -> void:
	if busy:
		return
	touch.release()
	Audio.sfx("select")
	await enter_map(door.entry["enter"], "door")


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
	if has_meta("rebuild_after_menu"):
		remove_meta("rebuild_after_menu")
		await enter_map(map.id, "", Vector2(_player.position.x, _player.position.z))


func update_quest() -> void:
	var q: String = current_quest()
	_hud_quest.text = ("◆ " + tr(q)) if q != "" else ""
	_hud_quest.visible = q != ""


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


## "!" over the hero's head when a battle begins.
func _exclaim() -> void:
	if DialogBox.autopilot:
		return
	var img := Image.create(6, 12, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	img.fill_rect(Rect2i(1, 0, 4, 8), Color("2a2230"))
	img.fill_rect(Rect2i(2, 1, 2, 6), Color("ffd040"))
	img.fill_rect(Rect2i(1, 9, 4, 3), Color("2a2230"))
	img.fill_rect(Rect2i(2, 10, 2, 1), Color("ffd040"))
	var s := Sprite3D.new()
	s.texture = ImageTexture.create_from_image(img)
	s.pixel_size = 1.6 / CameraRig.PIXELS_PER_UNIT
	s.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	s.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	s.no_depth_test = true
	s.shaded = false
	s.position = _player.position + Vector3(0, 1.9, 0)
	_map_root.add_child(s)
	var tw := s.create_tween()
	tw.tween_property(s, "position:y", s.position.y + 0.25, 0.12)
	tw.tween_property(s, "position:y", s.position.y, 0.12)
	await get_tree().create_timer(0.45).timeout
	s.queue_free()


var _wipe_rect: ColorRect


## Diamond wipe in (to_black) or out of a battle.
func _wipe(to_black: bool) -> void:
	if _wipe_rect == null:
		_wipe_rect = ColorRect.new()
		_wipe_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_wipe_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var mat := ShaderMaterial.new()
		mat.shader = load("res://shaders/diamond_wipe.gdshader")
		_wipe_rect.material = mat
		_fade.get_parent().add_child(_wipe_rect)
	_wipe_rect.visible = true
	var mat := _wipe_rect.material as ShaderMaterial
	var tw := create_tween()
	tw.tween_method(func(v): mat.set_shader_parameter("progress", v), 0.0 if to_black else 1.0, 1.0 if to_black else 0.0, 0.45)
	await tw.finished
	if not to_black:
		_wipe_rect.visible = false


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
	if _follower2:
		_follower2.position = _player.position + Vector3(-1.8, 0, 0.7)


func refresh_party_follower() -> void:
	_update_follower()


func _v3(at: Array) -> Vector3:
	return Vector3(float(at[0]), 0, float(at[1]))
