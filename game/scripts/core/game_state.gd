class_name GameState
extends RefCounted
## The whole save game (rule 1: game state lives only in code). Plain
## dictionaries and arrays so it serializes to versioned JSON; Lingshou are
## party records with a unique id each (prepared for trading later).
##
##   GameState.current.add_lingshou("bambaer", 5)
##   GameState.current.save_game()

const VERSION := 2
const SAVE_PATH := "user://save_%d.json"
const START_BELLS := 2
const MAX_BELLS := 12
const START_COINS := 100
## Share of coins lost when the whole party is exhausted (GDD "Niederlage").
const DEFEAT_COIN_LOSS := 0.2

static var current: GameState

var player := {"name": "", "hair": 0, "outfit": 0}
var party: Array = []
## Lingshou living on the farm in Weidendorf (no free bell when they joined).
var farm: Array = []
var bells := START_BELLS
var coins := START_COINS
var items := {}
var flags := {}
var map := ""
var pos := Vector2.ZERO
## Where the player wakes up after a defeat: {"map", "spawn"}.
var inn := {"map": "weidendorf", "spawn": "home"}
var seen: Array = []
var play_seconds := 0.0
## Counters for the endings (GDD "Mehrere Enden").
var stats := {"battles": 0, "tamed": 0, "freed": 0, "defeated_silenced": 0, "calls": 0, "defeats": 0}
var next_uid := 1
## Random seed of this save: farm nights and weather are reproducible from it.
var seed := 0
## Game clock (GDD "Zeit"): day number and minute of the day (0..1439).
var day := 1
var minute := 18 * 60
## Weather per region for today: region id -> kind (see Weather).
var weather := {}
## The farm: building stage, pens ({"type"}), eggs ({"species", "parents", "nights"}).
var home := {"stage": 0, "pens": [{"type": "pond"}, {"type": "bamboo"}], "eggs": []}
## Dish eaten today: {"id", "effect", "day"} (GDD "Restaurant").
var buff := {}

## Region -> flag of the tone that frees it (GDD "Die Welt Yunhai").
const REGION_TONE := {"bamboo": "tone_jue", "river": "tone_yu", "ridge": "tone_zhi", "dunes": "tone_shang", "pillars": "tone_gong"}
const TONES: Array[String] = ["tone_jue", "tone_yu", "tone_zhi", "tone_shang", "tone_gong"]
## Bells on the wind chime by number of tones returned (GDD table).
const BELLS_BY_TONES: Array[int] = [3, 4, 6, 8, 10, 11]


static func new_game(player_name: String, hair := 0, outfit := 0) -> GameState:
	var s := GameState.new()
	s.player = {"name": player_name, "hair": hair, "outfit": outfit}
	s.items = {"reisbaellchen": 3, "bambussprossen": 2, "suessreis": 2}
	s.seed = randi()
	return s


# --- Lingshou ------------------------------------------------------------------

## Adds a Lingshou to the party, or to the farm when every bell is taken.
## Returns its record.
func add_lingshou(species_id: String, level: int, bond := 20) -> Dictionary:
	var u := BattleUnit.create(species_id, level, "ls%d" % next_uid)
	next_uid += 1
	u.bond = bond
	u.sex = "f" if hash([seed, u.uid]) % 2 == 0 else "m"
	var rec := u.to_record()
	if party.size() < bells:
		party.append(rec)
	else:
		farm.append(rec)
		Farm.auto_house(self, rec)
	mark_seen(species_id)
	return rec


func in_party(rec: Dictionary) -> bool:
	return party.has(rec)


func party_units() -> Array[BattleUnit]:
	var out: Array[BattleUnit] = []
	for rec in party:
		out.append(BattleUnit.from_record(rec))
	return out


## Party records as battle specs (side 0 of Battle.create).
func party_specs() -> Array:
	var out := []
	for rec in party:
		var spec: Dictionary = rec.duplicate(true)
		spec["id"] = rec["species"]
		out.append(spec)
	return out


## Writes HP, level, experience and bond back after a battle.
func sync_party(units: Array) -> void:
	for u in units:
		for i in party.size():
			if party[i]["uid"] == u.uid:
				party[i] = u.to_record()


func heal_party() -> void:
	for rec in party:
		var u := BattleUnit.from_record(rec)
		rec["hp"] = u.max_hp


func party_alive() -> bool:
	return party.any(func(r): return int(r["hp"]) > 0)


func swap_with_farm(party_index: int, farm_index: int) -> void:
	var a: Dictionary = party[party_index]
	party[party_index] = farm[farm_index]
	farm[farm_index] = a


func move_to_farm(party_index: int) -> void:
	if party.size() > 1:
		var rec: Dictionary = party[party_index]
		farm.append(rec)
		party.remove_at(party_index)
		Farm.auto_house(self, rec)


func move_to_party(farm_index: int) -> void:
	if party.size() < bells:
		var rec: Dictionary = farm[farm_index]
		rec["pen"] = -1
		party.append(rec)
		farm.remove_at(farm_index)


func mark_seen(species_id: String) -> void:
	if species_id not in seen:
		seen.append(species_id)


## Bond grows through battles together (GDD "Bindung").
func add_bond(uid: String, amount: int) -> void:
	for rec in party:
		if rec["uid"] == uid:
			rec["bond"] = clampi(int(rec["bond"]) + amount, 0, 100)


# --- items, coins, flags -------------------------------------------------------

func item_count(id: String) -> int:
	return int(items.get(id, 0))


func give_item(id: String, n := 1) -> void:
	items[id] = item_count(id) + n


func take_item(id: String, n := 1) -> bool:
	if item_count(id) < n:
		return false
	items[id] = item_count(id) - n
	if items[id] == 0:
		items.erase(id)
	return true


func buy(id: String, n := 1) -> bool:
	var price := int(GameData.item(id).get("price", 0)) * n
	if price <= 0 or coins < price:
		return false
	coins -= price
	give_item(id, n)
	return true


func flag(name: String, default: Variant = false) -> Variant:
	return flags.get(name, default)


func set_flag(name: String, value: Variant = true) -> void:
	flags[name] = value


## Wakes up at the last inn: party healed, part of the coins gone.
func apply_defeat() -> int:
	var lost := floori(coins * DEFEAT_COIN_LOSS)
	coins -= lost
	heal_party()
	stats["defeats"] = int(stats["defeats"]) + 1
	return lost


func count(stat: String, n := 1) -> void:
	stats[stat] = int(stats.get(stat, 0)) + n


func tones_count() -> int:
	var n := 0
	for t in TONES:
		if flag(t):
			n += 1
	return n


## A tone returns: flag, bells per the GDD table. Returns the new number of tones.
func return_tone(tone_flag: String) -> int:
	set_flag(tone_flag)
	var n := tones_count()
	bells = maxi(bells, BELLS_BY_TONES[mini(n, BELLS_BY_TONES.size() - 1)])
	while party.size() < bells and not farm.is_empty():
		move_to_party(0)
	if n >= 5:
		set_flag("five_tones")
	return n


## Is this region still under Wusheng's silence?
func region_silent(region: String) -> bool:
	if not flag("silence_fell"):
		return false
	if region == "temple":
		return not flag("phoenix_reborn")
	if REGION_TONE.has(region):
		return not flag(REGION_TONE[region]) or flag("bitter_" + region)
	return false


# --- clock, weather, sleep ------------------------------------------------------

func hour() -> int:
	return minute / 60


func is_night() -> bool:
	return minute >= 21 * 60 or minute < 5 * 60


func region_weather(region: String) -> String:
	if not weather.has(region):
		weather[region] = Weather.roll(region, seed, day)
	return weather[region]


## Ends the day: the farm night, a new morning with new weather, today's dish is gone.
## Returns the farm diary of the night.
func sleep() -> Array:
	var diary := Farm.daily(self)
	day += 1
	minute = 6 * 60 + 30
	weather.clear()
	buff = {}
	heal_party()
	return diary


func buff_effect() -> String:
	return String(buff.get("effect", "")) if int(buff.get("day", -1)) == day else ""


# --- save / load ---------------------------------------------------------------

func to_dict() -> Dictionary:
	return {"version": VERSION, "player": player, "party": party, "farm": farm, "bells": bells, "coins": coins,
		"items": items, "flags": flags, "map": map, "pos": [pos.x, pos.y], "inn": inn, "seen": seen,
		"play_seconds": play_seconds, "stats": stats, "next_uid": next_uid,
		"seed": seed, "day": day, "minute": minute, "weather": weather, "home": home, "buff": buff,
		"saved_at": Time.get_datetime_string_from_system()}


static func from_dict(d: Dictionary) -> GameState:
	var s := GameState.new()
	if int(d.get("version", 0)) > VERSION:
		push_warning("save from a newer version")
	s.player = d.get("player", s.player)
	s.party = d.get("party", [])
	s.farm = d.get("farm", [])
	s.bells = int(d.get("bells", START_BELLS))
	s.coins = int(d.get("coins", START_COINS))
	s.items = d.get("items", {})
	s.flags = d.get("flags", {})
	s.map = d.get("map", "")
	var p: Array = d.get("pos", [0, 0])
	s.pos = Vector2(float(p[0]), float(p[1]))
	s.inn = d.get("inn", s.inn)
	s.seen = d.get("seen", [])
	s.play_seconds = float(d.get("play_seconds", 0.0))
	s.stats.merge(d.get("stats", {}), true)
	s.next_uid = int(d.get("next_uid", 1))
	s.seed = int(d.get("seed", hash(s.player.get("name", ""))))
	s.day = int(d.get("day", 1))
	s.minute = int(d.get("minute", 18 * 60))
	s.weather = d.get("weather", {})
	s.home = d.get("home", s.home)
	for k in ["pens", "eggs"]:
		if not s.home.has(k):
			s.home[k] = [] if k == "eggs" else [{"type": "pond"}, {"type": "bamboo"}]
	s.home["stage"] = int(s.home.get("stage", 0))
	for egg in s.home["eggs"]:
		egg["nights"] = int(egg.get("nights", 0))
	s.buff = d.get("buff", {})
	if s.buff.has("day"):
		s.buff["day"] = int(s.buff["day"])
	# Version 1 (beta): farm Lingshou had no pen yet.
	for rec in s.farm:
		if not rec.has("pen"):
			Farm.auto_house(s, rec)
	# JSON numbers come back as floats; keep record fields integer.
	for list in [s.party, s.farm]:
		for rec in list:
			for k in ["level", "xp", "hp", "bond"]:
				rec[k] = int(rec.get(k, 0))
			for k in ["pen", "happy", "breed", "grow", "fed_day", "visit_day", "variant"]:
				if rec.has(k):
					rec[k] = int(rec[k])
	for k in s.items:
		s.items[k] = int(s.items[k])
	return s


func save_game(slot := 0) -> bool:
	var f := FileAccess.open(SAVE_PATH % slot, FileAccess.WRITE)
	if f == null:
		push_error("cannot write save: %s" % FileAccess.get_open_error())
		return false
	f.store_string(JSON.stringify(to_dict(), "\t"))
	return true


static func has_save(slot := 0) -> bool:
	return FileAccess.file_exists(SAVE_PATH % slot)


static func load_game(slot := 0) -> GameState:
	if not has_save(slot):
		return null
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(SAVE_PATH % slot)) != OK or not json.data is Dictionary:
		push_warning("save %d unreadable" % slot)
		return null
	return from_dict(json.data)


static func delete_save(slot := 0) -> void:
	if has_save(slot):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH % slot))
