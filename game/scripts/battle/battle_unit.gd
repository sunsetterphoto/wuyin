class_name BattleUnit
extends RefCounted
## One Lingshou as it exists in a battle: species data plus level, current HP,
## sound statuses and per-turn flags. Stats derive from base stats and level.

const MAX_LEVEL := 50
const BASIC_MOVE := "grundangriff"

var uid: String
var species: Dictionary
var level: int
var xp := 0
var bond := 0
var hp: int
var max_hp: int
var atk: int
var def: int
var spd: int
var moves: Array[String] = []
## status name -> {"turns": int, "applied_turn": int}
var statuses: Dictionary = {}
var shielded := false
var side := 0
## "" = regular opponent or own Lingshou, "wild" = can be tamed, "silenced" = can be freed.
var role := ""
## Wild: trust towards the player (0-100). Silenced: heart-sound bar (0-100).
var trust := 0
var heart := 0
## A freed silenced Lingshou leaves the fight (counts as out, but not exhausted).
var freed := false


static func create(species_id: String, lvl: int, unit_uid := "") -> BattleUnit:
	var u := BattleUnit.new()
	u.species = GameData.lingshou(species_id)
	u.uid = unit_uid if unit_uid != "" else species_id
	u.level = clampi(lvl, 1, MAX_LEVEL)
	for m in u.species["moves"]:
		u.moves.append(m)
	u.recalc_stats()
	u.hp = u.max_hp
	return u


## Rebuilds a unit from a saved party record (see GameState).
static func from_record(rec: Dictionary) -> BattleUnit:
	var u := create(rec["species"], int(rec.get("level", 1)), rec.get("uid", ""))
	u.xp = int(rec.get("xp", 0))
	u.bond = int(rec.get("bond", 0))
	if rec.has("moves"):
		u.moves.clear()
		for m in rec["moves"]:
			u.moves.append(m)
	u.hp = clampi(int(rec.get("hp", u.max_hp)), 0, u.max_hp)
	return u


func to_record() -> Dictionary:
	return {"uid": uid, "species": species["id"], "level": level, "xp": xp, "hp": hp, "bond": bond,
		"moves": moves.duplicate()}


static func stat_for(base: int, lvl: int) -> int:
	return maxi(1, floori(base * (0.6 + lvl * 0.06)))


static func hp_for(base: int, lvl: int) -> int:
	return floori(base * (1.0 + lvl * 0.12)) + 10


## Experience needed to go from `lvl` to `lvl + 1`.
static func xp_to_next(lvl: int) -> int:
	return 8 * lvl * lvl


## Experience gained for exhausting an opponent of level `lvl`.
static func xp_reward(lvl: int) -> int:
	return 20 * lvl + 40


func recalc_stats() -> void:
	var b: Dictionary = species["base_stats"]
	var old_max := max_hp
	max_hp = hp_for(int(b["hp"]), level)
	atk = stat_for(int(b["atk"]), level)
	def = stat_for(int(b["def"]), level)
	spd = stat_for(int(b["spd"]), level)
	if old_max > 0:
		hp = mini(max_hp, hp + max_hp - old_max)


## Adds experience and returns the number of levels gained.
func gain_xp(amount: int) -> int:
	var gained := 0
	xp += amount
	while level < MAX_LEVEL and xp >= xp_to_next(level):
		xp -= xp_to_next(level)
		level += 1
		gained += 1
	if gained > 0:
		recalc_stats()
	return gained


func element() -> String:
	return species["element"]


func name_key() -> String:
	return species["name"]


func is_alive() -> bool:
	return hp > 0 and not freed


func has_status(s: String) -> bool:
	return statuses.has(s)


## Moves the unit may pick from the menu right now. Silenced: only the basic attack.
func usable_moves() -> Array[String]:
	if has_status("silenced"):
		return [BASIC_MOVE]
	var out: Array[String] = moves.duplicate()
	if BASIC_MOVE not in out:
		out.append(BASIC_MOVE)
	return out


## Deaf units ignore calls (free-text commands); menu commands still work.
func accepts_calls() -> bool:
	return not has_status("deaf")
