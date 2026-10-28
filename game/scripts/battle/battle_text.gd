class_name BattleText
extends RefCounted
## Turns battle events into translated log lines (all text via translation keys).


static func unit_name(battle: Battle, uid: String) -> String:
	var u := battle.find_unit(uid)
	return TranslationServer.translate(u.name_key()) if u else uid


static func move_name(move_id: String) -> String:
	return TranslationServer.translate(GameData.move(move_id)["name"])


static func element_name(element: String) -> String:
	return TranslationServer.translate("ELEMENT_" + element.to_upper())


static func status_name(status: String) -> String:
	return TranslationServer.translate("STATUS_" + status.to_upper())


static func _t(key: String, args := {}) -> String:
	return String(TranslationServer.translate(key)).format(args)


## Returns zero or more lines for one event.
static func describe(battle: Battle, e: Dictionary) -> Array[String]:
	var out: Array[String] = []
	var user := unit_name(battle, e.get("user", "")) if e.has("user") else ""
	var target := unit_name(battle, e.get("target", "")) if e.has("target") and e["target"] is String else ""
	match e["type"]:
		"uses":
			out.append(_t("BATTLE_USES", {"user": user, "move": move_name(e["move"])}))
		"miss":
			out.append(_t("BATTLE_MISS", {"user": user}))
		"damage":
			if e["effectiveness"] > 1.0:
				out.append(_t("BATTLE_STRONG", {"element": element_name(e["target_element"])}))
			elif e["effectiveness"] < 1.0:
				out.append(_t("BATTLE_WEAK", {"element": element_name(e["target_element"])}))
			out.append(_t("BATTLE_DAMAGE", {"target": target, "amount": e["amount"]}))
		"echo":
			out.append(_t("BATTLE_ECHO"))
		"heal":
			out.append(_t("BATTLE_HEAL", {"target": target, "amount": e["amount"]}))
		"guard":
			out.append(_t("BATTLE_GUARD", {"target": target}))
		"status":
			out.append(_t("BATTLE_STATUS", {"target": target, "status": status_name(e["status"])}))
		"status_end":
			out.append(_t("BATTLE_STATUS_END", {"target": target, "status": status_name(e["status"])}))
		"silenced_fallback":
			out.append(_t("BATTLE_SILENCED_FALLBACK", {"user": user, "move": move_name(e["move"])}))
		"dissonance":
			out.append(_t("BATTLE_DISSONANCE", {"user": user}))
		"faint":
			out.append(_t("BATTLE_FAINT", {"target": target}))
		"send_in":
			out.append(_t("BATTLE_SEND_IN", {"target": target}))
		"switch":
			out.append(_t("BATTLE_SWITCH", {"user": user, "target": target}))
		"team_bonus":
			out.append(_t("BATTLE_TEAM_BONUS", {"a": unit_name(battle, e["a"]), "b": unit_name(battle, e["b"])}))
		"disobey":
			out.append(_t("BATTLE_DISOBEY", {"user": user}))
		"situation_bonus":
			out.append(_t("BATTLE_SITUATION_BONUS", {"pct": roundi(e["bonus"] * 100)}))
		"no_effect":
			out.append(_t("BATTLE_NO_EFFECT"))
		"level_up":
			out.append(_t("BATTLE_LEVEL_UP", {"target": target, "level": e["level"]}))
		"end":
			out.append(_t("BATTLE_WIN") if e["winner"] == 0 else _t("BATTLE_LOSE"))
		"tame_calm":
			out.append(_t("BATTLE_CALMS", {"target": target}))
		"tame_feed":
			out.append(_t("BATTLE_FEEDS", {"target": target, "item": TranslationServer.translate(GameData.item(e["item"])["name"])}))
		"tame_talk":
			out.append(_t("BATTLE_TALKS", {"target": target}))
		"trust":
			var key := "BATTLE_TRUST_UP" if e["amount"] > 0 else ("BATTLE_TRUST_DOWN" if e["amount"] < 0 else "BATTLE_TRUST_SAME")
			out.append(_t(key, {"target": target}))
		"heart":
			out.append(_t("BATTLE_HEART_UP", {"target": target}))
		"tamed":
			out.append(_t("BATTLE_TAMED", {"target": target}))
		"freed":
			out.append(_t("BATTLE_FREED", {"target": target}))
		"item":
			out.append(_t("BATTLE_ITEM", {"item": TranslationServer.translate(GameData.item(e["item"])["name"]), "target": target}))
		"revive":
			out.append(_t("BATTLE_REVIVE", {"target": target}))
		"watch":
			out.append(_t("BATTLE_WATCHES", {"user": user}))
		"fled":
			pass
	return out
