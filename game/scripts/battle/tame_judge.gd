class_name TameJudge
extends RefCounted
## "Zureden": the player's sentence to a wild or silenced Lingshou. The model
## only names the sentence's tone (grammar-forced, one word); how much trust
## that earns is decided by Taming per temperament (GDD: "Das LLM bewertet nur,
## ob der Satz zum Temperament passt; die Vertrauensschwelle prüft der Code").
## Without a model, keyword lists from data/llm/tame_keywords.json decide.

const KEYWORDS_PATH := "res://data/llm/tame_keywords.json"

static var _keywords := {}

const RULES := """You judge the tone of one sentence a player says to a shy spirit animal. The sentence may be German, English or Chinese.
Tones:
soothing = calming, gentle, reassuring ("Keine Angst", "it's okay", "别怕")
encouraging = cheering on, daring, brave ("You can do it!", "Komm, zeig was du kannst!")
playful = jokes, games, silly ("Wanna play?", "Fang mich!")
respectful = polite, patient, giving space, asking ("Darf ich?", "I'll wait for you")
praising = compliments ("Du bist wunderschön", "what a strong one")
rude = insults, threats, orders, mocking ("Stupid", "Komm sofort her!")
neutral = none of these
Answer with one line: tone=<tone>"""


static func grammar() -> String:
	return 'root ::= "tone=" tone\ntone ::= ' + " | ".join(Taming.TONES.map(func(t): return "\"%s\"" % t))


static func messages(text: String) -> Array:
	return [{"role": "system", "content": RULES}, {"role": "user", "content": "Sentence: " + text}]


## Returns {"tone": String, "source": "model"|"template", "ms": int}.
static func judge(text: String, service: LlmService = null) -> Dictionary:
	service = service if service else LlmService.instance()
	var job := service.ask("tame_judge", messages(text), {}, grammar(), "tame")
	var r := await job.wait()
	if r["ok"]:
		var t := String(r["text"]).strip_edges().trim_prefix("tone=").strip_edges()
		if t in Taming.TONES:
			return {"tone": t, "source": "model", "ms": r["total_ms"]}
	return {"tone": from_keywords(text), "source": "template", "ms": r["total_ms"]}


static func from_keywords(text: String) -> String:
	if _keywords.is_empty():
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(KEYWORDS_PATH))
		_keywords = parsed if parsed is Dictionary else {}
	var lower := text.to_lower()
	var best := "neutral"
	var best_hits := 0
	# rude first: an insult inside a nice sentence still counts as rude.
	for tone in ["rude", "soothing", "encouraging", "playful", "respectful", "praising"]:
		var hits := 0
		for w in _keywords.get(tone, []):
			if String(w) in lower:
				hits += 1
		if hits > best_hits or (tone == "rude" and hits > 0):
			best = tone
			best_hits = hits
			if tone == "rude":
				return best
	return best


## Precomputes the fixed prompt so the first judgement is quick.
static func prepare(service: LlmService = null) -> void:
	service = service if service else LlmService.instance()
	if service.is_model_available():
		service.prefill("tame", RULES)
