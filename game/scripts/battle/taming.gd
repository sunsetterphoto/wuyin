class_name Taming
extends RefCounted
## Taming instead of catching (GDD "Zähmen statt Fangen"): wild Lingshou gain
## trust from calming, food and fitting words; silenced ones fill the
## heart-sound bar (Herzklang) from words and from the damage that wears their
## resistance down. The model only names the tone of a sentence; every number
## here is code (rule 1).

const TRUST_FULL := 100
const HEART_FULL := 100
const START_TRUST := 10
## From this trust on, a wild Lingshou stops attacking and just watches.
const CALM_TRUST := 60
## Trust lost when the player's side hits a wild Lingshou.
const HIT_PENALTY := 8
## Mercy: extra trust for befriending a Lingshou that is already weakened.
const SPARE_BONUS := 5
## Heart gained per full max HP of damage dealt to a silenced Lingshou.
const HEART_PER_DAMAGE := 60.0
## Sky guardians resist: everything that fills their heart counts half.
const GUARDIAN_FACTOR := 0.5

const TONES: Array[String] = ["soothing", "encouraging", "playful", "respectful", "praising", "rude", "neutral"]

## Trust per tone and temperament (rows: temperament).
const TALK := {
	"anxious": {"soothing": 30, "encouraging": 10, "playful": 5, "respectful": 15, "praising": 20, "rude": -20, "neutral": 5},
	"brave": {"soothing": 5, "encouraging": 30, "playful": 10, "respectful": 10, "praising": 20, "rude": -10, "neutral": 5},
	"stubborn": {"soothing": 5, "encouraging": 10, "playful": 0, "respectful": 30, "praising": 5, "rude": -15, "neutral": 5},
	"playful": {"soothing": 5, "encouraging": 15, "playful": 30, "respectful": 5, "praising": 15, "rude": -10, "neutral": 5},
	"gentle": {"soothing": 25, "encouraging": 10, "playful": 10, "respectful": 20, "praising": 15, "rude": -25, "neutral": 5},
	"moody": {"soothing": 10, "encouraging": 10, "playful": 20, "respectful": 10, "praising": 25, "rude": -15, "neutral": 5},
}
const CALM := {"anxious": 20, "brave": 5, "stubborn": 5, "playful": 10, "gentle": 15, "moody": 10}
## Heart gained per tone for silenced Lingshou (their temperament is buried).
const HEART_TALK := {"soothing": 25, "encouraging": 15, "playful": 10, "respectful": 20, "praising": 15, "rude": 0, "neutral": 5}
const HEART_CALM := 15
const FEED_LIKED := 25
const FEED_OTHER := 10


static func temperament(u: BattleUnit) -> String:
	return u.species.get("temperaments", ["gentle"])[0]


static func is_tameable(u: BattleUnit) -> bool:
	return u.role == "wild"


static func is_silenced(u: BattleUnit) -> bool:
	return u.role == "silenced"


## Trust (wild) or heart (silenced) gained from one befriending act.
## act: "calm" | "feed" | "talk"; item for feed; tone for talk.
## moody_shift: the battle's mood roll for moody Lingshou (-0.2..0.2).
static func gain(u: BattleUnit, act: String, item := "", tone := "neutral", moody_shift := 0.0) -> int:
	var t := temperament(u)
	var amount := 0
	if is_silenced(u):
		match act:
			"calm":
				amount = HEART_CALM
			"talk":
				amount = int(HEART_TALK.get(tone, 5))
		if u.species.get("guardian", false):
			amount = roundi(amount * GUARDIAN_FACTOR)
		return amount
	match act:
		"calm":
			amount = int(CALM.get(t, 10))
		"feed":
			var it := GameData.item(item)
			amount = FEED_LIKED if u.element() in it.get("likes", []) else FEED_OTHER
		"talk":
			amount = int(TALK.get(t, TALK["gentle"]).get(tone, 5))
	if t == "moody":
		amount = roundi(amount * (1.0 + moody_shift * 2.0))
	if amount > 0 and float(u.hp) / u.max_hp < 0.5:
		amount += SPARE_BONUS
	return amount


## Heart gained from `damage` dealt to a silenced Lingshou.
static func heart_from_damage(u: BattleUnit, damage: int) -> int:
	var amount := roundi(HEART_PER_DAMAGE * damage / float(maxi(1, u.max_hp)))
	if u.species.get("guardian", false):
		amount = roundi(amount * GUARDIAN_FACTOR)
	return amount


## Bond a freshly tamed Lingshou starts with.
static func starting_bond(trust: int) -> int:
	return clampi(15 + (trust - TRUST_FULL) / 2, 15, 35)
