class_name CameraRig
extends Node3D
## Camera for both looks (GDD "Grafik"): HD-2D = tilted perspective with
## tilt-shift blur; classic 2D = orthographic 3/4 view, snapped to the texel
## grid. Switching tweens a dolly zoom (fov shrinks while the camera backs off),
## so the change itself becomes a small effect.

signal mode_changed(mode: String)

const HD2D := "hd2d"
const CLASSIC := "classic"
const PIXELS_PER_UNIT := 32.0

## Visible world height (units) and pitch per mode.
const HD2D_VIEW_HEIGHT := 9.0
const HD2D_PITCH := 38.0
const HD2D_FOV := 30.0
const CLASSIC_PITCH := 60.0
const MIN_FOV := 1.0
const TRANSITION_S := 0.6

var mode := HD2D
var target: Node3D
## Visible height in classic mode (set from the low-res viewport height).
var classic_view_height := 360.0 / PIXELS_PER_UNIT
var blur_amount := 0.08

var camera: Camera3D
var attributes: CameraAttributesPractical
var _t := 0.0  # 0 = HD-2D, 1 = classic
var _tween: Tween


func _ready() -> void:
	camera = Camera3D.new()
	camera.current = true
	camera.near = 0.1
	camera.far = 200.0
	attributes = CameraAttributesPractical.new()
	attributes.dof_blur_far_enabled = true
	attributes.dof_blur_near_enabled = true
	camera.attributes = attributes
	add_child(camera)
	_apply(_t)


func set_mode(new_mode: String, animate := true) -> void:
	if new_mode == mode and not animate:
		return
	mode = new_mode
	var goal := 1.0 if mode == CLASSIC else 0.0
	if _tween:
		_tween.kill()
	if not animate:
		_t = goal
		_apply(_t)
		mode_changed.emit(mode)
		return
	_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tween.tween_method(func(v): _t = v; _apply(v), _t, goal, TRANSITION_S)
	_tween.finished.connect(func(): mode_changed.emit(mode))


func set_blur(amount: float) -> void:
	blur_amount = amount
	_apply(_t)


func _process(_delta: float) -> void:
	_apply(_t)


func _apply(t: float) -> void:
	if camera == null:
		return
	var focus := target.global_position if target else Vector3.ZERO
	var pitch := deg_to_rad(lerpf(HD2D_PITCH, CLASSIC_PITCH, t))
	var view_h := lerpf(HD2D_VIEW_HEIGHT, classic_view_height, t)
	if t >= 0.999:
		# Classic: orthographic, camera snapped to whole texels so pixels don't shimmer.
		camera.projection = Camera3D.PROJECTION_ORTHOGONAL
		camera.size = view_h
		var snap := 1.0 / PIXELS_PER_UNIT
		focus = Vector3(snappedf(focus.x, snap), focus.y, snappedf(focus.z, snap))
		_place(focus, pitch, 40.0)
	else:
		camera.projection = Camera3D.PROJECTION_PERSPECTIVE
		# Dolly zoom: keep the visible height while narrowing the fov.
		var fov := lerpf(HD2D_FOV, MIN_FOV, ease(t, 2.4))
		camera.fov = fov
		var dist := view_h / (2.0 * tan(deg_to_rad(fov) / 2.0))
		_place(focus, pitch, dist)
	# Tilt-shift: sharp band around the focus, fades out towards classic.
	var dist_to_focus := camera.global_position.distance_to(focus)
	attributes.dof_blur_amount = blur_amount * (1.0 - t)
	attributes.dof_blur_far_enabled = blur_amount > 0.0 and t < 0.999
	attributes.dof_blur_near_enabled = attributes.dof_blur_far_enabled
	attributes.dof_blur_far_distance = dist_to_focus + 3.0
	attributes.dof_blur_far_transition = 6.0
	attributes.dof_blur_near_distance = maxf(0.5, dist_to_focus - 3.0)
	attributes.dof_blur_near_transition = 3.0


func _place(focus: Vector3, pitch: float, dist: float) -> void:
	var offset := Vector3(0, sin(pitch), cos(pitch)) * dist
	camera.global_position = focus + offset
	camera.look_at(focus, Vector3.UP)


## 0 = HD-2D, 1 = classic; for the scene to fade lighting and effects along.
func blend() -> float:
	return _t
