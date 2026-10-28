class_name FarmDiary
extends RefCounted
## The farm diary after a night (GDD "Rolle des LLM auf dem Hof"): eggs,
## hatchlings and grown-up young are reported from templates; one little
## story about two pen mates is written by the model from facts, or a template.


static func _name(species: String) -> String:
	return TranslationServer.translate(GameData.lingshou(species)["name"])


static func lines(diary: Array, state: GameState) -> Array[String]:
	var out: Array[String] = []
	var chats := []
	for e in diary:
		match e["type"]:
			"egg":
				out.append(TranslationServer.translate("DIARY_EGG").format({"a": _name(e["a"]), "b": _name(e["b"])}))
			"hatched":
				out.append(TranslationServer.translate("DIARY_HATCHED_RARE" if int(e.get("variant", 0)) > 0 else "DIARY_HATCHED").format({"a": _name(e["a"])}))
			"grown":
				out.append(TranslationServer.translate("DIARY_GROWN").format({"a": _name(e["a"])}))
			"chat":
				chats.append(e)
			"alone":
				if chats.is_empty():
					chats.append(e)
	if chats.is_empty():
		return out
	var e: Dictionary = chats[0]
	var template := TranslationServer.translate("DIARY_ALONE" if e["type"] == "alone" else "DIARY_CHAT_%d" % (state.day % 4))
	template = template.format({"a": _name(e["a"]), "b": _name(e.get("b", e["a"]))})
	var service := LlmService.instance()
	if not service.is_model_available():
		out.append(template)
		return out
	var locale := TranslationServer.get_locale()
	var who := [Texts.get_text(GameData.lingshou(e["a"])["name"], locale)]
	if e.has("b"):
		who.append(Texts.get_text(GameData.lingshou(e["b"])["name"], locale))
	var temps := []
	for sp in [e["a"], e.get("b", e["a"])]:
		temps.append(GameData.lingshou(sp)["temperaments"][0])
	var facts := "Spirit animals in the same pen: %s (temperaments: %s)." % [" and ".join(who), ", ".join(temps)]
	var msgs := [
		{"role": "system", "content": "You write one line in a cosy farm diary of a family-friendly fantasy game: what two spirit animals did together last night. One sentence, max 20 words, warm and a little funny. Use only the names given. %s" % LingshouVoice.ANSWER_IN.get(locale, "")},
		{"role": "user", "content": "%s Write the diary line. %s" % [facts, LingshouVoice.ANSWER_IN.get(locale, "")]},
	]
	var r := await service.ask("farm_diary", msgs).wait()
	var text := TextGuard.clean(r["text"], locale, 140) if r["ok"] else ""
	out.append(TranslationServer.translate("DIARY_PREFIX") + " " + (text if text != "" else template))
	return out
