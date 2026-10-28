class_name FeedbackForm
extends MenuScreen
## Rating sheet for the beta: 1-5 stars per area plus a free comment.
## Stored on the device (Feedback.submit), pulled later via adb.

var context := "menu"
var _ratings := {}
var _rows := {}
var _text: TextEdit


func _ready() -> void:
	title_label.text = tr("FB_TITLE")
	body.add_child(UiTheme.label(tr("FB_INTRO"), 19, UiTheme.MUTED))
	for area in Feedback.AREAS:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		var l := UiTheme.label(tr("FB_" + area.to_upper()), 21)
		l.custom_minimum_size = Vector2(300, 0)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.add_child(l)
		var stars: Array[Button] = []
		for n in range(1, 6):
			var b := UiTheme.button("☆", func(): _rate(area, n), 64)
			b.add_theme_font_size_override("font_size", 28)
			row.add_child(b)
			stars.append(b)
		_rows[area] = stars
		body.add_child(row)
	body.add_child(UiTheme.label(tr("FB_COMMENT"), 21))
	_text = TextEdit.new()
	_text.custom_minimum_size = Vector2(0, 160)
	_text.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	_text.placeholder_text = tr("FB_COMMENT_PLACEHOLDER")
	body.add_child(_text)
	body.add_child(UiTheme.button(tr("FB_SEND"), _send))


func _rate(area: String, n: int) -> void:
	_ratings[area] = n
	var stars: Array = _rows[area]
	for i in stars.size():
		stars[i].text = "★" if i < n else "☆"
		stars[i].add_theme_color_override("font_color", UiTheme.GOLD if i < n else UiTheme.TEXT)


func _send() -> void:
	Feedback.submit(_ratings, _text.text.strip_edges(), context)
	Audio.sfx("bell")
	clear_body()
	body.add_child(UiTheme.label(tr("FB_THANKS"), 26, UiTheme.JADE))
	body.add_child(UiTheme.button(tr("UI_CONTINUE"), close))
