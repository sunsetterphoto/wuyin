class_name Farm
extends RefCounted
## The farm in Willowdale (GDD "Heimat: Hof, Gehege und Zucht"): building
## stages, pens by element, contentment and breeding. Pure logic on the
## GameState; every random roll comes from an RNG seeded with the save's seed
## and the game day, so the same save sleeps into the same night (rule 6).
##
##   Farm.assign(state, farm_index, pen_index)
##   var diary := Farm.daily(state)   # once per night, when the player sleeps

const BREEDING_PATH := "res://data/farm/breeding.json"
const PEN_SIZE := 2
const PEN_TYPES: Array[String] = ["pond", "bamboo", "ember", "ore", "rock"]
const PEN_ELEMENT := {"pond": "water", "bamboo": "wood", "ember": "fire", "ore": "metal", "rock": "earth"}
## Building stages: pens, cost and what unlocks them (tones returned or a flag).
const STAGES: Array[Dictionary] = [
	{"key": "FARM_STAGE_0", "pens": 2},
	{"key": "FARM_STAGE_1", "pens": 4, "coins": 300, "mats": {"bambus": 4}, "flag": "prologue_done"},
	{"key": "FARM_STAGE_2", "pens": 8, "coins": 800, "mats": {"flusskiesel": 3, "danxia_ton": 3}, "tones": 3},
	{"key": "FARM_STAGE_3", "pens": 12, "coins": 1500, "mats": {"wuestenkupfer": 3, "wolkenjade": 3}, "tones": 5},
	{"key": "FARM_STAGE_4", "pens": 16, "coins": 3000, "mats": {"wolkenjade": 4}, "flag": "phoenix_reborn"},
]
const START_HAPPY := 50
const MIN_HAPPY := 20
const BREED_HAPPY := 60
## Nights a happy pair needs for an egg, nights until it hatches, nights until the young is grown.
const BREED_NIGHTS := 2
const HATCH_NIGHTS := 2
const GROW_NIGHTS := 3
const NEW_TEMPERAMENT_CHANCE := 0.1
const VARIANT_CHANCE := 1.0 / 24.0
const IV_SPREAD := 3
const PEN_COST := 120

static var _hybrids := {}


static func hybrid_for(element: String) -> String:
	if _hybrids.is_empty():
		var d = JSON.parse_string(FileAccess.get_file_as_string(BREEDING_PATH))
		_hybrids = d.get("hybrids", {}) if d is Dictionary else {}
	return _hybrids.get(element, "")


# --- stages and pens -------------------------------------------------------------

static func stage(state: GameState) -> int:
	return int(state.home.get("stage", 0))


static func pen_count(state: GameState) -> int:
	return state.home["pens"].size()


## Pens the current stage allows (built or not).
static func pen_slots(state: GameState) -> int:
	return int(STAGES[stage(state)]["pens"])


## "" when the next stage can be built now, otherwise a translation key with the reason.
static func upgrade_block(state: GameState) -> String:
	var next := stage(state) + 1
	if next >= STAGES.size():
		return "FARM_MAX"
	var st: Dictionary = STAGES[next]
	if st.has("flag") and not state.flag(st["flag"]):
		return "FARM_NOT_YET"
	if st.has("tones") and state.tones_count() < int(st["tones"]):
		return "FARM_NOT_YET"
	if state.coins < int(st.get("coins", 0)):
		return "SHOP_NO_MONEY"
	for m in st.get("mats", {}):
		if state.item_count(m) < int(st["mats"][m]):
			return "FARM_NO_MATERIAL"
	return ""


static func upgrade(state: GameState) -> bool:
	if upgrade_block(state) != "":
		return false
	var st: Dictionary = STAGES[stage(state) + 1]
	state.coins -= int(st.get("coins", 0))
	for m in st.get("mats", {}):
		state.take_item(m, int(st["mats"][m]))
	state.home["stage"] = stage(state) + 1
	return true


## Builds a new pen of a type (needs a free slot of the current stage).
static func build_pen(state: GameState, type: String) -> bool:
	if type not in PEN_TYPES or pen_count(state) >= pen_slots(state) or state.coins < PEN_COST:
		return false
	state.coins -= PEN_COST
	state.home["pens"].append({"type": type})
	return true


static func set_pen_type(state: GameState, pen: int, type: String) -> void:
	if type in PEN_TYPES and pen < pen_count(state):
		state.home["pens"][pen]["type"] = type


static func residents(state: GameState, pen: int) -> Array:
	return state.farm.filter(func(r): return int(r.get("pen", -1)) == pen)


static func unhoused(state: GameState) -> Array:
	return state.farm.filter(func(r): return int(r.get("pen", -1)) < 0)


## Moves a farm Lingshou into a pen (or out with pen = -1).
static func assign(state: GameState, farm_index: int, pen: int) -> bool:
	if farm_index < 0 or farm_index >= state.farm.size():
		return false
	if pen >= 0 and (pen >= pen_count(state) or residents(state, pen).size() >= PEN_SIZE):
		return false
	state.farm[farm_index]["pen"] = pen
	state.farm[farm_index]["breed"] = 0
	return true


## A newcomer moves into the best free pen: matching element first.
static func auto_house(state: GameState, rec: Dictionary) -> void:
	var el: String = GameData.lingshou(rec["species"])["element"]
	var best := -1
	for i in pen_count(state):
		if residents(state, i).size() >= PEN_SIZE:
			continue
		if PEN_ELEMENT.get(state.home["pens"][i]["type"], "") == el:
			best = i
			break
		if best < 0:
			best = i
	rec["pen"] = best
	rec["happy"] = int(rec.get("happy", START_HAPPY))


static func fits_pen(state: GameState, rec: Dictionary) -> bool:
	var pen := int(rec.get("pen", -1))
	if pen < 0 or pen >= pen_count(state):
		return false
	return PEN_ELEMENT.get(state.home["pens"][pen]["type"], "") == GameData.lingshou(rec["species"])["element"]


# --- care ------------------------------------------------------------------------

## Feeding on the farm: liked food helps more; each Lingshou is hungry once a day.
static func feed(state: GameState, rec: Dictionary, item: String) -> int:
	var it := GameData.item(item)
	if it.get("kind") != "food" or not state.take_item(item):
		return 0
	var amount := 25 if GameData.lingshou(rec["species"])["element"] in it.get("likes", []) else 12
	if int(rec.get("fed_day", -1)) == state.day:
		amount /= 3
	rec["fed_day"] = state.day
	rec["happy"] = clampi(int(rec.get("happy", START_HAPPY)) + amount, 0, 100)
	return amount


## A visit to the pen (talking to the sign) cheers everyone up a little, once a day.
static func visit(state: GameState, pen: int) -> void:
	for rec in residents(state, pen):
		if int(rec.get("visit_day", -1)) != state.day:
			rec["visit_day"] = state.day
			rec["happy"] = clampi(int(rec.get("happy", START_HAPPY)) + 4, 0, 100)


## Can these two have an egg together? Same species or same element, one of each sex, not unique.
static func compatible(a: Dictionary, b: Dictionary) -> bool:
	var sa := GameData.lingshou(a["species"])
	var sb := GameData.lingshou(b["species"])
	if not sa.get("can_breed", true) or not sb.get("can_breed", true):
		return false
	if a.get("stage", "adult") != "adult" or b.get("stage", "adult") != "adult":
		return false
	if a.get("sex", "") == b.get("sex", "") or a.get("sex", "") == "" or b.get("sex", "") == "":
		return false
	return a["species"] == b["species"] or sa["element"] == sb["element"]


## The species of the young: the parents' species, or the hybrid of their element.
static func child_species(a: Dictionary, b: Dictionary) -> String:
	if a["species"] == b["species"]:
		return a["species"]
	var h := hybrid_for(GameData.lingshou(a["species"])["element"])
	return h if h != "" and GameData.lingshou_ids().has(h) else a["species"]


# --- feed garden (GDD "Hofarbeit") ------------------------------------------------

const GARDEN_STAGE := 2
const GARDEN_NIGHTS := 2
const GARDEN_CROPS: Array[String] = ["bambussprossen", "suessreis", "silbertau", "flussmuscheln", "chilischoten", "wuestendatteln", "wolkenbeeren"]


static func garden_open(state: GameState) -> bool:
	return stage(state) >= GARDEN_STAGE


## Plants a crop; it can be harvested after GARDEN_NIGHTS nights.
static func plant(state: GameState, crop: String) -> bool:
	if not garden_open(state) or crop not in GARDEN_CROPS or state.home.has("garden"):
		return false
	state.home["garden"] = {"crop": crop, "nights": 0}
	return true


static func garden_ready(state: GameState) -> bool:
	return state.home.has("garden") and int(state.home["garden"]["nights"]) >= GARDEN_NIGHTS


## Harvest: 3 of the crop, +1 for each water and wood Lingshou on the farm helping (watering, growing), at most 6.
static func harvest(state: GameState) -> int:
	if not garden_ready(state):
		return 0
	var helpers := state.farm.filter(func(r): return GameData.lingshou(r["species"])["element"] in ["water", "wood"]).size()
	var n := mini(6, 3 + helpers)
	state.give_item(state.home["garden"]["crop"], n)
	state.home.erase("garden")
	return n


# --- the night -------------------------------------------------------------------

## Advances the farm by one night. Returns diary entries (dictionaries with "type").
static func daily(state: GameState) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([state.seed, state.day, "farm"])
	var diary := []
	if state.home.has("garden"):
		state.home["garden"]["nights"] = int(state.home["garden"]["nights"]) + 1
		if int(state.home["garden"]["nights"]) == GARDEN_NIGHTS:
			diary.append({"type": "garden"})
	# Young ones grow, eggs hatch.
	for rec in state.farm:
		if rec.get("stage", "adult") == "young":
			rec["grow"] = int(rec.get("grow", 0)) + 1
			if int(rec["grow"]) >= GROW_NIGHTS:
				rec.erase("stage")
				rec.erase("grow")
				diary.append({"type": "grown", "a": rec["species"]})
	for egg in state.home["eggs"].duplicate():
		egg["nights"] = int(egg["nights"]) + 1
		if int(egg["nights"]) >= HATCH_NIGHTS:
			state.home["eggs"].erase(egg)
			var rec := _hatch(state, egg, rng)
			diary.append({"type": "hatched", "a": rec["species"], "variant": int(rec.get("variant", 0))})
	# Contentment.
	for rec in state.farm:
		var happy := int(rec.get("happy", START_HAPPY))
		if int(rec.get("pen", -1)) < 0:
			happy -= 6
		elif fits_pen(state, rec):
			happy += 5
		else:
			happy -= 6
		for other in residents(state, int(rec.get("pen", -1))):
			if other != rec and int(rec.get("pen", -1)) >= 0 and \
					GameData.lingshou(other["species"])["element"] == GameData.lingshou(rec["species"])["element"]:
				happy += 3
		rec["happy"] = clampi(happy, MIN_HAPPY, 100)
	# Pairs.
	for pen in pen_count(state):
		var r := residents(state, pen)
		if r.size() == 2:
			var a: Dictionary = r[0]
			var b: Dictionary = r[1]
			if rng.randf() < 0.5:
				diary.append({"type": "chat", "a": a["species"], "b": b["species"], "pen": pen})
			if compatible(a, b) and int(a["happy"]) >= BREED_HAPPY and int(b["happy"]) >= BREED_HAPPY:
				a["breed"] = int(a.get("breed", 0)) + 1
				if int(a["breed"]) >= BREED_NIGHTS:
					a["breed"] = 0
					var egg := {"species": child_species(a, b), "parents": [a["uid"], b["uid"]], "nights": 0}
					state.home["eggs"].append(egg)
					diary.append({"type": "egg", "a": a["species"], "b": b["species"], "child": egg["species"]})
			else:
				a["breed"] = 0
		elif r.size() == 1 and rng.randf() < 0.3:
			diary.append({"type": "alone", "a": r[0]["species"]})
	return diary


static func _parent(state: GameState, uid: String) -> Dictionary:
	for list in [state.farm, state.party]:
		for rec in list:
			if rec["uid"] == uid:
				return rec
	return {}


static func _hatch(state: GameState, egg: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	var pa := _parent(state, egg["parents"][0])
	var pb := _parent(state, egg["parents"][1])
	var sp := GameData.lingshou(egg["species"])
	var u := BattleUnit.create(egg["species"], 3, "ls%d" % state.next_uid)
	state.next_uid += 1
	u.sex = "f" if rng.randf() < 0.5 else "m"
	u.stage = "young"
	u.bond = 40
	# Stats: around the parents' average, a little spread.
	for stat in GameData.STATS:
		var avg := (int(pa.get("iv", {}).get(stat, 0)) + int(pb.get("iv", {}).get(stat, 0))) / 2.0
		u.iv[stat] = clampi(roundi(avg) + rng.randi_range(-1, IV_SPREAD - 1), -IV_SPREAD, IV_SPREAD * 2)
	if rng.randf() < VARIANT_CHANCE:
		u.variant = 1
	u.recalc_stats()
	u.hp = u.max_hp
	var rec := u.to_record()
	# Temperament from a parent, rarely a new one (stored per individual).
	var temps: Array = []
	for p in [pa, pb]:
		if not p.is_empty():
			temps.append(p.get("temperament", GameData.lingshou(p["species"])["temperaments"][0]))
	if temps.is_empty() or rng.randf() < NEW_TEMPERAMENT_CHANCE:
		temps = GameData.TEMPERAMENTS
	rec["temperament"] = temps[rng.randi_range(0, temps.size() - 1)]
	rec["parents"] = egg["parents"]
	rec["grow"] = 0
	rec["happy"] = 70
	state.farm.append(rec)
	auto_house(state, rec)
	state.mark_seen(sp["id"])
	state.count("hatched")
	return rec
