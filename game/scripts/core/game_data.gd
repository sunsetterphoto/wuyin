class_name GameData
extends RefCounted
## Loads and validates content from res://data (rule 4: content is data).
## One JSON file per entry; the file name must equal the entry's "id".

const LINGSHOU_DIR := "res://data/lingshou"
const MOVES_DIR := "res://data/moves"
const ITEMS_DIR := "res://data/items"
const ITEM_KINDS: Array[String] = ["heal", "revive", "food", "material", "key", "festival", "dish"]

const TEMPERAMENTS: Array[String] = ["brave", "anxious", "stubborn", "playful", "gentle", "moody"]
const ALIGNMENTS: Array[String] = ["free", "wild", "silenced", "shadow_moth", "nian"]
const MOVE_KINDS: Array[String] = ["attack", "status", "heal", "guard"]
const MOVE_TARGETS: Array[String] = ["enemy", "ally", "self", "ally_side"]
const STATUSES: Array[String] = ["silenced", "echo", "dissonance", "deaf", "resonance"]
const STATS: Array[String] = ["hp", "atk", "def", "spd"]
const MAX_MOVES := 4

static var _lingshou: Dictionary = {}
static var _moves: Dictionary = {}
static var _items: Dictionary = {}
static var _loaded := false


static func lingshou(id: String) -> Dictionary:
	_ensure_loaded()
	assert(_lingshou.has(id), "unknown lingshou: " + id)
	return _lingshou[id]


static func move(id: String) -> Dictionary:
	_ensure_loaded()
	assert(_moves.has(id), "unknown move: " + id)
	return _moves[id]


## Empty dictionary for unknown ids (callers validate player input with it).
static func item(id: String) -> Dictionary:
	_ensure_loaded()
	return _items.get(id, {})


static func item_ids() -> Array:
	_ensure_loaded()
	return _items.keys()


static func lingshou_ids() -> Array:
	_ensure_loaded()
	return _lingshou.keys()


static func move_ids() -> Array:
	_ensure_loaded()
	return _moves.keys()


static func reload() -> void:
	_loaded = false
	_ensure_loaded()


## Returns a list of human-readable problems; empty = all data valid.
static func validate() -> Array[String]:
	_ensure_loaded()
	var errors: Array[String] = []
	for id in _moves:
		_validate_move(_moves[id], errors)
	for id in _lingshou:
		_validate_lingshou(_lingshou[id], errors)
	for id in _items:
		_validate_item(_items[id], errors)
	return errors


static func _validate_item(it: Dictionary, errors: Array[String]) -> void:
	var id: String = it.get("id", "?")
	if it.get("_file") != id:
		errors.append("item %s: file name differs from id" % id)
	for key in ["name", "desc"]:
		if not String(it.get(key, "")).begins_with("ITEM_"):
			errors.append("item %s: %s must be a translation key ITEM_*" % [id, key])
	if it.get("kind") not in ITEM_KINDS:
		errors.append("item %s: bad kind %s" % [id, it.get("kind")])
	if int(it.get("price", 0)) <= 0:
		errors.append("item %s: needs a price" % id)
	for e in it.get("likes", []):
		if not WuXing.is_element(e):
			errors.append("item %s: bad element in likes: %s" % [id, e])


static func _ensure_loaded() -> void:
	if _loaded:
		return
	_moves = _load_dir(MOVES_DIR)
	_lingshou = _load_dir(LINGSHOU_DIR)
	_items = _load_dir(ITEMS_DIR)
	_loaded = true


static func _load_dir(path: String) -> Dictionary:
	var out := {}
	for file in DirAccess.get_files_at(path):
		if not file.ends_with(".json"):
			continue
		var text := FileAccess.get_file_as_string(path.path_join(file))
		var entry = JSON.parse_string(text)
		if entry is Dictionary:
			entry["_file"] = file.get_basename()
			out[entry.get("id", file.get_basename())] = entry
		else:
			push_error("invalid JSON: " + path.path_join(file))
	return out


static func _validate_move(m: Dictionary, errors: Array[String]) -> void:
	var id: String = m.get("id", "?")
	if m.get("_file") != id:
		errors.append("move %s: file name differs from id" % id)
	if not m.get("name", "").begins_with("MOVE_"):
		errors.append("move %s: name must be a translation key MOVE_*" % id)
	var element: String = m.get("element", "")
	if not (WuXing.is_element(element) or element == WuXing.NEUTRAL):
		errors.append("move %s: bad element %s" % [id, element])
	if m.get("kind") not in MOVE_KINDS:
		errors.append("move %s: bad kind %s" % [id, m.get("kind")])
	if m.get("target") not in MOVE_TARGETS:
		errors.append("move %s: bad target %s" % [id, m.get("target")])
	if m.get("kind") == "attack" and int(m.get("power", 0)) <= 0:
		errors.append("move %s: attack without power" % id)
	if str(m.get("llm_hint", "")).length() < 10:
		errors.append("move %s: needs an llm_hint (prompt-only description)" % id)
	var acc := int(m.get("accuracy", 0))
	if acc < 1 or acc > 100:
		errors.append("move %s: accuracy must be 1..100" % id)
	var effect = m.get("effect")
	if effect != null:
		if effect.get("status") not in STATUSES:
			errors.append("move %s: bad status %s" % [id, effect.get("status")])
		if int(effect.get("turns", 0)) < 1:
			errors.append("move %s: status needs turns >= 1" % id)


static func _validate_lingshou(l: Dictionary, errors: Array[String]) -> void:
	var id: String = l.get("id", "?")
	if l.get("_file") != id:
		errors.append("lingshou %s: file name differs from id" % id)
	if not l.get("name", "").begins_with("LS_"):
		errors.append("lingshou %s: name must be a translation key LS_*" % id)
	if not l.get("animal", "").begins_with("LS_"):
		errors.append("lingshou %s: animal must be a translation key LS_*_ANIMAL" % id)
	if not WuXing.is_element(l.get("element", "")):
		errors.append("lingshou %s: bad element" % id)
	for t in l.get("temperaments", []):
		if t not in TEMPERAMENTS:
			errors.append("lingshou %s: bad temperament %s" % [id, t])
	if l.get("temperaments", []).is_empty():
		errors.append("lingshou %s: needs a temperament" % id)
	if l.get("alignment") not in ALIGNMENTS:
		errors.append("lingshou %s: bad alignment" % id)
	var stats: Dictionary = l.get("base_stats", {})
	for s in STATS:
		if int(stats.get(s, 0)) <= 0:
			errors.append("lingshou %s: base stat %s missing" % [id, s])
	var moves: Array = l.get("moves", [])
	if moves.is_empty() or moves.size() > MAX_MOVES:
		errors.append("lingshou %s: needs 1..%d moves" % [id, MAX_MOVES])
	for mv in moves:
		if not _moves.has(mv):
			errors.append("lingshou %s: unknown move %s" % [id, mv])
