extends CanvasLayer
## Debug builds only: after a while without input the screen goes fully black
## (OLED pixels off) so a test phone left on the desk can't burn in. Any touch,
## key or a running benchmark (hold) wakes it.

const IDLE_SECONDS := 90.0

var _idle := 0.0
var _black: ColorRect
var _holds := 0


func _ready() -> void:
	layer = 128
	process_mode = Node.PROCESS_MODE_ALWAYS
	_black = ColorRect.new()
	_black.color = Color.BLACK
	_black.set_anchors_preset(Control.PRESET_FULL_RECT)
	_black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_black.visible = false
	add_child(_black)
	set_process(OS.is_debug_build())


## Automated runs (benchmarks, evals) keep the screen awake while they hold.
func hold(on: bool) -> void:
	_holds = maxi(0, _holds + (1 if on else -1))
	_wake()


func _process(delta: float) -> void:
	if _holds > 0:
		_idle = 0.0
		return
	_idle += delta
	if _idle >= IDLE_SECONDS and not _black.visible:
		_black.visible = true
		Engine.max_fps = 5  # nothing to draw, save heat and battery


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch or event is InputEventMouseButton or event is InputEventKey:
		if _black.visible:
			get_viewport().set_input_as_handled()  # the waking touch should not press a button
		_wake()


func _wake() -> void:
	_idle = 0.0
	if _black.visible:
		_black.visible = false
		Engine.max_fps = 0
