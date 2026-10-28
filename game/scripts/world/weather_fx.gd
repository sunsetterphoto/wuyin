class_name WeatherFx
extends Control
## Screen-space weather over the diorama: rain streaks, snowflakes, blowing
## sand and lightning flashes. Cheap (one _draw call, ~120 particles), works
## the same in both camera modes. Fog itself is the environment's fog.

const COUNT := {"rain": 120, "storm": 160, "snow": 90, "sandstorm": 110}

var kind := ""
var _p: Array[Vector3] = []  # x, y (0..1), speed variation
var _flash := 0.0
var _flash_wait := 4.0
var _rng := RandomNumberGenerator.new()


func _init() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_kind(k: String) -> void:
	if k == kind:
		return
	kind = k
	_p.clear()
	for i in int(COUNT.get(k, 0)):
		_p.append(Vector3(_rng.randf(), _rng.randf(), _rng.randf_range(0.7, 1.3)))
	visible = not _p.is_empty()
	queue_redraw()


func _process(delta: float) -> void:
	if _p.is_empty():
		return
	var fall: float = {"rain": 1.6, "storm": 2.2, "snow": 0.18, "sandstorm": 0.25}.get(kind, 1.0)
	var drift: float = {"rain": 0.1, "storm": 0.35, "snow": 0.05, "sandstorm": 1.4}.get(kind, 0.0)
	for i in _p.size():
		var q := _p[i]
		q.y += fall * q.z * delta
		q.x += drift * q.z * delta + (sin(q.y * 9.0 + i) * 0.02 * delta if kind == "snow" else 0.0)
		if q.y > 1.05 or q.x > 1.05:
			q = Vector3(_rng.randf_range(-0.2, 1.0) if kind == "sandstorm" else _rng.randf(), -0.05 if kind != "sandstorm" else _rng.randf(), q.z)
		_p[i] = q
	if kind == "storm":
		_flash_wait -= delta
		if _flash_wait <= 0.0:
			_flash = 0.5
			_flash_wait = _rng.randf_range(4.0, 9.0)
	_flash = maxf(0.0, _flash - delta * 1.5)
	queue_redraw()


func _draw() -> void:
	var sz := size
	match kind:
		"rain", "storm":
			var c := Color(0.75, 0.82, 0.95, 0.45)
			for q in _p:
				var a := Vector2(q.x * sz.x, q.y * sz.y)
				draw_line(a, a + Vector2(-4, 18) * q.z, c, 2.0)
		"snow":
			for q in _p:
				draw_rect(Rect2(q.x * sz.x, q.y * sz.y, 4 * q.z, 4 * q.z), Color(1, 1, 1, 0.8))
		"sandstorm":
			var c := Color(0.85, 0.7, 0.45, 0.35)
			for q in _p:
				var a := Vector2(q.x * sz.x, q.y * sz.y)
				draw_line(a, a + Vector2(26, 3) * q.z, c, 2.0)
	if _flash > 0.0:
		draw_rect(Rect2(Vector2.ZERO, sz), Color(1, 1, 1, _flash * 0.5))
