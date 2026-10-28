class_name Actor
extends Sprite3D
## A character or Lingshou standing in the overworld: billboard sprite with a
## small walking bob, mirrored by walking direction, plus scripted movement.

signal arrived

const BOB_HZ := 7.0
const BOB_PX := 1.5

var actor_id := ""
## Event run when the player talks to this actor ("" = not interactive).
var event := ""
var entry: Dictionary = {}
var moving := false
var _walk_t := 0.0
var _base_offset := Vector2.ZERO
var _target := Vector3.ZERO
var _speed := 3.0
var _path: Array[Vector3] = []
## Optional views for walking up (back) and sideways (side, drawn facing left).
## Gentle breathing while standing (scale at the feet); off for the player.
var breathe := true
var _base_scale := Vector3.ONE
var _breath_phase := 0.0
var _shadow: MeshInstance3D
var _front: Texture2D
var _back: Texture2D
var _side: Texture2D


static func make(tex: Texture2D, pos: Vector3, id := "") -> Actor:
	var a := Actor.new()
	a.actor_id = id
	a.texture = tex
	a.pixel_size = 1.0 / CameraRig.PIXELS_PER_UNIT
	a.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	a.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	a.shaded = true
	a.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	a.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	a._base_offset = Vector2(0, tex.get_height() / 2.0)  # feet on the ground
	a.offset = a._base_offset
	a.position = pos
	a._breath_phase = randf() * TAU
	a._add_shadow(tex.get_width() / CameraRig.PIXELS_PER_UNIT)
	return a


## Soft contact shadow on the ground under the sprite.
func _add_shadow(width: float) -> void:
	_shadow = MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(clampf(width * 0.8, 0.5, 2.6), clampf(width * 0.45, 0.3, 1.4))
	plane.material = Materials.blob_shadow()
	_shadow.mesh = plane
	_shadow.position = Vector3(0, 0.015, 0.02)
	_shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_shadow)


func _ready() -> void:
	_base_scale = scale


## Faint silhouette drawn over everything, so the actor stays visible behind trees and roofs.
func add_silhouette() -> void:
	var s := Sprite3D.new()
	s.texture = texture
	s.pixel_size = pixel_size
	s.texture_filter = texture_filter
	s.billboard = billboard
	s.offset = offset
	s.no_depth_test = true
	s.shaded = false
	s.modulate = Color(0.75, 0.85, 1.0, 0.35)
	s.render_priority = -1
	s.name = "Silhouette"
	add_child(s)


func set_directions(back: Texture2D, side: Texture2D) -> void:
	_front = texture
	_back = back
	_side = side


func _face(dir_x: float, dir_z: float) -> void:
	if _front == null:
		if dir_x != 0.0:
			flip_h = dir_x > 0.0
		return
	var tex := _front
	if absf(dir_x) > absf(dir_z) * 1.2 and _side:
		tex = _side
		flip_h = dir_x > 0.0
	elif dir_z < -0.1 and _back:
		tex = _back
		flip_h = false
	else:
		flip_h = dir_x > 0.0 if absf(dir_x) > 0.1 else flip_h
	if tex != texture:
		texture = tex
		var sil := get_node_or_null("Silhouette") as Sprite3D
		if sil:
			sil.texture = tex


func set_texture_keep_feet(tex: Texture2D) -> void:
	texture = tex
	_base_offset = Vector2(0, tex.get_height() / 2.0)
	offset = _base_offset


## Walks in a straight line (scripted scenes); await `arrived`.
func walk_to(pos: Vector3, speed := 3.0) -> void:
	_path = [pos]
	_speed = speed
	moving = true


## Walks along tile centres (Jinli, NPCs).
func walk_path(points: Array[Vector3], speed := 3.0) -> void:
	_path = points.duplicate()
	_speed = speed
	moving = not _path.is_empty()


func stop() -> void:
	_path.clear()
	moving = false


## Called by the world each frame with the actor's own movement (player) or none.
func animate(delta: float, walking: bool, dir_x := 0.0, dir_z := 0.0) -> void:
	if dir_x != 0.0 or dir_z != 0.0:
		_face(dir_x, dir_z)
	if walking:
		_walk_t += delta
		var bob := absf(sin(_walk_t * BOB_HZ))
		offset = _base_offset + Vector2(0, bob * BOB_PX)
		# A little squash and stretch with every step: a happy waddle.
		scale = Vector3(_base_scale.x * (1.0 + (1.0 - bob) * 0.05), _base_scale.y * (1.0 - (1.0 - bob) * 0.05 + bob * 0.03), _base_scale.z)
	else:
		if _walk_t > 0.0:
			scale = _base_scale
		_walk_t = 0.0
		offset = _base_offset
	var sil := get_node_or_null("Silhouette") as Sprite3D
	if sil:
		sil.offset = offset
		sil.flip_h = flip_h
		sil.billboard = billboard


func _process(delta: float) -> void:
	if not moving:
		if breathe and visible:
			var b := sin(Time.get_ticks_msec() / 1000.0 * 2.2 + _breath_phase)
			scale = Vector3(_base_scale.x * (1.0 - b * 0.012), _base_scale.y * (1.0 + b * 0.018), _base_scale.z)
		return
	if _path.is_empty():
		moving = false
		animate(delta, false)
		arrived.emit()
		return
	var goal := _path[0]
	var to := goal - position
	to.y = 0.0
	var step := _speed * delta
	if to.length() <= step:
		position = Vector3(goal.x, position.y, goal.z)
		_path.pop_front()
	else:
		position += to.normalized() * step
	animate(delta, true, to.x, to.z)
