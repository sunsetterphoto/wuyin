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
