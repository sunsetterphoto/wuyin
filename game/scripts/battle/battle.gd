class_name Battle
extends RefCounted
## Turn-based battle core: 1 vs 1 (wild) or 2 vs 2 (bosses, order, guardians).
## Pure logic, no nodes. Every random roll comes from one RNG seeded at
## creation, so the same seed and the same commands give the same battle.
##
## Usage:
##   var b := Battle.create(seed, [[{"id": "bambaer", "level": 5}], [{"id": "glutfasan", "level": 5}]], 1)
##   b.submit(0, 0, Battle.move_action("bambusschlag", 1, 0))
##   BattleAI.new(b.seed_value).fill(b, 1)
##   var events := b.resolve_turn()

const DISSONANCE_CHANCE := 0.35
const ECHO_POWER := 0.5
const SAME_ELEMENT_MULT := 1.2
const GUARD_MULT := 0.5
const DAMAGE_SCALE := 0.4

var rng := RandomNumberGenerator.new()
var seed_value: int
var turn := 0
var active_count := 1
## sides[s] = {"party": Array[BattleUnit], "active": Array[int] (party indices)}
var sides: Array[Dictionary] = []
## Pending actions: "side:slot" -> action Dictionary
var pending: Dictionary = {}
var winner := -1
## Every event of the battle so far (for replays and determinism checks).
var history: Array[Dictionary] = []


static func create(battle_seed: int, parties: Array, active := 1) -> Battle:
	var b := Battle.new()
	b.seed_value = battle_seed
	b.rng.seed = battle_seed
	b.active_count = active
	for s in parties.size():
		var party: Array[BattleUnit] = []
		for i in parties[s].size():
			var spec: Dictionary = parties[s][i]
			var u := BattleUnit.create(spec["id"], int(spec.get("level", 5)), spec.get("uid", "s%dp%d" % [s, i]))
			u.side = s
			party.append(u)
		var act: Array[int] = []
		for i in party.size():
			if act.size() < active and party[i].is_alive():
				act.append(i)
		b.sides.append({"party": party, "active": act})
	return b


static func move_action(move_id: String, target_side: int, target_slot: int) -> Dictionary:
	return {"type": "move", "move": move_id, "target_side": target_side, "target_slot": target_slot}


static func switch_action(party_index: int) -> Dictionary:
	return {"type": "switch", "party_index": party_index}


# --- queries -----------------------------------------------------------------

func unit_at(side: int, slot: int) -> BattleUnit:
	var act: Array[int] = sides[side]["active"]
	if slot < 0 or slot >= act.size():
		return null
	return sides[side]["party"][act[slot]]


func active_units(side: int) -> Array[BattleUnit]:
	var out: Array[BattleUnit] = []
	for i in sides[side]["active"]:
		out.append(sides[side]["party"][i])
	return out


func bench(side: int) -> Array[int]:
	var out: Array[int] = []
	var party: Array = sides[side]["party"]
	for i in party.size():
		if i not in sides[side]["active"] and party[i].is_alive():
			out.append(i)
	return out


func is_over() -> bool:
	return winner >= 0


## Damage fraction both allies of `side` gain from the generating cycle.
func team_bonus(side: int) -> float:
	var act := active_units(side).filter(func(u): return u.is_alive())
	if act.size() < 2:
		return 0.0
	var res: bool = act[0].has_status("resonance") or act[1].has_status("resonance")
	return WuXing.team_bonus(act[0].element(), act[1].element(), res)


## Slots that still need an action this turn.
func open_slots(side: int) -> Array[int]:
	var out: Array[int] = []
	for slot in sides[side]["active"].size():
		if unit_at(side, slot).is_alive() and not pending.has(_key(side, slot)):
			out.append(slot)
	return out


func needs_actions() -> bool:
	for s in sides.size():
		if not open_slots(s).is_empty():
			return true
	return false


# --- commands ----------------------------------------------------------------

## Returns "" on success, otherwise the reason the action is invalid.
func submit(side: int, slot: int, action: Dictionary) -> String:
	if is_over():
		return "battle is over"
	var u := unit_at(side, slot)
	if u == null or not u.is_alive():
		return "no active unit in that slot"
	match action.get("type"):
		"move":
			var mid: String = action.get("move", "")
			if mid not in u.usable_moves():
				return "move not usable: " + mid
			var mv := GameData.move(mid)
			if mv["target"] == "enemy":
				var t := unit_at(int(action.get("target_side", -1)), int(action.get("target_slot", -1)))
				if t == null or t.side == side:
					return "enemy move needs an enemy target"
			elif mv["target"] == "ally":
				var t := unit_at(int(action.get("target_side", -1)), int(action.get("target_slot", -1)))
				if t == null or t.side != side:
					return "ally move needs an ally target"
		"switch":
			if int(action.get("party_index", -1)) not in bench(side):
				return "cannot switch to that party member"
			for k in pending:
				var other: Dictionary = pending[k]
				if k.begins_with("%d:" % side) and other.get("type") == "switch" \
						and other["party_index"] == action["party_index"]:
					return "party member already switching in"
		_:
			return "unknown action type"
	pending[_key(side, slot)] = action
	return ""


# --- turn resolution ---------------------------------------------------------

func resolve_turn() -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	if is_over():
		return events
	assert(not needs_actions(), "all active units need an action")
	turn += 1
	if turn == 1:
		_announce_team_bonus(events)

	var order := _turn_order()
	for entry in order:
		var u: BattleUnit = entry["unit"]
		if not u.is_alive() or not _is_active(u):
			continue
		var action: Dictionary = entry["action"]
		if action["type"] == "switch":
			_do_switch(u, action, events)
		else:
			_do_move(u, action, events)
		if _check_end(events):
			break

	_end_of_turn(events)
	pending.clear()
	history.append_array(events)
	return events


func _turn_order() -> Array:
	var entries := []
	for key in pending:
		var parts: PackedStringArray = key.split(":")
		var u := unit_at(int(parts[0]), int(parts[1]))
		var action: Dictionary = pending[key]
		var prio := 10 if action["type"] == "switch" else int(GameData.move(action["move"]).get("priority", 0))
		entries.append({"unit": u, "action": action, "prio": prio, "spd": u.spd, "tie": rng.randf(), "key": key})
	# Sort by key first so the tie-break rolls never depend on dictionary order.
	entries.sort_custom(func(a, b): return a["key"] < b["key"])
	entries.sort_custom(func(a, b):
		if a["prio"] != b["prio"]:
			return a["prio"] > b["prio"]
		if a["spd"] != b["spd"]:
			return a["spd"] > b["spd"]
		return a["tie"] > b["tie"])
	return entries


func _do_switch(u: BattleUnit, action: Dictionary, events: Array[Dictionary]) -> void:
	var side := u.side
	var idx: int = action["party_index"]
	var act: Array[int] = sides[side]["active"]
	var slot := act.find(sides[side]["party"].find(u))
	var incoming: BattleUnit = sides[side]["party"][idx]
	if not incoming.is_alive() or idx in act:
		return
	act[slot] = idx
	events.append({"type": "switch", "user": u.uid, "target": incoming.uid, "side": side, "slot": slot})
	_announce_team_bonus(events, side)


func _do_move(u: BattleUnit, action: Dictionary, events: Array[Dictionary]) -> void:
	var mid: String = action["move"]
	var tside: int = action.get("target_side", u.side)
	var tslot: int = action.get("target_slot", 0)

	if u.has_status("silenced") and GameData.move(mid)["element"] != WuXing.NEUTRAL:
		events.append({"type": "silenced_fallback", "user": u.uid, "move": mid})
		mid = BattleUnit.BASIC_MOVE
		tside = 1 - u.side
	if u.has_status("dissonance") and rng.randf() < DISSONANCE_CHANCE:
		var options := u.usable_moves()
		options.erase(mid)
		if not options.is_empty():
			mid = options[rng.randi_range(0, options.size() - 1)]
			events.append({"type": "dissonance", "user": u.uid, "move": mid})
			var t := _random_target(u, GameData.move(mid))
			tside = t.x
			tslot = t.y

	var mv := GameData.move(mid)
	events.append({"type": "uses", "user": u.uid, "move": mid})
	var targets := _resolve_targets(u, mv, tside, tslot)
	if targets.is_empty():
		events.append({"type": "no_effect"})
		return

	match mv["kind"]:
		"attack":
			for t in targets:
				_attack(u, t, mv, 1.0, events)
			if u.has_status("echo") and targets[0].is_alive():
				events.append({"type": "echo", "user": u.uid})
				_attack(u, targets[0], mv, ECHO_POWER, events)
				u.statuses.erase("echo")
				events.append({"type": "status_end", "target": u.uid, "status": "echo"})
		"heal":
			for t in targets:
				var amount := mini(t.max_hp - t.hp, ceili(t.max_hp * float(mv.get("heal_pct", 0)) / 100.0))
				t.hp += amount
				events.append({"type": "heal", "target": t.uid, "amount": amount})
		"guard":
			for t in targets:
				t.shielded = true
				events.append({"type": "guard", "target": t.uid})
		"status":
			if not _hits(mv):
				events.append({"type": "miss", "user": u.uid})
				return
			for t in targets:
				_apply_effect(mv, t, events, true)


func _attack(u: BattleUnit, t: BattleUnit, mv: Dictionary, power_mult: float, events: Array[Dictionary]) -> void:
	if not _hits(mv):
		events.append({"type": "miss", "user": u.uid})
		return
	var eff := WuXing.effectiveness(mv["element"], t.element())
	var amount := damage(u, t, mv, power_mult, rng.randf_range(0.9, 1.0))
	t.hp = maxi(0, t.hp - amount)
	events.append({"type": "damage", "target": t.uid, "amount": amount, "effectiveness": eff,
		"target_element": t.element()})
	if t.is_alive():
		_apply_effect(mv, t, events, false)
	else:
		events.append({"type": "faint", "target": t.uid})


## Damage of one hit. `roll` is the random factor (0.9..1.0); pass 1.0 for previews.
func damage(u: BattleUnit, t: BattleUnit, mv: Dictionary, power_mult := 1.0, roll := 1.0) -> int:
	# sqrt keeps lopsided attack/defense matchups from one-shotting (target: 3-4 hits per Lingshou).
	var ratio := sqrt(float(u.atk) / float(maxi(1, t.def)))
	var base := float(mv.get("power", 0)) * power_mult * ratio * (0.5 + u.level * 0.05) * DAMAGE_SCALE
	var mult := WuXing.effectiveness(mv["element"], t.element())
	if mv["element"] == u.element():
		mult *= SAME_ELEMENT_MULT
	mult *= 1.0 + team_bonus(u.side)
	if t.shielded:
		mult *= GUARD_MULT
	return maxi(1, roundi(base * mult * roll))


func _apply_effect(mv: Dictionary, t: BattleUnit, events: Array[Dictionary], primary: bool) -> void:
	var effect = mv.get("effect")
	if effect == null:
		return
	if not primary and rng.randi_range(1, 100) > int(effect.get("chance", 100)):
		return
	var status: String = effect["status"]
	t.statuses[status] = {"turns": int(effect["turns"]), "applied_turn": turn}
	events.append({"type": "status", "target": t.uid, "status": status})


func _hits(mv: Dictionary) -> bool:
	var acc := int(mv.get("accuracy", 100))
	return acc >= 100 or rng.randi_range(1, 100) <= acc


func _resolve_targets(u: BattleUnit, mv: Dictionary, tside: int, tslot: int) -> Array[BattleUnit]:
	var out: Array[BattleUnit] = []
	match mv["target"]:
		"self":
			out.append(u)
		"ally_side":
			for a in active_units(u.side):
				if a.is_alive():
					out.append(a)
		_:
			var t := unit_at(tside, tslot)
			if t != null and t.is_alive():
				out.append(t)
			else:
				# Original target gone: pick the first living unit on that side.
				for a in active_units(tside if tside >= 0 else 1 - u.side):
					if a.is_alive():
						out.append(a)
						break
	return out


func _random_target(u: BattleUnit, mv: Dictionary) -> Vector2i:
	var side := 1 - u.side if mv["target"] == "enemy" else u.side
	var slots: Array[int] = []
	for slot in sides[side]["active"].size():
		if unit_at(side, slot).is_alive():
			slots.append(slot)
	if slots.is_empty():
		return Vector2i(side, 0)
	return Vector2i(side, slots[rng.randi_range(0, slots.size() - 1)])


func _end_of_turn(events: Array[Dictionary]) -> void:
	for s in sides.size():
		for u in sides[s]["party"]:
			u.shielded = false
			for status in u.statuses.keys():
				var st: Dictionary = u.statuses[status]
				if st["applied_turn"] == turn:
					continue
				st["turns"] -= 1
				if st["turns"] <= 0:
					u.statuses.erase(status)
					if u.is_alive():
						events.append({"type": "status_end", "target": u.uid, "status": status})
	if is_over():
		return
	for s in sides.size():
		var act: Array[int] = sides[s]["active"]
		var replaced := false
		for slot in act.size():
			if sides[s]["party"][act[slot]].is_alive():
				continue
			var b := bench(s)
			if b.is_empty():
				continue
			act[slot] = b[0]
			replaced = true
			events.append({"type": "send_in", "target": sides[s]["party"][b[0]].uid, "side": s, "slot": slot})
		if replaced:
			_announce_team_bonus(events, s)


func _check_end(events: Array[Dictionary]) -> bool:
	for s in sides.size():
		var alive: bool = sides[s]["party"].any(func(u): return u.is_alive())
		if not alive:
			winner = 1 - s
			events.append({"type": "end", "winner": winner})
			_award_xp(winner, events)
			return true
	return false


func _award_xp(side: int, events: Array[Dictionary]) -> void:
	var reward := 0
	for u in sides[1 - side]["party"]:
		reward += BattleUnit.xp_reward(u.level)
	for u in sides[side]["party"]:
		if not u.is_alive():
			continue
		var gained: int = u.gain_xp(reward)
		events.append({"type": "xp", "target": u.uid, "amount": reward})
		if gained > 0:
			events.append({"type": "level_up", "target": u.uid, "level": u.level})


func _announce_team_bonus(events: Array[Dictionary], only_side := -1) -> void:
	for s in sides.size():
		if only_side >= 0 and s != only_side:
			continue
		if team_bonus(s) > 0.0:
			var act := active_units(s)
			events.append({"type": "team_bonus", "side": s, "a": act[0].uid, "b": act[1].uid})


func _is_active(u: BattleUnit) -> bool:
	return sides[u.side]["party"].find(u) in sides[u.side]["active"]


func _key(side: int, slot: int) -> String:
	return "%d:%d" % [side, slot]


func find_unit(uid: String) -> BattleUnit:
	for s in sides:
		for u in s["party"]:
			if u.uid == uid:
				return u
	return null
