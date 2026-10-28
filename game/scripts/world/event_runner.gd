class_name EventRunner
extends Node
## Runs scripted events from res://data/events/*.json (rule 4: story is data).
## An event is a list of steps; each step is a dictionary with one command key:
##
##   {"say": "meister", "text": "EV_..."}        line of dialog (speaker id from data/npcs.json)
##   {"choice": ["CH_A", "CH_B"], "then": [[...], [...]]}
##   {"if": "flag", "then": [...], "else": [...]}  also "if_item", "if_party_min", "if_coins"
##   {"set": "flag", "value": v} / {"clear": "flag"} / {"quest": "QUEST_KEY"} / {"goal": [map, x, z]}
##   {"give_item": "id", "n": 2} / {"coins": n} / {"heal": true} / {"bells": n}
##   {"give_lingshou": "species", "level": n}
##   {"befriend": "species", "level": n, "tamed": [...], "fled": [...]}   taming without a battle
##   {"battle": {...}, "win": [...], "lose": [...], "tamed": [...], "freed": [...]}
##   {"warp": "map", "spawn": "name"} / {"music": "id"} / {"sfx": "id"} / {"wait": s}
##   {"fade": "out"|"in"} / {"move": "actor", "to": [x, z], "speed": s} / {"teleport": [x, z]}
##   {"refresh": true} / {"save": true} / {"set_inn": ["map", "spawn"]} / {"silence": bool}
##   {"shop": ["item", ...]} / {"inn": true} / {"rumor": true} / {"hint": true}
##   {"voice": "species", "event": "freed"} / {"end_beta": true} / {"run": "other_event"}

const DIR := "res://data/events/"
const NPCS_PATH := "res://data/npcs.json"
const HINT_MAX_CHARS := 120
const RUMOR_MAX_CHARS := 160

static var _events := {}
static var _npcs := {}

var world: World
var running := false
## Actor that started the current event (for "say": "self").
var _self_id := ""


func _init(w: World = null) -> void:
	world = w


static func has_event(id: String) -> bool:
	_ensure_loaded()
	return _events.has(id)


static func event_ids() -> Array:
	_ensure_loaded()
	return _events.keys()


static func steps_of(id: String) -> Array:
	_ensure_loaded()
	return _events.get(id, [])


static func npc(id: String) -> Dictionary:
	_ensure_loaded()
	return _npcs.get(id, {})


static func _ensure_loaded() -> void:
	if not _events.is_empty():
		return
	for f in DirAccess.get_files_at(DIR):
		if not f.ends_with(".json"):
			continue
		var json := JSON.new()
		if json.parse(FileAccess.get_file_as_string(DIR + f)) != OK:
			push_error("events %s: %s (line %d)" % [f, json.get_error_message(), json.get_error_line()])
			continue
		_events.merge(json.data.get("events", {}))
	var nj := JSON.new()
	if nj.parse(FileAccess.get_file_as_string(NPCS_PATH)) == OK:
		_npcs = nj.data


func run(id: String, self_id := "") -> void:
	if running:
		return
	running = true
	world.busy = true
	world.touch.release()
	_self_id = self_id
	await _run_steps(steps_of(id))
	world.dialog.hide_box()
	world.update_quest()
	running = false
	world.busy = false


func _run_steps(steps: Array) -> void:
	for step in steps:
		await _step(step)
		if step.has("end_beta"):
			return


func _step(s: Dictionary) -> void:
	var st := world.state
	if s.has("say"):
		await say_key(s["say"], s["text"])
	elif s.has("choice"):
		var opts: Array[String] = []
		for k in s["choice"]:
			opts.append(_fmt(tr(k)))
		var picked := await world.dialog.ask(opts)
		var branches: Array = s.get("then", [])
		if picked < branches.size():
			await _run_steps(branches[picked])
	elif s.has("if") or s.has("if_item") or s.has("if_party_min") or s.has("if_coins") or s.has("if_not"):
		var ok := true
		if s.has("if"):
			ok = bool(st.flag(s["if"]))
		if s.has("if_not"):
			ok = ok and not st.flag(s["if_not"])
		if s.has("if_item"):
			ok = ok and st.item_count(s["if_item"]) > 0
		if s.has("if_party_min"):
			ok = ok and st.party.size() >= int(s["if_party_min"])
		if s.has("if_coins"):
			ok = ok and st.coins >= int(s["if_coins"])
		await _run_steps(s.get("then", []) if ok else s.get("else", []))
	elif s.has("set"):
		st.set_flag(s["set"], s.get("value", true))
		world.refresh_people()
	elif s.has("clear"):
		st.flags.erase(s["clear"])
		world.refresh_people()
	elif s.has("quest"):
		st.set_flag("quest", s["quest"])
		st.set_flag("hint_asks", 0)
		world.update_quest()
	elif s.has("goal"):
		st.set_flag("goal", s["goal"])
	elif s.has("give_item"):
		st.give_item(s["give_item"], int(s.get("n", 1)))
		Audio.sfx("coin")
		await say_key("narrator", "MSG_GOT_ITEM", {"item": tr(GameData.item(s["give_item"])["name"]), "n": int(s.get("n", 1))})
	elif s.has("coins"):
		st.coins += int(s["coins"])
		Audio.sfx("coin")
		await say_key("narrator", "MSG_GOT_COINS", {"n": int(s["coins"])})
	elif s.has("heal"):
		st.heal_party()
		Audio.sfx("heal")
	elif s.has("bells"):
		st.bells = maxi(st.bells, int(s["bells"]))
		while st.party.size() < st.bells and not st.farm.is_empty():
			st.move_to_party(0)
		Audio.sfx("bell")
		await say_key("narrator", "MSG_NEW_BELL", {"n": st.bells})
	elif s.has("give_lingshou"):
		var rec := st.add_lingshou(s["give_lingshou"], int(s.get("level", 5)), int(s.get("bond", 25)))
		world.refresh_party_follower()
		Audio.sfx("trust")
		await say_key("narrator", "MSG_JOINED" if st.in_party(rec) else "MSG_TO_FARM",
			{"name": tr(GameData.lingshou(s["give_lingshou"])["name"])})
	elif s.has("battle"):
		var r := await world.battle(s["battle"])
		var key: String = r["outcome"]
		if key == "fled":
			key = "lose"
		if s.has(key):
			await _run_steps(s[key])
		elif key in ["tamed", "freed"] and s.has("win"):
			await _run_steps(s["win"])
	elif s.has("befriend"):
		var r := await world.befriend(s["befriend"], int(s.get("level", 4)))
		if s.has(r["outcome"]):
			await _run_steps(s[r["outcome"]])
	elif s.has("warp"):
		await world.enter_map(s["warp"], s.get("spawn", ""))
	elif s.has("music"):
		Audio.play(s["music"])
	elif s.has("sfx"):
		Audio.sfx(s["sfx"])
	elif s.has("wait"):
		await get_tree().create_timer(float(s["wait"])).timeout
	elif s.has("fade"):
		await world.fade(s["fade"] == "out", float(s.get("seconds", 0.5)))
	elif s.has("move"):
		var a := world.actor(s["move"])
		if a:
			a.visible = true
			a.set_meta("active", true)
			a.walk_to(Vector3(float(s["to"][0]), 0, float(s["to"][1])), float(s.get("speed", 2.5)))
			if s.get("wait_arrival", true):
				await a.arrived
	elif s.has("teleport"):
		world.teleport_player(Vector2(float(s["teleport"][0]), float(s["teleport"][1])))
	elif s.has("place"):
		var a := world.actor(s["place"])
		if a:
			a.position = Vector3(float(s["at"][0]), 0, float(s["at"][1]))
	elif s.has("refresh"):
		world.refresh_people()
	elif s.has("save"):
		st.save_game(World.AUTOSAVE_SLOT)
	elif s.has("set_inn"):
		st.inn = {"map": s["set_inn"][0], "spawn": s["set_inn"][1]}
	elif s.has("silence"):
		world.set_silent(bool(s["silence"]))
	elif s.has("shop"):
		await world.show_ui(ShopMenu.make(s["shop"]))
	elif s.has("inn"):
		await world.show_ui(InnMenu.new())
	elif s.has("rumor"):
		await _rumor(s.get("speaker", _self_id))
	elif s.has("hint"):
		await _hint()
	elif s.has("voice"):
		await _lingshou_voice(s["voice"], s.get("event", "freed"))
	elif s.has("run"):
		await _run_steps(steps_of(s["run"]))
	elif s.has("end_beta"):
		await world.show_ui(EndScreen.new())
	else:
		push_warning("unknown event step: %s" % s)


# --- text --------------------------------------------------------------------

## Speaks a translated line. speaker: npc id, "player", "narrator", "jinli",
## "self" (the actor that started the event) or a Lingshou species id.
func say_key(speaker: String, key: String, args := {}) -> void:
	await say_text(speaker, _fmt(tr(key), args))


func say_text(speaker: String, text: String, report := {}) -> void:
	if speaker == "self":
		speaker = _self_id
	var info := speaker_info(speaker)
	if speaker == "jinli":
		Audio.sfx("meow")
	await world.dialog.say(info["name"], text, info["voice"], report)


func speaker_info(speaker: String) -> Dictionary:
	match speaker:
		"narrator", "":
			return {"name": "", "voice": {}}
		"player":
			return {"name": world.player_name(), "voice": {"tone": "jue", "style": "brave"}}
	if speaker in GameData.lingshou_ids():
		var sp := GameData.lingshou(speaker)
		return {"name": tr(sp["name"]), "voice": {"tone": Babble.ELEMENT_TONE.get(sp["element"], "gong"),
			"style": sp["temperaments"][0]}}
	var n := npc(speaker)
	return {"name": tr(n.get("name", speaker)), "voice": n.get("voice", {"tone": "gong", "style": "gentle"})}


func _fmt(text: String, args := {}) -> String:
	var a := {"player": world.player_name() if world else ""}
	if world and not world.state.party.is_empty():
		a["first"] = tr(GameData.lingshou(world.state.party[0]["species"])["name"])
	a.merge(args, true)
	return text.format(a)


# --- model-written lines (with templates) ---------------------------------------

## Jinli's hint for the current quest: clearer the more often the player asks.
func _hint() -> void:
	var st := world.state
	var quest: String = st.flag("quest", "")
	var asks := int(st.flag("hint_asks", 0))
	st.set_flag("hint_asks", asks + 1)
	if quest == "":
		await say_key("jinli", "HINT_NONE")
		return
	var level := mini(asks, 2)
	var template := _fmt(tr("HINT_%s_%d" % [quest.trim_prefix("QUEST_"), level]))
	var locale := TranslationServer.get_locale()
	var msgs := [
		{"role": "system", "content": "You write the subtitle for Jinli, a small tortoiseshell cat who can hear the stolen tones and shows the player the way. She only meows; the subtitle says what she means, in a few warm words, starting with a meow sound. Family friendly. Never invent places or people that are not in the facts. %s" % LingshouVoice.ANSWER_IN.get(locale, "")},
		{"role": "user", "content": "Current goal: %s\nHint to convey (clarity %d of 3): %s\nWrite one short subtitle (max 18 words). %s" % [
			tr(quest), level + 1, template, LingshouVoice.ANSWER_IN.get(locale, "")]},
	]
	var r := await _model_line("jinli_hint", msgs, HINT_MAX_CHARS, template, "jinli")
	await say_text("jinli", r["text"], r["report"])


func _rumor(speaker: String) -> void:
	var st := world.state
	var facts: Array[String] = []
	for m in ["bambuspfad", "reisterrassen"]:
		if MapData.exists(m):
			var md := MapData.load_map(m)
			var names: Array = []
			for e in md.def.get("encounters", {}).get("table", []):
				names.append(tr(GameData.lingshou(e["species"])["name"]))
			facts.append("%s: %s" % [tr(md.name_key()), ", ".join(names)])
	facts.append("The Azure Dragon in the shrine above the rice terraces has fallen silent.")
	if st.flag("tone_jue"):
		facts.append("The tone Jue has returned; the bamboo sings again.")
	var template := _fmt(tr("RUMOR_%d" % (int(st.flag("rumor_n", 0)) % 3)))
	st.set_flag("rumor_n", int(st.flag("rumor_n", 0)) + 1)
	var locale := TranslationServer.get_locale()
	var msgs := [
		{"role": "system", "content": "You are the tea master of the tea terrace town Teeufer in a family-friendly fantasy game. Tell the traveller one short rumour (one or two sentences, max 30 words) using only these facts. Do not invent new places. %s" % LingshouVoice.ANSWER_IN.get(locale, "")},
		{"role": "user", "content": "Facts:\n- %s\nTell a rumour. %s" % ["\n- ".join(facts), LingshouVoice.ANSWER_IN.get(locale, "")]},
	]
	var r := await _model_line("rumor", msgs, RUMOR_MAX_CHARS, template, speaker)
	await say_text(speaker, r["text"], r["report"])


func _lingshou_voice(species: String, event: String) -> void:
	var u := BattleUnit.create(species, 10)
	var r := await LingshouVoice.comment(u, event if event in LingshouVoice.EVENTS else "win", {"call": "", "target": ""})
	var text: String = r["text"]
	if r["source"] == "template":
		text = _fmt(tr("VOICE_%s_%s" % [species.to_upper(), event.to_upper()]))
	await say_text(species, text, {"role": "lingshou_voice", "species": species} if r["source"] == "model" else {})


## Streams a model line into the dialog box; falls back to the template.
## Returns {"text", "report"} (report is empty for templates).
func _model_line(role: String, msgs: Array, max_chars: int, template: String, speaker: String) -> Dictionary:
	var service := LlmService.instance()
	if not service.is_model_available():
		return {"text": template, "report": {}}
	var info := speaker_info(speaker)
	world.dialog.say(info["name"], "…", info["voice"])
	var job := service.ask(role, msgs)
	job.token.connect(func(_t): world.dialog.update_text(TextGuard.limit(job.text.strip_edges(), max_chars)))
	var r := await job.wait()
	world.dialog.advanced.emit()  # close the streaming line; the final one is shown by the caller
	var text := TextGuard.clean(r["text"], TranslationServer.get_locale(), max_chars) if r["ok"] else ""
	PlaytestLog.record("model_line", {"role": role, "ok": text != "", "ms": r["total_ms"]})
	if text == "":
		return {"text": template, "report": {}}
	return {"text": text, "report": {"role": role}}
