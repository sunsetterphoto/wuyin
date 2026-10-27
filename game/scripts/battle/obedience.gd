class_name Obedience
extends RefCounted
## Rules for calls (free-text commands) that live only in code (rule 1):
## obedience roll from bond and temperament, situation bonus (capped), breath.

const SITUATION_BONUS_CAP := 0.15
const SITUATION_BONUS := 0.10
const BREATH_MAX := 3
const BREATH_REGEN_TURNS := 3

## Base chance before bond; bond 0..100 adds up to +0.45.
const BASE_CHANCE := 0.55
const MIN_CHANCE := 0.15


## Probability that `u` follows a call with this `stance` and move kind.
static func chance(u: BattleUnit, stance: String, move_kind: String, moody_shift := 0.0) -> float:
	var p := BASE_CHANCE + u.bond / 100.0 * 0.45
	for t in u.species.get("temperaments", []):
		match t:
			"brave":
				# Loves attacking, ignores orders to hold back.
				if stance in ["defensive", "protective"]:
					p -= 0.2
				elif move_kind == "attack":
					p += 0.1
			"anxious":
				if stance == "offensive":
					p -= 0.15
				else:
					p += 0.1
			"stubborn":
				# Only listens once the bond is high.
				p -= 0.3 * (1.0 - u.bond / 100.0)
			"gentle":
				if move_kind in ["heal", "guard"] or stance == "protective":
					p += 0.15
				elif move_kind == "attack":
					p -= 0.05
			"moody":
				p += moody_shift
			"playful":
				pass
	return clampf(p, MIN_CHANCE, 1.0)


## Per-battle mood for moody Lingshou, -0.2..+0.2.
static func roll_mood(rng: RandomNumberGenerator) -> float:
	return rng.randf_range(-0.2, 0.2)


## Situation bonus checked against real battle facts. The model's
## `fits_situation` only opens the door; the code decides (max 15 %).
static func situation_bonus(battle: Battle, u: BattleUnit, mv: Dictionary, target: BattleUnit,
		stance: String, model_says_fits: bool) -> float:
	if not model_says_fits or target == null:
		return 0.0
	var bonus := 0.0
	match mv["kind"]:
		"attack":
			if WuXing.effectiveness(mv["element"], target.element()) > 1.0:
				bonus += SITUATION_BONUS
			if float(target.hp) / target.max_hp < 0.35 and stance == "offensive":
				bonus += 0.05
		"heal":
			if float(target.hp) / target.max_hp < 0.5:
				bonus += SITUATION_BONUS
		"guard":
			if target != u and float(target.hp) / target.max_hp < 0.5 and stance == "protective":
				bonus += SITUATION_BONUS
		"status":
			var st = mv.get("effect", {}).get("status", "")
			if target.side != u.side and not target.has_status(st):
				bonus += 0.05
	return minf(bonus, SITUATION_BONUS_CAP)
