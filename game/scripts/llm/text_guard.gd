class_name TextGuard
extends RefCounted
## Validator for free text from the model (voices, dialog): cleans it up,
## enforces the role's length limit, filters words and meta talk, checks the
## script matches the game language. Returns "" when the text must be replaced
## by a template.

const BLOCKLIST_PATH := "res://data/llm/blocklist.json"

static var _block: Dictionary = {}


## max_chars: hard limit for the role. Returns cleaned text or "" (= use template).
static func clean(text: String, locale: String, max_chars: int, extra_forbidden: Array = []) -> String:
	var t := text.strip_edges()
	# One line, no surrounding quotes, no markdown.
	t = t.replace("\r", " ").replace("\n", " ").replace("*", "").replace("#", "")
	while "  " in t:
		t = t.replace("  ", " ")
	for q in ["\"", "„", "“", "”", "「", "」", "'"]:
		if t.begins_with(q):
			t = t.substr(1)
		if t.ends_with(q):
			t = t.substr(0, t.length() - 1)
	t = t.strip_edges()
	if t == "":
		return ""
	var lower := t.to_lower()
	var block := _blocklist()
	for w in block.get("words", []) + block.get("meta", []) + extra_forbidden:
		if String(w).to_lower() in lower:
			return ""
	if not script_matches(t, locale) or not language_matches(t, locale):
		return ""
	return limit(t, max_chars)


## Cuts to max_chars, preferring a sentence end, else a word boundary + ellipsis.
static func limit(t: String, max_chars: int) -> String:
	if t.length() <= max_chars:
		return t
	var cut := t.substr(0, max_chars)
	var best := -1
	for mark in [".", "!", "?", "…", "。", "！", "？"]:
		best = maxi(best, cut.rfind(mark))
	if best >= max_chars / 3:
		return cut.substr(0, best + 1)
	var space := cut.rfind(" ")
	if space >= max_chars / 3:
		return cut.substr(0, space) + "…"
	return cut.substr(0, max_chars - 1) + "…"


const DE_WORDS := ["ich", "du", "der", "die", "das", "und", "nicht", "ist", "bin", "bitte", "mir", "mich", "war", "es", "ein", "eine",
	"wir", "hab", "auf", "danach", "jetzt", "ruhig", "mit", "uns", "werden", "wird", "dich", "dir", "kann", "noch", "nur", "auch",
	"aber", "zu", "von", "für", "ganz", "schon", "gut", "mal", "doch", "hier", "nach", "dem", "den", "sind", "habe"]
const EN_WORDS := ["i", "you", "the", "and", "not", "is", "am", "please", "me", "my", "was", "it", "a", "an", "we", "that",
	"on", "are", "be", "will", "this", "after", "now", "with", "to", "of", "in", "can", "just", "us", "your", "it's", "i'm",
	"don't", "for", "but", "all", "here", "have", "what", "easy", "too", "very"]


## German vs. English by common function words; short or unclear text passes.
static func language_matches(t: String, locale: String) -> bool:
	if not (locale.begins_with("de") or locale.begins_with("en")):
		return true
	var words := t.to_lower().replace("…", " ").replace("...", " ")
	for c in [".", ",", "!", "?", ":", ";", "-", "'", "\""]:
		words = words.replace(c, " ")
	var de := 0
	var en := 0
	for w in words.split(" ", false):
		if w in DE_WORDS:
			de += 1
		if w in EN_WORDS:
			en += 1
	if de + en < 2:
		return true
	return de >= en if locale.begins_with("de") else en >= de


## Chinese output must contain Han characters; German/English must not.
static func script_matches(t: String, locale: String) -> bool:
	var han := 0
	var letters := 0
	for i in t.length():
		var c := t.unicode_at(i)
		if c >= 0x4E00 and c <= 0x9FFF:
			han += 1
		elif (c >= 0x41 and c <= 0x5A) or (c >= 0x61 and c <= 0x7A) or (c >= 0xC0 and c <= 0x24F):
			letters += 1
	if locale.begins_with("zh"):
		return han > 0
	return han == 0 and letters > 0


static func _blocklist() -> Dictionary:
	if _block.is_empty():
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(BLOCKLIST_PATH))
		_block = parsed if parsed is Dictionary else {"words": [], "meta": []}
	return _block
