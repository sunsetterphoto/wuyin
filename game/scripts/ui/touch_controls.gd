class_name TouchControls
extends Control
## Overworld touch input: a floating stick on the left half (appears where the
## thumb lands), an action button and a menu button on the right. Keyboard and
## controller go through the input map in parallel (see Inputs).

signal interact
signal menu

const STICK_RADIUS := 90.0
const DEAD_ZONE := 0.18

var direction := Vector2.ZERO
var _stick_index := -1
var _stick_origin := Vector2.ZERO
var _stick_pos := Vector2.ZERO
var _a_button: Button
var _menu_button: Button


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_PASS
	_a_button = _round_button("A", Vector2(-170, -190), 128)
	_a_button.pressed.connect(func(): interact.emit())
	_menu_button = _round_button("☰", Vector2(-120, 24), 84, true)
	_menu_button.pressed.connect(func(): menu.emit())


func _round_button(text: String, offset: Vector2, size: int, top := false) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 40 if size > 100 else 30)
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.1, 0.08, 0.13, 0.55)
	s.border_color = Color(UiTheme.GOLD, 0.8)
	s.set_border_width_all(3)
	s.set_corner_radius_all(size / 2)
	b.add_theme_stylebox_override("normal", s)
	var p := s.duplicate()
	p.bg_color = Color(0.3, 0.24, 0.12, 0.7)
	b.add_theme_stylebox_override("pressed", p)
	b.add_theme_stylebox_override("hover", s)
	b.size = Vector2(size, size)
	b.set_anchor(SIDE_LEFT, 1.0, true)
	b.set_anchor(SIDE_RIGHT, 1.0, true)
	b.set_anchor(SIDE_TOP, 0.0 if top else 1.0, true)
	b.set_anchor(SIDE_BOTTOM, b.anchor_top, true)
	b.position = Vector2.ZERO
	b.offset_left = offset.x
	b.offset_top = offset.y
	b.offset_right = offset.x + size
	b.offset_bottom = offset.y + size
	add_child(b)
	return b


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and _stick_index < 0 and event.position.x < size.x * 0.55:
			_stick_index = event.index
			_stick_origin = event.position
			_stick_pos = event.position
			accept_event()
		elif not event.pressed and event.index == _stick_index:
			_stick_index = -1
			direction = Vector2.ZERO
		queue_redraw()
	elif event is InputEventScreenDrag and event.index == _stick_index:
		_stick_pos = event.position
		var v := (_stick_pos - _stick_origin) / STICK_RADIUS
		if v.length() > 1.0:
			v = v.normalized()
		direction = v if v.length() > DEAD_ZONE else Vector2.ZERO
		accept_event()
		queue_redraw()


func release() -> void:
	_stick_index = -1
	direction = Vector2.ZERO
	queue_redraw()


func _draw() -> void:
	if _stick_index < 0:
		return
	draw_circle(_stick_origin, STICK_RADIUS, Color(1, 1, 1, 0.08))
	draw_arc(_stick_origin, STICK_RADIUS, 0, TAU, 48, Color(UiTheme.GOLD, 0.5), 3.0)
	var knob := _stick_origin + (_stick_pos - _stick_origin).limit_length(STICK_RADIUS)
	draw_circle(knob, 38, Color(UiTheme.GOLD, 0.45))
