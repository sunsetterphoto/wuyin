extends Node
## Dev only: starts the world at a story point for device tests.
##   adb shell run-as com.wuyin.game sh -c 'echo river > files/dev_jump.txt; echo res://scenes/dev/beta_jump.tscn > files/dev_autorun.txt'
## Stages: river (shy Lingshou), bamboo (after the prologue), terraces, shrine.

const STAGES := {
	"river": {"map": "flussufer", "spawn": "from_village", "flags": ["intro_done", "jinli_follows", "has_fengling", "silence_fell"], "party": []},
	"bamboo": {"map": "bambuspfad", "spawn": "from_village", "flags": ["intro_done", "jinli_follows", "has_fengling", "silence_fell",
		"river_arrived", "prologue_tamed", "voice_taken", "prologue_done", "yao_battle1"], "party": [["wawalurch", 5], ["nebelaffe", 5]], "bells": 3},
	"terraces": {"map": "reisterrassen", "spawn": "from_town", "flags": ["intro_done", "jinli_follows", "has_fengling", "silence_fell",
		"river_arrived", "prologue_tamed", "voice_taken", "prologue_done", "yao_battle1", "yao_battle2", "teeufer_arrived"],
		"party": [["wawalurch", 8], ["nebelaffe", 9], ["jadelibelle", 8]], "bells": 3},
	"shrine": {"map": "drachenschrein", "spawn": "from_terraces", "flags": ["intro_done", "jinli_follows", "has_fengling", "silence_fell",
		"river_arrived", "prologue_tamed", "voice_taken", "prologue_done", "yao_battle1", "yao_battle2", "teeufer_arrived",
		"terraces_arrived", "gone_silent_leopard"], "party": [["wawalurch", 10], ["nebelaffe", 11], ["firnleopard", 10]], "bells": 3},
}


func _ready() -> void:
	var stage := "river"
	var event := ""
	if FileAccess.file_exists("user://dev_jump.txt"):
		var parts := FileAccess.get_file_as_string("user://dev_jump.txt").strip_edges().split(" ")
		stage = parts[0]
		event = parts[1] if parts.size() > 1 else ""
		DirAccess.remove_absolute("user://dev_jump.txt")
	var cfg: Dictionary = STAGES.get(stage, STAGES["river"])
	if stage.begins_with("map="):
		# Any map later in the game: the journey so far is done, arrival scenes are skipped.
		var flags: Array = STAGES["shrine"]["flags"].duplicate()
		flags.append_array(["tone_jue", "lesson_bamboo", "nian_driven", "three_tones", "meister_spoke", "order_left", "has_boat"])
		for id in MapData.all_ids():
			flags.append(id + "_arrived")
		for f in ["kreuzweg", "karstufer", "nebelhafen", "bucht", "danxiapfad", "rotfels", "gipfel", "duenenweg", "mondquell", "kamm",
				"saeulenpfad", "kiefernhang", "plateau", "temple", "hof"]:
			flags.append(f + "_arrived")
		var target := stage.trim_prefix("map=")
		cfg = {"map": target, "spawn": MapData.load_map(target).def.get("spawns", {}).keys()[0], "flags": flags,
			"party": [["wawalurch", 20], ["glutpanda", 20], ["firnleopard", 20], ["perlkormoran", 20]], "bells": 6}
	var s := GameState.new_game("Test")
	for f in cfg["flags"]:
		s.set_flag(f)
	s.bells = int(cfg.get("bells", 2))
	for p in cfg["party"]:
		s.add_lingshou(p[0], p[1])
	s.map = cfg["map"]
	var m := MapData.load_map(cfg["map"])
	s.pos = m.spawn(cfg["spawn"])
	s.give_item("kraeutertee", 2)
	if event != "":
		s.set_flag("_dev_event", event)
		s.set_flag("river_arrived")
	GameState.current = s
	get_tree().change_scene_to_file.call_deferred("res://scenes/world/world.tscn")
