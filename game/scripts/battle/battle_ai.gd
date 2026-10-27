class_name BattleAI
extends RefCounted
## Simple opponent: heals a hurt ally, otherwise mostly picks the move with the
## best expected damage. Uses its own RNG (derived from the battle seed) so AI
## decisions never shift the battle's random sequence.

const HEAL_BELOW := 0.35
const RANDOM_CHOICE := 0.25

var rng := RandomNumberGenerator.new()


func _init(seed_value: int) -> void:
	rng.seed = seed_value ^ 0x5eed_a1


## Submits actions for every open slot of `side`.
func fill(battle: Battle, side: int) -> void:
	for slot in battle.open_slots(side):
		var action := choose(battle, side, slot)
		var err := battle.submit(side, slot, action)
		assert(err == "", "AI produced invalid action: " + err)


## What a disobedient Lingshou does on its own: the best-scoring move for its
## temperament, without the AI's random spread (uses no RNG).
static func choose_for(battle: Battle, u: BattleUnit) -> Dictionary:
	var gentle: bool = "gentle" in u.species.get("temperaments", [])
	var anxious: bool = "anxious" in u.species.get("temperaments", [])
	var best := Battle.move_action(BattleUnit.BASIC_MOVE, 1 - u.side, 0)
	var best_score := -1.0
	for mid in u.usable_moves():
		var mv := GameData.move(mid)
		var score := 0.0
		var action := {}
		match mv["kind"]:
			"attack":
				for s in battle.sides[1 - u.side]["active"].size():
					var t := battle.unit_at(1 - u.side, s)
					if t.is_alive():
						var sc := float(battle.damage(u, t, mv)) * (0.6 if anxious or gentle else 1.0)
						if sc > score:
							score = sc
							action = Battle.move_action(mid, 1 - u.side, s)
			"heal", "guard":
				if gentle or anxious:
					score = 30.0 if float(u.hp) / u.max_hp < 0.6 else 5.0
					action = Battle.move_action(mid, u.side, battle.slot_of(u))
		if not action.is_empty() and score > best_score:
			best_score = score
			best = action
	return best


func choose(battle: Battle, side: int, slot: int) -> Dictionary:
	var u := battle.unit_at(side, slot)
	var usable := u.usable_moves()

	# Heal a badly hurt ally first.
	for mid in usable:
		var mv := GameData.move(mid)
		if mv["kind"] != "heal":
			continue
		for s in battle.sides[side]["active"].size():
			var ally := battle.unit_at(side, s)
			if ally.is_alive() and float(ally.hp) / ally.max_hp < HEAL_BELOW:
				return Battle.move_action(mid, side, s)

	var enemy_side := 1 - side
	var candidates := []
	for mid in usable:
		var mv := GameData.move(mid)
		if mv["kind"] == "attack":
			for s in battle.sides[enemy_side]["active"].size():
				var t := battle.unit_at(enemy_side, s)
				if t.is_alive():
					var score := battle.damage(u, t, mv) * int(mv.get("accuracy", 100)) / 100.0
					candidates.append({"action": Battle.move_action(mid, enemy_side, s), "score": score})
		elif mv["kind"] == "status" and mv["target"] == "enemy":
			for s in battle.sides[enemy_side]["active"].size():
				var t := battle.unit_at(enemy_side, s)
				if t.is_alive() and not t.has_status(mv["effect"]["status"]):
					candidates.append({"action": Battle.move_action(mid, enemy_side, s), "score": 0.0})
		elif mv["kind"] in ["status", "guard"]:
			candidates.append({"action": Battle.move_action(mid, side, slot), "score": 0.0})

	if candidates.is_empty():
		return Battle.move_action(BattleUnit.BASIC_MOVE, enemy_side, 0)
	if rng.randf() < RANDOM_CHOICE:
		return candidates[rng.randi_range(0, candidates.size() - 1)]["action"]
	candidates.sort_custom(func(a, b): return a["score"] > b["score"])
	return candidates[0]["action"]
