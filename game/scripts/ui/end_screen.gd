class_name EndScreen
extends MenuScreen
## End of the beta: thanks, a short summary of the run, and the rating sheet.


func _ready() -> void:
	title_label.text = tr("END_TITLE")
	var s := GameState.current
	body.add_child(UiTheme.label(tr("END_TEXT"), 22))
	body.add_child(UiTheme.label(tr("END_STATS").format({"time": GameMenu._time(s.play_seconds),
		"battles": s.stats["battles"], "tamed": s.stats["tamed"], "freed": s.stats["freed"],
		"calls": s.stats["calls"], "party": s.party.size() + s.farm.size()}), 20, UiTheme.MUTED))
	var b := UiTheme.button(tr("END_RATE"), _rate)
	body.add_child(b)
	b.grab_focus.call_deferred()
	body.add_child(UiTheme.button(tr("END_CONTINUE"), close))
	PlaytestLog.record("beta_end", {"minutes": roundi(s.play_seconds / 60.0), "stats": s.stats})


func _rate() -> void:
	var f := FeedbackForm.new()
	f.context = "beta_end"
	add_child(f)
	await f.closed
	f.queue_free()
