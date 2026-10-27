class_name WuXing
extends RefCounted
## The Five Phases (Wu Xing). Overcoming (ke) = type advantage,
## generating (sheng) = team bonus for two allies fighting side by side.

const WOOD := "wood"
const FIRE := "fire"
const EARTH := "earth"
const METAL := "metal"
const WATER := "water"
## Moves without a phase (e.g. the basic attack).
const NEUTRAL := "neutral"

const ELEMENTS: Array[String] = [WOOD, FIRE, EARTH, METAL, WATER]

## Overcoming cycle: key overcomes value.
const OVERCOMES := {WOOD: EARTH, EARTH: WATER, WATER: FIRE, FIRE: METAL, METAL: WOOD}
## Generating cycle: key nourishes value.
const GENERATES := {WOOD: FIRE, FIRE: EARTH, EARTH: METAL, METAL: WATER, WATER: WOOD}

const ADVANTAGE_MULT := 1.5
## The defender's phase overcomes the attack's phase: the attack is weakened.
const DISADVANTAGE_MULT := 0.75
const TEAM_BONUS := 0.10


static func is_element(e: String) -> bool:
	return e in ELEMENTS


static func overcomes(attacker: String, defender: String) -> bool:
	return OVERCOMES.get(attacker, "") == defender


static func generates(a: String, b: String) -> bool:
	return GENERATES.get(a, "") == b


## Damage multiplier of an attack of phase `move_element` against a target of phase `target_element`.
static func effectiveness(move_element: String, target_element: String) -> float:
	if overcomes(move_element, target_element):
		return ADVANTAGE_MULT
	if overcomes(target_element, move_element):
		return DISADVANTAGE_MULT
	return 1.0


## Two allies whose phases follow each other in the generating cycle (either direction).
static func is_team_pair(a: String, b: String) -> bool:
	return generates(a, b) or generates(b, a)


## Extra damage fraction for both allies of a pair; Resonance doubles it.
static func team_bonus(a: String, b: String, resonance := false) -> float:
	if not is_team_pair(a, b):
		return 0.0
	return TEAM_BONUS * (2.0 if resonance else 1.0)
