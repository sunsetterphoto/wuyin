class_name DialogBox
extends Control
## Bottom text box for conversations: speaker name, typewriter text with
## babble blips, tap (or A) to continue, optional choices. Model-written
## lines get a small report button (Google Play rule for AI content).

signal advanced
signal chosen(index: int)

var _panel: PanelContainer
var _name: Label
var _text: RichTextLabel
var _choices: VBoxContainer
var _report: Button
var _hint: Label
var _babble: Babble
var _typing := false
var _waiting := false
var _shown_chars := 0.0
var _report_data := {}


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	theme = UiTheme.get_theme()
	_babble = Babble.new()
	add_child(_babble)
	_panel = PanelContainer.new()
	_panel.add_theme_stylebox_override("panel", UiTheme.panel(0.94))
	_panel.set_anchor(SIDE_LEFT, 0.08, true)
	_panel.set_anchor(SIDE_RIGHT, 0.92, true)
	_panel.set_anchor(SIDE_TOP, 1.0, true)
	_panel.set_anchor(SIDE_BOTTOM, 1.0, true)
	_panel.offset_top = -230
	_panel.offset_bottom = -20
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_panel.gui_input.connect(_on_panel_input)
	add_child(_panel)
	var v := VBoxContainer.new()
	_panel.add_child(v)
	var top := HBoxContainer.new()
	v.add_child(top)
	_name = UiTheme.label("", 24, UiTheme.GOLD)
	_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(_name)
	_report = Button.new()
	_report.text = "⚑ " + tr("UI_REPORT")
	_report.flat = true
	_report.add_theme_font_size_override("font_size", 16)
	_report.add_theme_color_override("font_color", UiTheme.MUTED)
	_report.pressed.connect(_on_report)
	top.add_child(_report)
	_text = RichTextLabel.new()
	_text.bbcode_enabled = true
	_text.fit_content = true
	_text.scroll_active = false
	_text.custom_minimum_size = Vector2(0, 120)
	_text.mouse_filter = Control.MOUSE_FILTER_PASS
	_text.add_theme_font_size_override("normal_font_size", 26)
	v.add_child(_text)
	_hint = UiTheme.label("▼", 18, UiTheme.GOLD)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	v.add_child(_hint)
	_choices = VBoxContainer.new()
	_choices.set_anchor(SIDE_LEFT, 0.55, true)
	_choices.set_anchor(SIDE_RIGHT, 0.92, true)
	_choices.set_anchor(SIDE_TOP, 1.0, true)
	_choices.set_anchor(SIDE_BOTTOM, 1.0, true)
	_choices.offset_bottom = -250
	_choices.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_choices.alignment = BoxContainer.ALIGNMENT_END
	_choices.add_theme_constant_override("separation", 8)
	add_child(_choices)
	hide_box()


func hide_box() -> void:
	_panel.visible = false
	_choices.visible = false


func is_open() -> bool:
	return _panel.visible


## Shows a line and waits until the player taps on. voice: {"tone", "style", "octave"} or {}.
## report: context for the report button when the text came from the model ({} = hidden).
func say(speaker: String, text: String, voice := {}, report := {}) -> void:
	_panel.visible = true
	_choices.visible = false
	_name.text = speaker
	_name.visible = speaker != ""
	_text.text = text
	_report_data = report
	_report.visible = not report.is_empty()
	_report.disabled = false
	if voice.is_empty():
		_babble.set_voice("gong", "gentle", 0)
		_babble.process_mode = Node.PROCESS_MODE_DISABLED
	else:
		_babble.process_mode = Node.PROCESS_MODE_INHERIT
		_babble.set_voice(voice.get("tone", "gong"), voice.get("style", "gentle"), int(voice.get("octave", 0)))
	var cps := Settings.chars_per_second()
	_shown_chars = 0.0
	_text.visible_characters = 0 if cps > 0.0 else -1
	_typing = cps > 0.0
	_hint.modulate.a = 0.0
	_waiting = true
	await advanced
	_waiting = false


## Replaces the text of the current line while it streams in (model output).
func update_text(text: String) -> void:
	_text.text = text


func ask(options: Array[String]) -> int:
	_choices.visible = true
	for c in _choices.get_children():
		c.queue_free()
	for i in options.size():
		var b := UiTheme.button(options[i], func(): chosen.emit(i))
		_choices.add_child(b)
		if i == 0:
			b.grab_focus.call_deferred()
	var picked: int = await chosen
	_choices.visible = false
	return picked


func _process(delta: float) -> void:
	if not _panel.visible:
		return
	if _typing:
		var before := int(_shown_chars)
		_shown_chars += delta * Settings.chars_per_second()
		var total := _text.get_total_character_count()
		_text.visible_characters = mini(int(_shown_chars), total)
		var parsed := _text.get_parsed_text()
		if _babble.process_mode != Node.PROCESS_MODE_DISABLED and int(_shown_chars) > before:
			_babble.feed(parsed.substr(before, int(_shown_chars) - before))
		if _shown_chars >= total:
			_typing = false
			_text.visible_characters = -1
	_hint.modulate.a = 0.0 if _typing or _choices.visible else 0.5 + 0.5 * sin(Time.get_ticks_msec() / 200.0)


func _unhandled_input(event: InputEvent) -> void:
	if _panel.visible and not _choices.visible and (event.is_action_pressed("ui_accept") or event.is_action_pressed("interact")):
		get_viewport().set_input_as_handled()
		_continue()


func _on_panel_input(event: InputEvent) -> void:
	if (event is InputEventMouseButton and event.pressed) or (event is InputEventScreenTouch and event.pressed):
		if not _choices.visible:
			accept_event()
			_continue()


func _continue() -> void:
	if _typing:
		_typing = false
		_text.visible_characters = -1
		return
	if _waiting:
		advanced.emit()


func _on_report() -> void:
	Feedback.report(_report_data.merged({"text": _text.get_parsed_text(), "speaker": _name.text}))
	_report.disabled = true
	_report.text = "⚑ " + tr("UI_REPORTED")
