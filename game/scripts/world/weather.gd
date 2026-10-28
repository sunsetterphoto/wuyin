class_name Weather
extends RefCounted
## Weather per region and game day (GDD "Wetter"): rolled from the save seed,
## so it is the same when a save is loaded again. Silent regions have no
## weather at all - even the wind is gone.

const KINDS: Array[String] = ["sun", "cloudy", "rain", "storm", "fog", "snow", "sandstorm"]
## Weights per region.
const TABLE := {
	"bamboo": {"sun": 45, "cloudy": 20, "rain": 25, "fog": 7, "storm": 3},
	"hub": {"sun": 45, "cloudy": 25, "rain": 20, "fog": 10},
	"river": {"fog": 35, "rain": 25, "cloudy": 20, "sun": 15, "storm": 5},
	"ridge": {"sun": 60, "cloudy": 15, "storm": 15, "fog": 10},
	"dunes": {"sun": 60, "sandstorm": 30, "cloudy": 10},
	"pillars": {"fog": 30, "sun": 30, "snow": 25, "cloudy": 10, "storm": 5},
	"temple": {"sun": 100},
}
const ICON := {"sun": "☀", "cloudy": "☁", "rain": "☂", "storm": "⚡", "fog": "≋", "snow": "❄", "sandstorm": "≈", "": ""}


static func roll(region: String, seed_value: int, day: int) -> String:
	var table: Dictionary = TABLE.get(region, TABLE["bamboo"])
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([seed_value, day, region])
	var total := 0
	for k in table:
		total += int(table[k])
	var r := rng.randi_range(1, total)
	for k in table:
		r -= int(table[k])
		if r <= 0:
			return k
	return "sun"


## Weather that counts right now on a map (empty indoors, at night only the sky stays dark).
static func current(state: GameState, map: MapData) -> String:
	var region: String = map.def.get("region", "bamboo")
	if map.def.get("indoor", false) or state.region_silent(region) or not state.flag("prologue_done"):
		return ""
	return state.region_weather(region)


static func icon(kind: String) -> String:
	return ICON.get(kind, "")


static func name_key(kind: String) -> String:
	return "WEATHER_" + kind.to_upper()
