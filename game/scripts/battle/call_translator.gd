class_name CallTranslator
extends RefCounted
## Turns a free-text call ("Bambär, schütz Glutfasan!") into a battle action.
## The model proposes {action, target, stance, fits_situation}; the validator
## only lets through actions the unit can do right now; without a model (or on
## timeout / invalid output) a keyword matcher produces the action instead.
##
##   var ctx := CallTranslator.context(battle, 0, slot)
##   var res := await CallTranslator.translate(ctx, "Greif den Leoparden an!")
##   battle.submit(0, slot, res["action"])   # always a valid action

const KEYWORDS_PATH := "res://data/llm/call_keywords.json"
const STANCES: Array[String] = ["offensive", "defensive", "protective"]
const LOCALES: Array[String] = ["en", "de", "zh_Hans"]

static var _keywords: Dictionary = {}


## Everything the translator may refer to, from the battle state (facts, not memory).
static func context(battle: Battle, side: int, slot: int) -> Dictionary:
	var u := battle.unit_at(side, slot)
	var targets := {}  # target id -> {"side", "slot", "unit"}
	targets["self"] = {"side": side, "slot": slot, "unit": u}
	for s in battle.sides[side]["active"].size():
		var a := battle.unit_at(side, s)
		if s != slot and a.is_alive():
			targets["partner"] = {"side": side, "slot": s, "unit": a}
	for s in battle.sides[1 - side]["active"].size():
		var e := battle.unit_at(1 - side, s)
		if e.is_alive():
			targets["enemy:%d" % s] = {"side": 1 - side, "slot": s, "unit": e}
	var actions: Array[String] = []
	for mid in u.usable_moves():
		actions.append("move:" + mid)
	return {"battle": battle, "side": side, "slot": slot, "unit": u, "targets": targets, "actions": actions}


static func schema(ctx: Dictionary) -> Dictionary:
	return {
		"type": "object",
		"properties": {
			"action": {"enum": ctx["actions"]},
			"target": {"enum": ctx["targets"].keys()},
			"stance": {"enum": STANCES},
			"fits_situation": {"type": "boolean"},
		},
		"required": ["action", "target", "stance", "fits_situation"],
	}


## GBNF grammar: compact one-line JSON with exactly the allowed values. Keeps
## the output short (about 30 tokens) and makes invalid actions impossible.
static func grammar(ctx: Dictionary) -> String:
	var alt := func(values: Array) -> String:
		return " | ".join(values.map(func(v): return "\"\\\"%s\\\"\"" % v))
	return "\n".join([
		'root ::= "{\\"action\\":" action ",\\"target\\":" target ",\\"stance\\":" stance ",\\"fits_situation\\":" bool "}"',
		"action ::= " + alt.call(ctx["actions"]),
		"target ::= " + alt.call(ctx["targets"].keys()),
		"stance ::= " + alt.call(STANCES),
		'bool ::= "true" | "false"',
	])


static func messages(ctx: Dictionary, call_text: String) -> Array:
	var u: BattleUnit = ctx["unit"]
	var lines: Array[String] = []
	# Static rules first so the runtime can reuse its prompt cache across calls.
	lines.append("You translate a player's battle call for their spirit animal into JSON. The call may be German, English or Chinese.")
	lines.append("Pick the action that best matches the call. Attacks target an enemy. Heal and guard target self or partner.")
	lines.append("If the call asks to protect, cover, shield or stand in front of the partner, use a guard action with target partner. If it asks to heal or help the partner, heal with target partner.")
	lines.append("Players may name a spirit by its name or by its animal (e.g. pangolin, fire bird). If the call names nobody, attacks go to the enemy the player most likely means.")
	lines.append("stance: offensive (attack), defensive (hold back, endure), protective (shield someone).")
	lines.append("fits_situation: true only if the call is clever for the current battle facts (e.g. uses a type advantage, protects a hurt ally).")
	lines.append("Phases: wood beats earth, earth beats water, water beats fire, fire beats metal, metal beats wood.")
	lines.append("")
	lines.append("Your spirit: %s (%s), %s, temperament %s, HP %d/%d." % [_names(u.name_key()), _names(u.species["animal"]), u.element(),
		", ".join(u.species.get("temperaments", [])), u.hp, u.max_hp])
	for tid in ctx["targets"]:
		if tid == "self":
			continue
		var t: BattleUnit = ctx["targets"][tid]["unit"]
		lines.append("%s = %s (%s), %s, HP %d/%d%s" % [tid, _names(t.name_key()), _names(t.species["animal"]), t.element(), t.hp, t.max_hp,
			(", " + ", ".join(t.statuses.keys())) if not t.statuses.is_empty() else ""])
	lines.append("Actions:")
	for a in ctx["actions"]:
		var mv := GameData.move(a.substr(5))
		lines.append("- %s = %s: %s %s; %s" % [a, _names(mv["name"]), mv["element"], mv["kind"], mv.get("llm_hint", "")])
	return [
		{"role": "system", "content": "\n".join(lines)},
		{"role": "user", "content": call_text},
	]


## Full pipeline: model if available, else keywords. Always returns a valid action.
## {"action": Dictionary, "source": "model"|"template", "reason": String, "raw": String, "ms": int}
static func translate(ctx: Dictionary, call_text: String, service: LlmService = null) -> Dictionary:
	service = service if service else LlmService.instance()
	var job := service.ask("call_translator", messages(ctx, call_text), schema(ctx), grammar(ctx))
	var r := await job.wait()
	if r["ok"]:
		var parsed := validate(ctx, r["text"])
		if parsed["valid"]:
			parsed["source"] = "model"
			parsed["ms"] = r["total_ms"]
			parsed["raw"] = r["text"]
			return parsed
		r["reason"] = "invalid: " + parsed["reason"]
	var fallback := from_keywords(ctx, call_text)
	fallback["reason"] = r["reason"]
	fallback["raw"] = r.get("text", "")
	fallback["ms"] = r["total_ms"]
	return fallback


## Checks model output against what the unit can do now; repairs mismatched
## targets (attack on an ally -> first enemy). Never returns an invalid action.
static func validate(ctx: Dictionary, text: String) -> Dictionary:
	var json := JSON.new()  # instance parse: no engine error log for garbage input
	if json.parse(text) != OK or not json.data is Dictionary:
		return {"valid": false, "reason": "not a JSON object"}
	var data: Dictionary = json.data
	var action: String = str(data.get("action", ""))
	if action not in ctx["actions"]:
		return {"valid": false, "reason": "action not allowed: " + action}
	var stance: String = str(data.get("stance", ""))
	if stance not in STANCES:
		stance = "offensive"
	var target_id: String = str(data.get("target", ""))
	var mid := action.substr(5)
	var resolved := _resolve_target(ctx, GameData.move(mid), target_id)
	if resolved.is_empty():
		return {"valid": false, "reason": "no valid target"}
	return {"valid": true, "reason": resolved.get("note", ""), "target_id": resolved["id"], "stance": stance,
		"action": Battle.call_action(mid, resolved["side"], resolved["slot"], stance, data.get("fits_situation", false) == true)}


## Template fallback: keyword matching in all three languages.
static func from_keywords(ctx: Dictionary, call_text: String) -> Dictionary:
	var text := call_text.to_lower()
	var u: BattleUnit = ctx["unit"]
	var kw := _kw()
	var wants := func(group: String) -> bool:
		return kw.get(group, []).any(func(w): return w in text)

	# 1. A move named explicitly wins.
	var move_id := ""
	for a in ctx["actions"]:
		var mid: String = a.substr(5)
		for loc in LOCALES:
			var n := _name_in(GameData.move(mid)["name"], loc).to_lower()
			if n != "" and n in text:
				move_id = mid
	# 2. Otherwise by intent.
	var stance := "offensive"
	if wants.call("heal"):
		move_id = move_id if move_id else _first_of_kind(ctx, "heal")
		stance = "protective"
	elif wants.call("protect") or wants.call("defend"):
		move_id = move_id if move_id else _first_of_kind(ctx, "guard")
		stance = "protective" if wants.call("protect") else "defensive"
	elif wants.call("status"):
		move_id = move_id if move_id else _first_of_kind(ctx, "status")
	if move_id == "":
		move_id = _best_attack(ctx)

	# Target: a named unit, else by hint, else default for the move.
	var target_id := ""
	for tid in ctx["targets"]:
		var t: BattleUnit = ctx["targets"][tid]["unit"]
		for loc in LOCALES:
			var n := _name_in(t.name_key(), loc).to_lower()
			if n != "" and n in text and tid != "self":
				target_id = tid
	var mv := GameData.move(move_id)
	if target_id == "" and mv["kind"] == "attack":
		target_id = _pick_enemy(ctx, wants.call("weakest"), wants.call("strongest"))
	if target_id == "" and wants.call("self"):
		target_id = "self"
	var resolved := _resolve_target(ctx, mv, target_id)
	return {"valid": true, "source": "template", "target_id": resolved["id"], "stance": stance,
		"action": Battle.call_action(move_id, resolved["side"], resolved["slot"], stance, false)}


## Slot of the player's Lingshou a call is addressed to by name (any language),
## among `open_slots`; -1 if the call names none of them.
static func addressed_slot(battle: Battle, side: int, open_slots: Array[int], call_text: String) -> int:
	var text := call_text.to_lower()
	for slot in open_slots:
		var u := battle.unit_at(side, slot)
		for loc in LOCALES:
			var n := _name_in(u.name_key(), loc).to_lower()
			if n != "" and text.begins_with(n):
				return slot
	return -1


## Up to three tap-to-send calls for the current situation (templates, no model).
static func suggestions(ctx: Dictionary) -> Array[String]:
	var out: Array[String] = []
	var u: BattleUnit = ctx["unit"]
	var battle: Battle = ctx["battle"]
	var name_of := func(tid: String) -> String:
		return TranslationServer.translate(ctx["targets"][tid]["unit"].name_key())
	# Best attack against the most vulnerable enemy.
	var best_mid := ""
	var best_tid := ""
	var best_dmg := -1
	for a in ctx["actions"]:
		var mv := GameData.move(a.substr(5))
		if mv["kind"] != "attack":
			continue
		for tid in ctx["targets"]:
			if tid.begins_with("enemy:"):
				var d := battle.damage(u, ctx["targets"][tid]["unit"], mv)
				if d > best_dmg:
					best_dmg = d
					best_mid = a.substr(5)
					best_tid = tid
	if best_mid != "":
		out.append(String(TranslationServer.translate("CALL_SUGGEST_ATTACK")).format(
			{"move": TranslationServer.translate(GameData.move(best_mid)["name"]), "target": name_of.call(best_tid)}))
	var partner_hurt := false
	if ctx["targets"].has("partner"):
		var p: BattleUnit = ctx["targets"]["partner"]["unit"]
		partner_hurt = float(p.hp) / p.max_hp < 0.5
	if partner_hurt and _first_of_kind(ctx, "guard") != "":
		out.append(String(TranslationServer.translate("CALL_SUGGEST_PROTECT")).format({"target": name_of.call("partner")}))
	if _first_of_kind(ctx, "heal") != "":
		if partner_hurt:
			out.append(String(TranslationServer.translate("CALL_SUGGEST_HEAL")).format({"target": name_of.call("partner")}))
		elif float(u.hp) / u.max_hp < 0.6:
			out.append(String(TranslationServer.translate("CALL_SUGGEST_HEAL_SELF")))
	var status_mid := _first_of_kind(ctx, "status")
	if out.size() < 3 and status_mid != "" and GameData.move(status_mid)["target"] == "enemy":
		var tid := _pick_enemy(ctx, false, true)
		if tid != "":
			out.append(String(TranslationServer.translate("CALL_SUGGEST_STATUS")).format(
				{"move": TranslationServer.translate(GameData.move(status_mid)["name"]), "target": name_of.call(tid)}))
	return out.slice(0, 3)


# --- helpers -----------------------------------------------------------------

static func _resolve_target(ctx: Dictionary, mv: Dictionary, target_id: String) -> Dictionary:
	var targets: Dictionary = ctx["targets"]
	var side: int = ctx["side"]
	var want_enemy: bool = mv["target"] == "enemy"
	var note := ""
	if targets.has(target_id):
		var t: Dictionary = targets[target_id]
		var is_enemy: bool = t["side"] != side
		if mv["target"] in ["self", "ally_side"]:
			return {"id": "self", "side": side, "slot": ctx["slot"]}
		if is_enemy == want_enemy:
			return {"id": target_id, "side": t["side"], "slot": t["slot"]}
		note = "target repaired"
	if want_enemy:
		var e := _pick_enemy(ctx, false, false)
		if e == "":
			return {}
		return {"id": e, "side": targets[e]["side"], "slot": targets[e]["slot"], "note": note}
	return {"id": "self", "side": side, "slot": ctx["slot"], "note": note}


static func _pick_enemy(ctx: Dictionary, weakest: bool, strongest: bool) -> String:
	var best := ""
	var best_val := INF if weakest else -INF
	for tid in ctx["targets"]:
		if not tid.begins_with("enemy:"):
			continue
		var t: BattleUnit = ctx["targets"][tid]["unit"]
		var frac := float(t.hp) / t.max_hp
		if best == "":
			best = tid
			best_val = frac
		elif weakest and frac < best_val:
			best = tid
			best_val = frac
		elif strongest and frac > best_val:
			best = tid
			best_val = frac
	return best


static func _first_of_kind(ctx: Dictionary, kind: String) -> String:
	for a in ctx["actions"]:
		if GameData.move(a.substr(5))["kind"] == kind:
			return a.substr(5)
	return ""


static func _best_attack(ctx: Dictionary) -> String:
	var battle: Battle = ctx["battle"]
	var u: BattleUnit = ctx["unit"]
	var best := BattleUnit.BASIC_MOVE
	var best_dmg := -1
	for a in ctx["actions"]:
		var mv := GameData.move(a.substr(5))
		if mv["kind"] != "attack":
			continue
		for tid in ctx["targets"]:
			if tid.begins_with("enemy:"):
				var d := battle.damage(u, ctx["targets"][tid]["unit"], mv)
				if d > best_dmg:
					best_dmg = d
					best = a.substr(5)
	return best


static func _names(key: String) -> String:
	var parts: Array[String] = []
	for loc in LOCALES:
		var n := _name_in(key, loc)
		if n != "" and n not in parts:
			parts.append(n)
	return " / ".join(parts)


static func _name_in(key: String, locale: String) -> String:
	var tr_obj := TranslationServer.get_translation_object(locale)
	if tr_obj == null:
		return ""
	return String(tr_obj.get_message(key))


static func _kw() -> Dictionary:
	if _keywords.is_empty():
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(KEYWORDS_PATH))
		_keywords = parsed if parsed is Dictionary else {}
	return _keywords
