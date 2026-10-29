class_name BattleUnit
extends RefCounted
## One Lingshou as it exists in a battle: species data plus level, current HP,
## sound statuses and per-turn flags. Stats derive from base stats and level.

const MAX_LEVEL := 50
const BASIC_MOVE := "grundangriff"
const AWAKENED_BOOST := 1.12
## Wandlung: from this bond and level on, at a wind chime shrine.
const AWAKEN_BOND := 70
const AWAKEN_LEVEL := 20


static func can_awaken(rec: Dictionary) -> bool:
	var sp := GameData.lingshou(rec["species"])
	return not rec.get("awakened", false) and int(rec.get("bond", 0)) >= AWAKEN_BOND and int(rec.get("level", 1)) >= AWAKEN_LEVEL \
		and not sp.get("guardian", false) and sp["alignment"] != "nian" and rec.get("stage", "adult") == "adult"

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
## Every move this Lingshou knows; `moves` are the (up to four) active ones.
var known: Array[String] = []
## Bred Lingshou vary a little around their species (added to the base stats).
var iv := {}
var sex := ""
## 0 = normal colours, 1 = rare colour variant (breeding).
var variant := 0
## "adult" or "young" (hatched on the farm, grows up after a few days).
var stage := "adult"
## Moves learned by the last gain_xp() call (for the battle log).
var learned_new: Array[String] = []
## Changed into its stronger form (GDD "Wandlung"): a little stronger, glows in its element.
var awakened := false
## Nian only: how often it was frightened by drums, firecrackers or red banners.
var fear := 0
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
	u.known = u.moves.duplicate()
	for lv in u.species.get("learn", {}):
		var mv: String = u.species["learn"][lv]
		if int(lv) <= u.level and mv not in u.known:
			u.known.append(mv)
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
	for m in rec.get("known", []):
		if m not in u.known:
			u.known.append(m)
	for m in u.moves:
		if m not in u.known:
			u.known.append(m)
	if rec.has("temperament") and rec["temperament"] != u.species["temperaments"][0]:
		# Bred individuals may differ from their species; keep the shared data untouched.
		u.species = u.species.duplicate()
		u.species["temperaments"] = [rec["temperament"]]
	u.iv = rec.get("iv", {})
	u.sex = rec.get("sex", "")
	u.variant = int(rec.get("variant", 0))
	u.stage = rec.get("stage", "adult")
	u.awakened = bool(rec.get("awakened", false))
	if not u.iv.is_empty() or u.awakened:
		u.recalc_stats()
		u.hp = u.max_hp
	u.hp = clampi(int(rec.get("hp", u.max_hp)), 0, u.max_hp)
	return u


func to_record() -> Dictionary:
	var rec := {"uid": uid, "species": species["id"], "level": level, "xp": xp, "hp": hp, "bond": bond,
		"moves": moves.duplicate(), "known": known.duplicate()}
	if not iv.is_empty():
		rec["iv"] = iv
	if sex != "":
		rec["sex"] = sex
	if variant != 0:
		rec["variant"] = variant
	if stage != "adult":
		rec["stage"] = stage
	if awakened:
		rec["awakened"] = true
	if species["temperaments"][0] != GameData.lingshou(species["id"])["temperaments"][0]:
		rec["temperament"] = species["temperaments"][0]
	return rec


static func stat_for(base: int, lvl: int) -> int:
	return maxi(1, floori(base * (0.6 + lvl * 0.06)))


static func hp_for(base: int, lvl: int) -> int:
	return floori(base * (1.0 + lvl * 0.12)) + 10


## Experience needed to go from `lvl` to `lvl + 1`: quadratic in the first
## chapter, then linear so the long middle game needs a steady 3-4 battles per level.
static func xp_to_next(lvl: int) -> int:
	return 8 * lvl * lvl if lvl < 10 else 70 * lvl


## Experience gained for exhausting an opponent of level `lvl`.
static func xp_reward(lvl: int) -> int:
	return 20 * lvl + 40


func recalc_stats() -> void:
	var b: Dictionary = species["base_stats"]
	var old_max := max_hp
	max_hp = hp_for(int(b["hp"]) + int(iv.get("hp", 0)), level)
	atk = stat_for(int(b["atk"]) + int(iv.get("atk", 0)), level)
	def = stat_for(int(b["def"]) + int(iv.get("def", 0)), level)
	spd = stat_for(int(b["spd"]) + int(iv.get("spd", 0)), level)
	if awakened:
		max_hp = roundi(max_hp * AWAKENED_BOOST)
		atk = roundi(atk * AWAKENED_BOOST)
		def = roundi(def * AWAKENED_BOOST)
		spd = roundi(spd * AWAKENED_BOOST)
	if old_max > 0:
		hp = mini(max_hp, hp + max_hp - old_max)


## Adds experience and returns the number of levels gained.
func gain_xp(amount: int) -> int:
	var gained := 0
	learned_new.clear()
	xp += amount
	while level < MAX_LEVEL and xp >= xp_to_next(level):
		xp -= xp_to_next(level)
		level += 1
		gained += 1
		var mv: String = species.get("learn", {}).get(str(level), "")
		if mv != "" and mv not in known:
			known.append(mv)
			learned_new.append(mv)
			if moves.size() < GameData.MAX_MOVES:
				moves.append(mv)
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
