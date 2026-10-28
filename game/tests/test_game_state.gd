extends "res://tests/test_case.gd"
## Beta: save game, party with bells, items, defeat, taming and freeing in battle.

const TEST_SLOT := 9


func test_party_fills_bells_then_farm() -> void:
	var s := GameState.new_game("Mei")
	s.add_lingshou("bambaer", 5)
	s.add_lingshou("wawalurch", 5)
	var third := s.add_lingshou("zirpo", 4)
	assert_eq(s.party.size(), 2)
	assert_eq(s.farm.size(), 1)
	assert_false(s.in_party(third))
	s.bells = 3
	s.move_to_party(0)
	assert_eq(s.party.size(), 3)
	assert_ne(s.party[0]["uid"], s.party[1]["uid"], "unique ids")


func test_save_and_load_round_trip() -> void:
	var s := GameState.new_game("Mei", 2, 1)
	s.add_lingshou("glutfasan", 7)
	s.party[0]["hp"] = 3
	s.give_item("kraeutertee", 2)
	s.set_flag("prologue_done")
	s.pos = Vector2(4.5, 7.25)
	s.map = "bambuspfad"
	assert_true(s.save_game(TEST_SLOT))
	var l := GameState.load_game(TEST_SLOT)
	GameState.delete_save(TEST_SLOT)
	assert_true(l != null, "loaded")
	assert_eq(l.player["name"], "Mei")
	assert_eq(l.party[0]["hp"], 3)
	assert_eq(l.party[0]["level"], 7)
	assert_eq(l.item_count("kraeutertee"), 2)
	assert_true(l.flag("prologue_done"))
	assert_eq(l.map, "bambuspfad")
	assert_almost_eq(l.pos.y, 7.25)
	assert_false(GameState.has_save(TEST_SLOT))


func test_records_survive_a_battle() -> void:
	var s := GameState.new_game("Mei")
	s.add_lingshou("bambaer", 6)
	var b := Battle.create(5, [s.party_specs(), [{"id": "glutfasan", "level": 3}]], 1)
	assert_eq(b.unit_at(0, 0).uid, s.party[0]["uid"])
	var ai := BattleAI.new(1)
	while not b.is_over():
		ai.fill(b, 0)
		BattleAI.new(b.turn).fill(b, 1)
		b.resolve_turn()
	s.sync_party(b.sides[0]["party"])
	assert_eq(s.party[0]["hp"], b.unit_at(0, 0).hp)
	assert_true(s.party[0]["xp"] > 0 or s.party[0]["level"] > 6, "experience kept")


func test_items_and_shop() -> void:
	var s := GameState.new_game("Mei")
	s.coins = 50
	assert_true(s.buy("reisbaellchen", 2))
	assert_eq(s.coins, 10)
	assert_false(s.buy("kraeutertee"), "too expensive")
	assert_true(s.take_item("reisbaellchen", 5))
	assert_false(s.take_item("reisbaellchen", 1), "none left")
	assert_eq(s.item_count("reisbaellchen"), 0)


func test_defeat_costs_coins_and_heals() -> void:
	var s := GameState.new_game("Mei")
	s.add_lingshou("bambaer", 5)
	s.party[0]["hp"] = 0
	s.coins = 100
	assert_false(s.party_alive())
	assert_eq(s.apply_defeat(), 20)
	assert_eq(s.coins, 80)
	assert_true(s.party_alive())


func _wild(species := "wawalurch", trust := Taming.START_TRUST) -> Battle:
	return Battle.create(11, [[{"id": "bambaer", "level": 6}], [{"id": species, "level": 4, "role": "wild", "trust": trust}]], 1)


func test_taming_fits_the_temperament() -> void:
	var b := _wild()
	var shy := b.unit_at(1, 0)
	assert_eq(shy.trust, Taming.START_TRUST)
	assert_true(Taming.gain(shy, "talk", "", "soothing") > Taming.gain(shy, "talk", "", "encouraging"), "anxious likes soothing")
	assert_true(Taming.gain(shy, "talk", "", "rude") < 0)
	var brave := Battle.create(1, [[{"id": "bambaer"}], [{"id": "firnleopard", "role": "wild"}]], 1).unit_at(1, 0)
	assert_true(Taming.gain(brave, "talk", "", "encouraging") > Taming.gain(brave, "talk", "", "soothing"), "brave likes courage")
	assert_eq(Taming.gain(shy, "feed", "suessreis"), Taming.FEED_LIKED, "water likes sweet rice")
	assert_eq(Taming.gain(shy, "feed", "bambussprossen"), Taming.FEED_OTHER)


func test_wild_lingshou_can_be_tamed() -> void:
	var b := _wild()
	for i in 6:
		if b.is_over():
			break
		assert_eq(b.submit(0, 0, Battle.tame_action("talk", 0, "", "soothing")), "")
		BattleAI.new(i).fill(b, 1)
		b.resolve_turn()
	assert_eq(b.outcome, "tamed")
	assert_eq(b.winner, 0)
	assert_true(b.history.any(func(e): return e["type"] == "tamed"))


func test_trusting_wild_lingshou_stops_attacking() -> void:
	var b := _wild("wawalurch", Taming.CALM_TRUST)
	var a := BattleAI.new(3).choose(b, 1, 0)
	assert_eq(a["type"], "watch")
	b.submit(0, 0, Battle.tame_action("calm", 0))
	b.submit(1, 0, a)
	b.resolve_turn()
	assert_eq(b.unit_at(0, 0).hp, b.unit_at(0, 0).max_hp, "not attacked")


func test_hitting_a_wild_lingshou_costs_trust() -> void:
	var b := _wild("wawalurch", 50)
	b.submit(0, 0, Battle.move_action("rankenpeitsche", 1, 0))
	b.submit(1, 0, Battle.watch_action())
	b.resolve_turn()
	assert_eq(b.unit_at(1, 0).trust, 50 - Taming.HIT_PENALTY)


func test_feeding_needs_food_and_a_wild_target() -> void:
	var b := _wild()
	assert_ne(b.submit(0, 0, Battle.tame_action("feed", 0, "reisbaellchen")), "", "heal item is no food")
	assert_eq(b.submit(0, 0, Battle.tame_action("feed", 0, "suessreis")), "")
	var foe := Battle.create(1, [[{"id": "bambaer"}], [{"id": "glutfasan"}]], 1)
	assert_ne(foe.submit(0, 0, Battle.tame_action("calm", 0)), "", "regular opponents cannot be befriended")


func test_silenced_lingshou_is_freed_by_words_and_damage() -> void:
	var b := Battle.create(4, [[{"id": "glutfasan", "level": 12}], [{"id": "firnleopard", "level": 6, "role": "silenced"}]], 1)
	var t := b.unit_at(1, 0)
	var turns := 0
	while not b.is_over() and turns < 20:
		var act := Battle.tame_action("talk", 0, "", "soothing") if turns % 2 == 0 else Battle.move_action("grundangriff", 1, 0)
		assert_eq(b.submit(0, 0, act), "")
		BattleAI.new(turns).fill(b, 1)
		b.resolve_turn()
		turns += 1
	assert_eq(b.outcome, "freed")
	assert_true(t.freed)
	assert_true(t.hp > 0, "freed, not exhausted")


func test_guardian_needs_two_partners_to_free() -> void:
	var b := Battle.create(4, [[{"id": "bambaer", "level": 12}, {"id": "wawalurch", "level": 12}],
		[{"id": "qinglong", "level": 12, "role": "silenced"}, {"id": "schattenmotte", "level": 10}]], 2)
	var dragon := b.unit_at(1, 0)
	assert_eq(Taming.gain(dragon, "talk", "", "soothing"), roundi(Taming.HEART_TALK["soothing"] * Taming.GUARDIAN_FACTOR))
	# Free the dragon while the moth still flies: the battle goes on.
	dragon.heart = Taming.HEART_FULL - 1
	b.submit(0, 0, Battle.tame_action("talk", 0, "", "soothing"))
	b.submit(0, 1, Battle.move_action("stroemungsruf", 1, 1))
	BattleAI.new(1).fill(b, 1)
	b.resolve_turn()
	assert_true(dragon.freed)
	assert_eq(b.outcome, "" if b.unit_at(1, 1) and b.sides[1]["party"][1].is_alive() else "win")


func test_items_heal_and_revive_in_battle() -> void:
	var b := Battle.create(2, [[{"id": "bambaer", "level": 5}, {"id": "wawalurch", "level": 5, "hp": 0}],
		[{"id": "glutfasan", "level": 3}]], 1)
	var u := b.unit_at(0, 0)
	u.hp = 5
	assert_ne(b.submit(0, 0, Battle.item_action("reisbaellchen", 1)), "", "cannot heal exhausted")
	assert_eq(b.submit(0, 0, Battle.item_action("glockenbluete", 1)), "")
	b.submit(1, 0, Battle.watch_action())
	b.resolve_turn()
	assert_true(b.sides[0]["party"][1].is_alive(), "revived")


func test_flee_only_from_wild() -> void:
	var b := _wild()
	assert_true(b.can_flee())
	assert_eq(b.submit(0, 0, Battle.flee_action()), "")
	BattleAI.new(1).fill(b, 1)
	b.resolve_turn()
	assert_eq(b.outcome, "fled")
	var boss := Battle.create(1, [[{"id": "bambaer"}], [{"id": "qinglong", "role": "silenced"}]], 1)
	assert_false(boss.can_flee())
