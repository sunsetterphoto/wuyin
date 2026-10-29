class_name EndScreen
extends MenuScreen
## The end: after the phoenix's rebirth the ending's name, the epilogue (what
## became of Yao, the Order, the farm, Master Lu), the journey in numbers and
## the rating sheet. "beta" is the old end of chapter 1 (kept for old saves).

var kind := "final"


static func make(end_kind: String) -> EndScreen:
	var e := EndScreen.new()
	e.kind = end_kind
	return e


func _ready() -> void:
	var s := GameState.current
	if kind == "beta":
		title_label.text = tr("END_TITLE")
		body.add_child(UiTheme.para(tr("END_TEXT"), 22))
	else:
		var ending: String = s.flag("ending", "victory")
		title_label.text = tr("ENDING_TITLE_" + ending.to_upper())
		# The reborn phoenix, Jinli and the first companion in a little row.
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 24)
		body.add_child(row)
		var pics: Array[Texture2D] = [Sprites.character("jinli"), Sprites.lingshou("fenghuang")]
		if not s.party.is_empty():
			pics.append(Sprites.lingshou_rec(s.party[0]))
		for tex in pics:
			var tr_ := TextureRect.new()
			tr_.texture = tex
			tr_.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			tr_.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tr_.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tr_.custom_minimum_size = Vector2(150, 150) if tex != pics[1] else Vector2(230, 230)
			row.add_child(tr_)
			var tw := tr_.create_tween().set_loops()
			tw.tween_property(tr_, "position:y", -6.0, 0.9 + randf() * 0.4).as_relative().set_trans(Tween.TRANS_SINE)
			tw.tween_property(tr_, "position:y", 6.0, 0.9).as_relative().set_trans(Tween.TRANS_SINE)
		var petals := CPUParticles2D.new()
		petals.amount = 40
		petals.lifetime = 10.0
		petals.preprocess = 10.0
		petals.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
		petals.emission_rect_extents = Vector2(900, 40)
		petals.position = Vector2(780, -30)
		petals.direction = Vector2(0.3, 1)
		petals.initial_velocity_min = 40.0
		petals.initial_velocity_max = 80.0
		petals.angular_velocity_min = -90.0
		petals.angular_velocity_max = 90.0
		petals.scale_amount_min = 4.0
		petals.scale_amount_max = 7.0
		petals.color = Color("ffd070")
		petals.hue_variation_min = -0.1
		petals.hue_variation_max = 0.1
		add_child(petals)
		body.add_child(UiTheme.para(tr("ENDING_TEXT_" + ending.to_upper()), 22))
		for key in Endings.epilogue(s):
			body.add_child(UiTheme.para("· " + tr(key).format({"player": s.player["name"]}), 19, UiTheme.MUTED))
		body.add_child(UiTheme.label(tr("CREDITS_TITLE"), 24, UiTheme.GOLD))
		body.add_child(UiTheme.para(tr("CREDITS_TEXT"), 17, UiTheme.MUTED))
	body.add_child(UiTheme.para(tr("END_STATS").format({"time": GameMenu._time(s.play_seconds),
		"battles": s.stats["battles"], "tamed": s.stats["tamed"], "freed": s.stats["freed"],
		"calls": s.stats["calls"], "party": s.party.size() + s.farm.size()}), 20, UiTheme.MUTED))
	var b := UiTheme.button(tr("END_RATE"), _rate)
	body.add_child(b)
	b.grab_focus.call_deferred()
	body.add_child(UiTheme.button(tr("END_CONTINUE"), close))
	PlaytestLog.record("game_end" if kind == "final" else "beta_end", {"minutes": roundi(s.play_seconds / 60.0), "stats": s.stats,
		"ending": s.flag("ending", "")})
	if kind == "final":
		Audio.play("ending")


func _rate() -> void:
	var f := FeedbackForm.new()
	f.context = "game_end" if kind == "final" else "beta_end"
	add_child(f)
	await f.closed
	f.queue_free()
