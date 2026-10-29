extends SceneTree
## Checks the persuasion categories of the model (and the keyword fallback) on sample sentences.
##   godot --headless --path game -s res://tests/tools/persuade_eval.gd
const CASES := [
	["Wenn das Wasser stillsteht, sterben die Fische und die Fischer hungern.", "logic"],
	["Ich weiß, wie sehr du deinen Mann vermisst. Mir fehlt auch jemand.", "compassion"],
	["Hör doch, der Bambus rauscht wieder – ich habe den Drachen befreit!", "proof"],
	["Ich gebe dir 100 Münzen, wenn du mich vorbeilässt.", "bribe"],
	["Geh weg oder ich schubse dich in den Fluss!", "threat"],
	["If the river stays still, no boat can ever sail again.", "logic"],
	["I understand you're scared. I'm scared of goodbyes too.", "compassion"],
	["Look at the colours coming back - the dragon sings again.", "proof"],
	["Here, take these coins and let me through.", "bribe"],
	["Move, or you'll regret it!", "threat"],
	["Schöner Tag heute, oder?", "neutral"],
	["我知道你害怕离别，我也一样。", "compassion"],
]

func _initialize():
	_run.call_deferred()

func _run():
	var model_ok := 0
	var kw_ok := 0
	for c in CASES:
		var r: Dictionary = await Persuader.judge(c[0])
		var kw := Persuader.from_keywords(c[0])
		model_ok += 1 if r["category"] == c[1] else 0
		kw_ok += 1 if kw == c[1] else 0
		print("%-10s model=%-10s (%s %d ms) keywords=%-10s  %s" % [c[1], r["category"], r["source"], r["ms"], kw, c[0]])
	print("PERSUADE model %d/%d  keywords %d/%d" % [model_ok, CASES.size(), kw_ok, CASES.size()])
	quit()
