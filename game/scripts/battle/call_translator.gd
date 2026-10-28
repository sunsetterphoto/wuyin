class_name CallTranslator
extends RefCounted
## Turns a free-text call ("Bambär, schütz Glutfasan!") into a battle action.
## The model proposes {action, target, stance} (the situation bonus is checked by code); the validator
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


## GBNF grammar for the answer line "<kind> <move> <target> <stance> <yes|no>",
## e.g. "guard schlammwand partner protective yes". The model first picks the
## kind of action (easy), then a move of that kind; about 11 tokens instead of
## ~30 for JSON (decoding is the slow part on phones). Only allowed values fit.
static func grammar(ctx: Dictionary, limits := {}) -> String:
	var alt := func(values: Array) -> String:
		return " | ".join(values.map(func(v): return "\"%s\"" % v))
	var by_kind := {}
	for a in limits.get("actions", ctx["actions"]):
		var kind: String = GameData.move(a.substr(5))["kind"]
		if not by_kind.has(kind):
			by_kind[kind] = []
		by_kind[kind].append(a.substr(5))
	var lines: Array[String] = []
	var choices: Array[String] = []
	var all_moves: Array = []
	for kind in by_kind:
		all_moves.append_array(by_kind[kind])
	lines.push_front("move ::= " + alt.call(all_moves))
	lines.push_front('root ::= "action=" move " target=" target " stance=" stance')
	lines.append("target ::= " + alt.call(limits.get("targets", ctx["targets"].keys())))
	lines.append("stance ::= " + alt.call(STANCES))
	return "\n".join(lines)


## Fixed part of every translator prompt. Kept identical across calls so the
## runtime's prompt cache can skip it (big win on phones).
const STATIC_RULES := """You turn a player's battle call for their spirit animal into an action. Calls may be German, English or Chinese.
Pick the action that matches the call. Attacks target an enemy; heal and guard target self or partner.
Protect, cover, shield or stand in front of the partner: guard with target partner. Heal or help the partner: heal with target partner.
Spirits may be named by name or animal (e.g. pangolin, fire bird). No name given: attack the enemy the player most likely means.
stance: offensive (attack), defensive (hold back), protective (shield someone).
Phases: wood beats earth, earth beats water, water beats fire, fire beats metal, metal beats wood.
Answer with one line: action=<action> target=<target> stance=<stance>.
Examples (action names differ per battle):
"Heal yourself!" -> action=<a heal action> target=self stance=protective
"Stand in front of <partner> and hold on!" -> action=<a guard action> target=partner stance=protective
"<move name> on <enemy>!" -> action=<that move> target=<that enemy> stance=offensive
"Hit the <animal>!" -> action=<strongest fitting attack> target=<enemy with that animal> stance=offensive
"Make them confused!" -> action=<the status action> target=<an enemy> stance=offensive"""


## Prompt layout for cache reuse: [static rules][this spirit, its actions and
## the spirits on the field] in the system message (stable over several turns),
## [HP, statuses, the call] in the user message (changes every request).
static func messages(ctx: Dictionary, call_text: String) -> Array:
	var u: BattleUnit = ctx["unit"]
	var lines: Array[String] = [STATIC_RULES, ""]
	lines.append("Your spirit: %s (%s), %s, %s." % [_names(u.name_key()), _names(u.species["animal"]), u.element(),
		", ".join(u.species.get("temperaments", []))])
	for tid in ctx["targets"]:
		if tid == "self":
			continue
		var t: BattleUnit = ctx["targets"][tid]["unit"]
		lines.append("%s = %s (%s), %s" % [tid, _names(t.name_key()), _names(t.species["animal"]), t.element()])
	lines.append("Actions:")
	for a in ctx["actions"]:
		var mv := GameData.move(a.substr(5))
		lines.append("- %s = %s: %s %s; %s" % [a.substr(5), _names(mv["name"]), mv["element"], mv["kind"], mv.get("llm_hint", "")])
	var facts: Array[String] = ["you HP %d/%d%s" % [u.hp, u.max_hp, _status_text(u)]]
	for tid in ctx["targets"]:
		if tid == "self":
			continue
		var t: BattleUnit = ctx["targets"][tid]["unit"]
		facts.append("%s HP %d/%d%s" % [tid, t.hp, t.max_hp, _status_text(t)])
	return [
		{"role": "system", "content": "\n".join(lines)},
		{"role": "user", "content": "Now: %s.\nCall: %s" % ["; ".join(facts), call_text]},
	]


static func _status_text(u: BattleUnit) -> String:
	return (" (" + ", ".join(u.statuses.keys()) + ")") if not u.statuses.is_empty() else ""


static func lane_for(ctx: Dictionary) -> String:
	return "calls:" + (ctx["unit"] as BattleUnit).uid


## At battle start (and after switches): precompute each active Lingshou's
## prompt so its first call only processes the short user part.
static func prepare(battle: Battle, side: int, service: LlmService = null) -> void:
	service = service if service else LlmService.instance()
	if not service.is_model_available():
		return
	for slot in battle.sides[side]["active"].size():
		var u := battle.unit_at(side, slot)
		if u.is_alive():
			var ctx := context(battle, side, slot)
			service.prefill(lane_for(ctx), messages(ctx, "")[0]["content"])


## Full pipeline: model if available, else keywords. Always returns a valid action.
## {"action": Dictionary, "source": "model"|"template", "reason": String, "raw": String, "ms": int}
static func translate(ctx: Dictionary, call_text: String, service: LlmService = null) -> Dictionary:
	service = service if service else LlmService.instance()
	var job := service.ask("call_translator", messages(ctx, call_text), schema(ctx), grammar(ctx, constraints(ctx, call_text)),
		lane_for(ctx))
	var r := await job.wait()
	if r["ok"]:
		var parsed := validate(ctx, r["text"])
		if parsed["valid"]:
			parsed["source"] = "model"
			parsed["ms"] = r["total_ms"]
			parsed["stats"] = job.get_meta("stats", {})
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
	var data := parse_answer(text)
	if data.is_empty():
		return {"valid": false, "reason": "unreadable answer"}
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


## What the code can already tell from the call, enforced through the grammar
## so small models can't contradict it: an explicitly named move, a named or
## described target, and clear heal/protect wording. Ambiguity stays with the model.
## Returns {"actions": [...], "targets": [...]} with only the restricted keys.
static func constraints(ctx: Dictionary, call_text: String) -> Dictionary:
	var text := call_text.to_lower()
	var kw := _kw()
	var wants := func(group: String) -> bool:
		return kw.get(group, []).any(func(w): return w in text)
	var out := {}

	var named: Array[String] = []
	for a in ctx["actions"]:
		if _mentions_move(text, a.substr(5)) and a not in named:
			named.append(a)
	var kinds := func(kind: String) -> Array[String]:
		var r: Array[String] = []
		for a in ctx["actions"]:
			if GameData.move(a.substr(5))["kind"] == kind:
				r.append(a)
		return r
	if not named.is_empty():
		out["actions"] = named
	elif wants.call("heal") and not kinds.call("heal").is_empty():
		out["actions"] = kinds.call("heal")
	elif (wants.call("protect") or wants.call("defend")) and not kinds.call("guard").is_empty():
		out["actions"] = kinds.call("guard")
	elif wants.call("status") and not kinds.call("status").is_empty():
		out["actions"] = kinds.call("status")
	elif wants.call("attack") and not kinds.call("attack").is_empty():
		out["actions"] = kinds.call("attack")

	var targets: Array[String] = []
	for tid in ctx["targets"]:
		if tid == "self":
			continue
		if _mentions_unit(text, ctx["targets"][tid]["unit"]) or (tid == "partner" and wants.call("partner")):
			targets.append(tid)
	var allowed_kinds := {}
	for a in out.get("actions", ctx["actions"]):
		allowed_kinds[GameData.move(a.substr(5))["target"]] = true
	var only_enemy_moves := allowed_kinds.keys() == ["enemy"]
	var only_support := not allowed_kinds.has("enemy")
	if not targets.is_empty():
		var fitting := targets.filter(func(t): return t.begins_with("enemy:") == (not only_support) or not (only_enemy_moves or only_support))
		if not fitting.is_empty():
			out["targets"] = fitting
	elif only_enemy_moves:
		out["targets"] = ctx["targets"].keys().filter(func(t): return t.begins_with("enemy:"))
	elif only_support and wants.call("self"):
		out["targets"] = ["self"]
	return out


## A move is named when its full name appears, or every word of the name
## (4+ letters) appears in any order: "Lash the bird with your vines" = "Vine Lash".
static func _mentions_move(text: String, mid: String) -> bool:
	for loc in LOCALES:
		var n := _name_in(GameData.move(mid)["name"], loc).to_lower()
		if n == "":
			continue
		if n in text:
			return true
		var words := Array(n.split(" ", false)).filter(func(w): return w.length() >= 4)
		if words.size() >= 2 and words.all(func(w): return w in text):
			return true
	return false


## Name or animal of a unit appears in the call (any language).
static func _mentions_unit(text: String, u: BattleUnit) -> bool:
	for loc in LOCALES:
		var n := _name_in(u.name_key(), loc).to_lower()
		if n != "" and n in text:
			return true
		var animal := _name_in(u.species["animal"], loc).to_lower()
		for part in animal.replace("(", ",").replace(")", ",").split(","):
			part = part.strip_edges()
			if part.length() >= 4 and part in text:
				return true
			for w in part.split(" "):
				if w.length() >= 6 and w in text:
					return true
	return false


## Reads the compact answer line (or JSON, e.g. from older tools) into
## {"action": "move:<id>", "target", "stance", "fits_situation"}; {} if unreadable.
static func parse_answer(text: String) -> Dictionary:
	var t := text.strip_edges()
	if t.begins_with("{"):
		var json := JSON.new()  # instance parse: no engine error log for garbage input
		return json.data if json.parse(t) == OK and json.data is Dictionary else {}
	var parts := t.split(" ", false)
	if parts.size() >= 3 and parts[0].begins_with("action="):
		parts = PackedStringArray(Array(parts).map(func(p): return p.get_slice("=", 1)))
		if parts.size() == 3:
			parts.append("yes")  # the code checks the battle facts for the situation bonus
	if parts.size() == 5:
		parts.remove_at(0)  # leading kind
	if parts.size() != 4:
		return {}
	return {"action": "move:" + parts[0], "target": parts[1], "stance": parts[2], "fits_situation": parts[3] == "yes"}


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


## Names in the game language and English (the call is usually in one of them).
static func _names(key: String) -> String:
	var parts: Array[String] = []
	var game_locale := TranslationServer.get_locale()
	var locales: Array[String] = ["en"]
	for loc in LOCALES:
		if game_locale.begins_with(loc.left(2)) and loc != "en":
			locales.push_front(loc)
	for loc in locales:
		var n := _name_in(key, loc)
		if n != "" and n not in parts:
			parts.append(n)
	return " / ".join(parts)


static func _name_in(key: String, locale: String) -> String:
	return Texts.get_text(key, locale)


static func _kw() -> Dictionary:
	if _keywords.is_empty():
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(KEYWORDS_PATH))
		_keywords = parsed if parsed is Dictionary else {}
	return _keywords
