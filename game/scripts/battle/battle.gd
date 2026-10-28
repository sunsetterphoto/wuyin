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
## How the battle ended: "win", "lose", "tamed", "freed", "fled" ("" while running).
var outcome := ""
## Breath per side: each call costs one, regenerates every few turns.
var breath: Array[int] = []
## Per-unit mood shift for moody Lingshou (uid -> float), rolled at battle start.
var moods: Dictionary = {}
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
			var u := BattleUnit.from_record({"species": spec["id"], "level": int(spec.get("level", 5)),
				"uid": spec.get("uid", "s%dp%d" % [s, i])}.merged(spec))
			u.side = s
			u.role = spec.get("role", "")
			if u.role == "wild":
				u.trust = int(spec.get("trust", Taming.START_TRUST))
			party.append(u)
		var act: Array[int] = []
		for i in party.size():
			if act.size() < active and party[i].is_alive():
				act.append(i)
		b.sides.append({"party": party, "active": act})
		b.breath.append(Obedience.BREATH_MAX)
	for side in b.sides:
		for u in side["party"]:
			if "moody" in u.species.get("temperaments", []):
				b.moods[u.uid] = Obedience.roll_mood(b.rng)
	return b


static func move_action(move_id: String, target_side: int, target_slot: int) -> Dictionary:
	return {"type": "move", "move": move_id, "target_side": target_side, "target_slot": target_slot}


## A call (free-text command) after translation and validation.
static func call_action(move_id: String, target_side: int, target_slot: int, stance: String, fits_situation: bool) -> Dictionary:
	var a := move_action(move_id, target_side, target_slot)
	a["call"] = true
	a["stance"] = stance
	a["fits_situation"] = fits_situation
	return a


static func switch_action(party_index: int) -> Dictionary:
	return {"type": "switch", "party_index": party_index}


## Befriending a wild or silenced opponent instead of attacking (act: calm | feed | talk).
static func tame_action(act: String, target_slot: int, item := "", tone := "neutral") -> Dictionary:
	return {"type": "tame", "act": act, "target_side": 1, "target_slot": target_slot, "item": item, "tone": tone}


## Using an item from the bag on a party member (heal, revive).
static func item_action(item: String, party_index: int) -> Dictionary:
	return {"type": "item", "item": item, "party_index": party_index}


static func flee_action() -> Dictionary:
	return {"type": "flee"}


## A wild Lingshou that trusts the player just watches.
static func watch_action() -> Dictionary:
	return {"type": "watch"}


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


## Active slot of `u`, or -1 when it is on the bench.
func slot_of(u: BattleUnit) -> int:
	return sides[u.side]["active"].find(sides[u.side]["party"].find(u))


func bench(side: int) -> Array[int]:
	var out: Array[int] = []
	var party: Array = sides[side]["party"]
	for i in party.size():
		if i not in sides[side]["active"] and party[i].is_alive():
			out.append(i)
	return out


func is_over() -> bool:
	return outcome != ""


## Only wild battles can be left (not rivals, silenced or guardians).
func can_flee(side := 0) -> bool:
	return active_units(1 - side).all(func(u): return u.role == "wild") and sides[1 - side]["party"].size() == 1


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
	if action.get("call", false):
		if not u.accepts_calls():
			return "unit is deaf to calls"
		if breath[side] <= 0:
			return "no breath left"
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
		"tame":
			var t := unit_at(int(action.get("target_side", 1)), int(action.get("target_slot", 0)))
			if t == null or t.side == side or not (Taming.is_tameable(t) or Taming.is_silenced(t)):
				return "nothing to befriend there"
			var act: String = action.get("act", "")
			if act not in ["calm", "feed", "talk"]:
				return "unknown befriending act"
			if act == "feed" and (not Taming.is_tameable(t) or GameData.item(action.get("item", "")).get("kind") != "food"):
				return "can only feed wild Lingshou with food"
		"item":
			var it := GameData.item(action.get("item", ""))
			var idx := int(action.get("party_index", -1))
			if it.is_empty() or it.get("kind") not in ["heal", "revive"] or idx < 0 or idx >= sides[side]["party"].size():
				return "item cannot be used like that"
			var target: BattleUnit = sides[side]["party"][idx]
			if it["kind"] == "heal" and (not target.is_alive() or target.hp >= target.max_hp):
				return "item would have no effect"
			if it["kind"] == "revive" and target.is_alive():
				return "item would have no effect"
		"flee":
			if not can_flee(side):
				return "cannot flee from this battle"
		"watch":
			pass
		_:
			return "unknown action type"
	if action.get("call", false):
		breath[side] -= 1
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
		match action["type"]:
			"switch":
				_do_switch(u, action, events)
			"move":
				_do_move(u, action, events)
			"tame":
				_do_tame(u, action, events)
			"item":
				_do_item(u, action, events)
			"flee":
				outcome = "fled"
				events.append({"type": "fled", "user": u.uid})
			"watch":
				events.append({"type": "watch", "user": u.uid})
		if is_over() or _check_end(events):
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
		var prio := 0
		match action["type"]:
			"flee":
				prio = 20
			"switch", "item":
				prio = 10
			"tame":
				prio = 5
			"move":
				prio = int(GameData.move(action["move"]).get("priority", 0))
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


func _do_tame(u: BattleUnit, action: Dictionary, events: Array[Dictionary]) -> void:
	var t := unit_at(int(action["target_side"]), int(action["target_slot"]))
	if t == null or not t.is_alive():
		events.append({"type": "no_effect"})
		return
	var act: String = action["act"]
	var amount := Taming.gain(t, act, action.get("item", ""), action.get("tone", "neutral"), moods.get(t.uid, 0.0))
	events.append({"type": "tame_" + act, "user": u.uid, "target": t.uid, "item": action.get("item", ""),
		"tone": action.get("tone", "")})
	if Taming.is_silenced(t):
		_add_heart(t, amount, events)
	else:
		t.trust = clampi(t.trust + amount, 0, Taming.TRUST_FULL)
		events.append({"type": "trust", "target": t.uid, "amount": amount, "total": t.trust})
		if t.trust >= Taming.TRUST_FULL:
			outcome = "tamed"
			winner = u.side
			events.append({"type": "tamed", "target": t.uid})
			_award_xp(u.side, events)


func _add_heart(t: BattleUnit, amount: int, events: Array[Dictionary]) -> void:
	if amount <= 0:
		return
	t.heart = clampi(t.heart + amount, 0, Taming.HEART_FULL)
	events.append({"type": "heart", "target": t.uid, "amount": amount, "total": t.heart})
	if t.heart >= Taming.HEART_FULL and outcome == "":
		# Freed: the silenced Lingshou stops fighting; with two opponents the battle
		# ends once every silenced one is freed and the rest are exhausted.
		events.append({"type": "freed", "target": t.uid})
		t.freed = true
		var others: Array = sides[t.side]["party"].filter(func(o): return o != t and o.is_alive())
		if others.is_empty():
			outcome = "freed"
			winner = 1 - t.side
			_award_xp(winner, events)


func _do_item(u: BattleUnit, action: Dictionary, events: Array[Dictionary]) -> void:
	var it := GameData.item(action["item"])
	var t: BattleUnit = sides[u.side]["party"][int(action["party_index"])]
	events.append({"type": "item", "user": u.uid, "item": action["item"], "target": t.uid})
	match it["kind"]:
		"heal":
			if not t.is_alive():
				events.append({"type": "no_effect"})
				return
			var amount := mini(t.max_hp - t.hp, ceili(t.max_hp * float(it.get("heal_pct", 0)) / 100.0))
			t.hp += amount
			events.append({"type": "heal", "target": t.uid, "amount": amount})
		"revive":
			if t.is_alive():
				events.append({"type": "no_effect"})
				return
			t.hp = maxi(1, ceili(t.max_hp * float(it.get("heal_pct", 50)) / 100.0))
			events.append({"type": "revive", "target": t.uid, "amount": t.hp})


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
	var bonus := 0.0

	if action.get("call", false):
		var stance: String = action.get("stance", "offensive")
		var p := Obedience.chance(u, stance, GameData.move(mid)["kind"], moods.get(u.uid, 0.0))
		if rng.randf() >= p:
			var own := BattleAI.choose_for(self, u)
			events.append({"type": "disobey", "user": u.uid, "move": mid, "chance": p})
			mid = own["move"]
			tside = own["target_side"]
			tslot = own["target_slot"]
		else:
			events.append({"type": "obey", "user": u.uid, "chance": p})
			var target := unit_at(tside, tslot)
			bonus = Obedience.situation_bonus(self, u, GameData.move(mid), target, stance,
				action.get("fits_situation", false))
			if bonus > 0.0:
				events.append({"type": "situation_bonus", "user": u.uid, "bonus": bonus})

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
				_attack(u, t, mv, 1.0 + bonus, events)
			if u.has_status("echo") and targets[0].is_alive():
				events.append({"type": "echo", "user": u.uid})
				_attack(u, targets[0], mv, ECHO_POWER, events)
				u.statuses.erase("echo")
				events.append({"type": "status_end", "target": u.uid, "status": "echo"})
		"heal":
			for t in targets:
				var amount := mini(t.max_hp - t.hp, ceili(t.max_hp * float(mv.get("heal_pct", 0)) / 100.0 * (1.0 + bonus)))
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
	if Taming.is_tameable(t) and t.side != u.side:
		t.trust = maxi(0, t.trust - Taming.HIT_PENALTY)
	if Taming.is_silenced(t) and t.side != u.side and t.is_alive():
		_add_heart(t, Taming.heart_from_damage(t, amount), events)
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
	if turn % Obedience.BREATH_REGEN_TURNS == 0:
		for s in breath.size():
			breath[s] = mini(Obedience.BREATH_MAX, breath[s] + 1)
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
			outcome = "win" if winner == 0 else "lose"
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
