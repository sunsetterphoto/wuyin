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
