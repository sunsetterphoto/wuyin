class_name Inputs
extends RefCounted
## Input actions for keyboard and controller, added at runtime so the
## project file stays readable. Touch has its own controls (TouchControls).

const ACTIONS := {
	"move_left": [KEY_LEFT, KEY_A, JOY_BUTTON_DPAD_LEFT],
	"move_right": [KEY_RIGHT, KEY_D, JOY_BUTTON_DPAD_RIGHT],
	"move_up": [KEY_UP, KEY_W, JOY_BUTTON_DPAD_UP],
	"move_down": [KEY_DOWN, KEY_S, JOY_BUTTON_DPAD_DOWN],
	"interact": [KEY_SPACE, KEY_ENTER, KEY_E, JOY_BUTTON_A],
	"menu": [KEY_ESCAPE, KEY_M, KEY_TAB, JOY_BUTTON_START],
}
const AXES := {"move_left": [JOY_AXIS_LEFT_X, -1.0], "move_right": [JOY_AXIS_LEFT_X, 1.0],
	"move_up": [JOY_AXIS_LEFT_Y, -1.0], "move_down": [JOY_AXIS_LEFT_Y, 1.0]}


static func ensure() -> void:
	for action in ACTIONS:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action, 0.25)
		for code in ACTIONS[action]:
			var ev: InputEvent
			if code < 32:  # joypad buttons are small numbers, key codes start at 32
				ev = InputEventJoypadButton.new()
				ev.button_index = code
			else:
				ev = InputEventKey.new()
				ev.physical_keycode = code
			InputMap.action_add_event(action, ev)
		if AXES.has(action):
			var m := InputEventJoypadMotion.new()
			m.axis = AXES[action][0]
			m.axis_value = AXES[action][1]
			InputMap.action_add_event(action, m)
