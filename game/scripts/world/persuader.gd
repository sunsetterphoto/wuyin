class_name Persuader
extends RefCounted
## "Reden außerhalb von Kämpfen" (GDD): the player tries to talk a guard,
## trader or member of the Order round. The model only names the category of
## the sentence (grammar-forced, one word); whether it works is decided by the
## event's data and the game state (rule 1). Without a model, keyword lists
## from data/llm/persuade_keywords.json decide.

const KEYWORDS_PATH := "res://data/llm/persuade_keywords.json"
const CATEGORIES: Array[String] = ["logic", "compassion", "threat", "bribe", "proof", "neutral"]

static var _keywords := {}

const RULES := """You sort one sentence a player says to convince someone in a family-friendly fantasy game. The sentence may be German, English or Chinese.
Categories:
logic = reasons, consequences, arguments ("If the river stays still, the fish die", "Denk doch nach")
compassion = empathy, feelings, kindness, shared loss ("I know you are afraid", "Ich verstehe deinen Schmerz")
threat = threats, force, insults ("Move or else!", "Geh weg, sonst...")
bribe = offering money or gifts ("I'll pay you", "Hier, nimm die Münzen")
proof = pointing to something that happened or was seen ("The dragon sings again, I freed it", "Schau, das Windspiel klingt")
neutral = none of these
Answer with one line: category=<category>"""


static func grammar() -> String:
	return 'root ::= "category=" cat\ncat ::= ' + " | ".join(CATEGORIES.map(func(c): return "\"%s\"" % c))


## Returns {"category", "source": "model"|"template", "ms"}.
static func judge(text: String, service: LlmService = null) -> Dictionary:
	service = service if service else LlmService.instance()
	var job := service.ask("persuade_judge", [{"role": "system", "content": RULES}, {"role": "user", "content": "Sentence: " + text}],
		{}, grammar(), "persuade")
	var r := await job.wait()
	if r["ok"]:
		var c := String(r["text"]).strip_edges().trim_prefix("category=").strip_edges()
		if c in CATEGORIES:
			return {"category": c, "source": "model", "ms": r["total_ms"]}
	return {"category": from_keywords(text), "source": "template", "ms": r["total_ms"]}


static func from_keywords(text: String) -> String:
	if _keywords.is_empty():
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(KEYWORDS_PATH))
		_keywords = parsed if parsed is Dictionary else {}
	var lower := text.to_lower()
	var best := "neutral"
	var best_hits := 0
	for cat in ["threat", "bribe", "proof", "compassion", "logic"]:
		var hits := 0
		for w in _keywords.get(cat, []):
			if String(w) in lower:
				hits += 1
		if hits > best_hits or (cat == "threat" and hits > 0):
			best = cat
			best_hits = hits
			if cat == "threat":
				return best
	return best


## Points a category earns against this person (spec from the event):
##   "accept": {category: points}, "proof_flags": [flags that make proof real], "bribe": coins
static func points(spec: Dictionary, category: String, state: GameState) -> int:
	var accept: Dictionary = spec.get("accept", {})
	match category:
		"proof":
			var real := false
			for f in spec.get("proof_flags", []):
				real = real or bool(state.flag(f))
			return int(accept.get("proof", 0)) if real else 0
		"bribe":
			var price := int(spec.get("bribe", 0))
			if price <= 0 or state.coins < price or int(accept.get("bribe", 0)) <= 0:
				return 0
			state.coins -= price
			return int(accept["bribe"])
		"threat":
			return int(accept.get("threat", -1))
	return int(accept.get(category, 0))


static func prepare(service: LlmService = null) -> void:
	service = service if service else LlmService.instance()
	if service.is_model_available():
		service.prefill("persuade", RULES)
