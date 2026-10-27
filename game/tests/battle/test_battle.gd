extends "res://tests/test_case.gd"
## Battle core: 1v1 and 2v2, sound statuses, Wu Xing in real damage,
## levels, and reproducibility with a fixed seed.


func _duel(seed_value: int, a := "bambaer", b := "glutfasan", level := 10) -> Battle:
	return Battle.create(seed_value, [[{"id": a, "level": level}], [{"id": b, "level": level}]], 1)


func _team(seed_value: int) -> Battle:
	return Battle.create(seed_value, [
		[{"id": "bambaer", "level": 10}, {"id": "glutfasan", "level": 10}, {"id": "wawalurch", "level": 10}],
		[{"id": "rollschupp", "level": 10}, {"id": "zirpo", "level": 10}, {"id": "firnleopard", "level": 10}],
	], 2)


## Plays a battle to the end with AI on both sides; returns the full event history.
func _autoplay(b: Battle, max_turns := 200) -> Array[Dictionary]:
	var ai0 := BattleAI.new(b.seed_value + 1)
	var ai1 := BattleAI.new(b.seed_value + 2)
	while not b.is_over() and b.turn < max_turns:
		ai0.fill(b, 0)
		ai1.fill(b, 1)
		b.resolve_turn()
	return b.history


func test_duel_runs_to_an_end() -> void:
	var b := _duel(1)
	_autoplay(b)
	assert_true(b.is_over(), "1v1 ends")
	assert_true(b.winner in [0, 1])


func test_team_battle_runs_to_an_end() -> void:
	var b := _team(7)
	_autoplay(b)
	assert_true(b.is_over(), "2v2 ends")
	assert_eq(b.active_count, 2)


func test_same_seed_same_battle() -> void:
	for seed_value in [1, 42, 9001]:
		var h1 := _autoplay(_team(seed_value))
		var h2 := _autoplay(_team(seed_value))
		assert_eq(JSON.stringify(h1), JSON.stringify(h2), "seed %d" % seed_value)


func test_different_seeds_differ() -> void:
	var h1 := JSON.stringify(_autoplay(_team(1)))
	var h2 := JSON.stringify(_autoplay(_team(2)))
	assert_ne(h1, h2)


func test_advantage_in_real_damage() -> void:
	# Same attacker, same move power class: fire (glutfeder) vs metal target beats fire vs water target.
	var b := Battle.create(3, [[{"id": "glutfasan", "level": 10}], [{"id": "rollschupp", "level": 10}]], 1)
	var fire := GameData.move("glutfeder")
	var u := b.unit_at(0, 0)
	var metal_target := b.unit_at(1, 0)
	var water_target := BattleUnit.create("wawalurch", 10)
	water_target.def = metal_target.def
	var neutral_target := BattleUnit.create("bambaer", 10)
	neutral_target.def = metal_target.def
	var vs_metal := b.damage(u, metal_target, fire)
	var vs_water := b.damage(u, water_target, fire)
	var vs_wood := b.damage(u, neutral_target, fire)
	assert_true(vs_metal > vs_wood, "fire overcomes metal: %d > %d" % [vs_metal, vs_wood])
	assert_true(vs_water < vs_wood, "water overcomes fire: %d < %d" % [vs_water, vs_wood])


func test_team_bonus_applies_in_2v2() -> void:
	# wood (bambaer) + fire (glutfasan) = generating pair; wood + water (wawalurch) too, wood + metal not.
	var b := Battle.create(5, [
		[{"id": "bambaer", "level": 10}, {"id": "glutfasan", "level": 10}],
		[{"id": "rollschupp", "level": 10}, {"id": "zirpo", "level": 10}]], 2)
	assert_almost_eq(b.team_bonus(0), 0.10)
	assert_almost_eq(b.team_bonus(1), 0.10, 0.0001, "earth + metal also generate")
	var c := Battle.create(5, [
		[{"id": "bambaer", "level": 10}, {"id": "rollschupp", "level": 10}],
		[{"id": "zirpo", "level": 10}, {"id": "glutfasan", "level": 10}]], 2)
	assert_almost_eq(c.team_bonus(0), 0.0, 0.0001, "metal overcomes wood: no bonus")
	var with_bonus := b.damage(b.unit_at(0, 0), b.unit_at(1, 1), GameData.move("bambusschlag"))
	var without := c.damage(c.unit_at(0, 0), c.unit_at(1, 0), GameData.move("bambusschlag"))
	assert_true(with_bonus > without, "bonus raises damage: %d > %d" % [with_bonus, without])


func test_resonance_doubles_bonus_in_battle() -> void:
	var b := Battle.create(5, [
		[{"id": "bambaer", "level": 10}, {"id": "glutfasan", "level": 10}],
		[{"id": "rollschupp", "level": 10}, {"id": "firnleopard", "level": 10}]], 2)
	b.unit_at(0, 1).statuses["resonance"] = {"turns": 2, "applied_turn": 0}
	assert_almost_eq(b.team_bonus(0), 0.20)


func test_silenced_only_basic_attack() -> void:
	var b := _duel(4)
	var u := b.unit_at(0, 0)
	u.statuses["silenced"] = {"turns": 2, "applied_turn": 0}
	assert_eq(u.usable_moves(), [BattleUnit.BASIC_MOVE] as Array[String])
	assert_ne(b.submit(0, 0, Battle.move_action("bambusschlag", 1, 0)), "", "element move rejected")
	assert_eq(b.submit(0, 0, Battle.move_action(BattleUnit.BASIC_MOVE, 1, 0)), "")


func test_silenced_mid_turn_falls_back() -> void:
	var b := _duel(4)
	assert_eq(b.submit(0, 0, Battle.move_action("bambusschlag", 1, 0)), "")
	b.unit_at(0, 0).statuses["silenced"] = {"turns": 2, "applied_turn": 0}
	assert_eq(b.submit(1, 0, Battle.move_action(BattleUnit.BASIC_MOVE, 0, 0)), "")
	var events := b.resolve_turn()
	var fallback := events.filter(func(e): return e["type"] == "silenced_fallback")
	assert_eq(fallback.size(), 1)
	var used := events.filter(func(e): return e["type"] == "uses" and e["user"] == "s0p0")
	assert_eq(used[0]["move"], BattleUnit.BASIC_MOVE)


func test_echo_repeats_next_attack_at_half_strength() -> void:
	var b := _duel(6, "nebelaffe", "rollschupp", 20)
	var u := b.unit_at(0, 0)
	u.statuses["echo"] = {"turns": 3, "applied_turn": 0}
	b.unit_at(1, 0).max_hp = 9999
	b.unit_at(1, 0).hp = 9999
	b.submit(0, 0, Battle.move_action("rankenpeitsche", 1, 0))  # accuracy 100
	b.submit(1, 0, Battle.move_action("schlammwand", 1, 0))
	b.unit_at(1, 0).moves = ["schlammwand"] as Array[String]
	var events := b.resolve_turn()
	var hits := events.filter(func(e): return e["type"] == "damage" and e["target"] == "s1p0")
	assert_eq(hits.size(), 2, "attack plus echo")
	if hits.size() == 2:
		assert_true(hits[1]["amount"] < hits[0]["amount"], "echo is weaker")
	assert_false(u.has_status("echo"), "echo is used up")


func test_dissonance_sometimes_changes_the_move() -> void:
	var changed := 0
	for seed_value in 40:
		var b := _duel(seed_value, "wawalurch", "rollschupp", 10)
		b.unit_at(0, 0).statuses["dissonance"] = {"turns": 9, "applied_turn": 0}
		b.submit(0, 0, Battle.move_action("stroemungsruf", 1, 0))
		b.submit(1, 0, Battle.move_action("schlammwand", 1, 0))
		var events := b.resolve_turn()
		if events.any(func(e): return e["type"] == "dissonance"):
			changed += 1
	assert_true(changed > 5 and changed < 25, "about 35%% of 40 turns, got %d" % changed)


func test_deaf_ignores_calls_but_takes_menu_commands() -> void:
	var b := _duel(8)
	var u := b.unit_at(0, 0)
	assert_true(u.accepts_calls())
	u.statuses["deaf"] = {"turns": 2, "applied_turn": 0}
	assert_false(u.accepts_calls())
	assert_eq(b.submit(0, 0, Battle.move_action("bambusschlag", 1, 0)), "", "menu still works")


func test_status_expires() -> void:
	var b := _duel(9)
	var u := b.unit_at(0, 0)
	u.statuses["silenced"] = {"turns": 1, "applied_turn": 0}
	b.submit(0, 0, Battle.move_action(BattleUnit.BASIC_MOVE, 1, 0))
	b.submit(1, 0, Battle.move_action(BattleUnit.BASIC_MOVE, 0, 0))
	var events := b.resolve_turn()
	assert_false(u.has_status("silenced"))
	assert_true(events.any(func(e): return e["type"] == "status_end" and e["status"] == "silenced"))


func test_guard_halves_damage() -> void:
	var b := _duel(10, "rollschupp", "firnleopard", 10)
	var mv := GameData.move("raureifkralle")
	var t := b.unit_at(0, 0)
	var normal := b.damage(b.unit_at(1, 0), t, mv)
	t.shielded = true
	var guarded := b.damage(b.unit_at(1, 0), t, mv)
	assert_true(abs(guarded * 2 - normal) <= 1, "%d vs %d" % [guarded, normal])


func test_switch_costs_the_turn() -> void:
	var b := Battle.create(11, [
		[{"id": "bambaer", "level": 10}, {"id": "wawalurch", "level": 10}],
		[{"id": "glutfasan", "level": 10}]], 1)
	assert_eq(b.submit(0, 0, Battle.switch_action(1)), "")
	b.submit(1, 0, Battle.move_action(BattleUnit.BASIC_MOVE, 0, 0))
	var events := b.resolve_turn()
	assert_eq(b.unit_at(0, 0).uid, "s0p1", "wawalurch now active")
	assert_false(events.any(func(e): return e["type"] == "uses" and e["user"] in ["s0p0", "s0p1"]), "no attack this turn")
	assert_eq(events[0]["type"], "switch", "switch goes first")


func test_invalid_commands_rejected() -> void:
	var b := _team(12)
	assert_ne(b.submit(0, 0, Battle.move_action("tauchen", 1, 0)), "", "move the unit does not know")
	assert_ne(b.submit(0, 0, Battle.move_action("bambusschlag", 0, 1)), "", "attack on own ally")
	assert_ne(b.submit(0, 0, Battle.move_action("bambushain", 1, 0)), "", "heal on enemy")
	assert_ne(b.submit(0, 0, Battle.switch_action(0)), "", "switch to active unit")
	assert_eq(b.submit(0, 0, Battle.switch_action(2)), "")
	assert_ne(b.submit(0, 1, Battle.switch_action(2)), "", "same bench unit twice")


func test_fainted_slot_refilled_from_bench() -> void:
	var b := Battle.create(13, [
		[{"id": "bambaer", "level": 10}, {"id": "wawalurch", "level": 10}],
		[{"id": "firnleopard", "level": 30}]], 1)
	b.unit_at(0, 0).hp = 1
	b.submit(0, 0, Battle.move_action(BattleUnit.BASIC_MOVE, 1, 0))
	b.submit(1, 0, Battle.move_action("raureifkralle", 0, 0))
	for attempt in 5:
		var events := b.resolve_turn()
		if events.any(func(e): return e["type"] == "send_in"):
			break
		b.submit(0, 0, Battle.move_action(BattleUnit.BASIC_MOVE, 1, 0))
		b.submit(1, 0, Battle.move_action("raureifkralle", 0, 0))
	assert_eq(b.unit_at(0, 0).uid, "s0p1")
	assert_false(b.is_over())


func test_stats_grow_with_level() -> void:
	var low := BattleUnit.create("bambaer", 1)
	var high := BattleUnit.create("bambaer", 50)
	for s in ["max_hp", "atk", "def", "spd"]:
		assert_true(high.get(s) > low.get(s), s)
	assert_eq(BattleUnit.create("bambaer", 99).level, 50, "level cap")


func test_xp_levels_up_and_keeps_damage_taken() -> void:
	var u := BattleUnit.create("zirpo", 5)
	u.hp -= 10
	var missing := u.max_hp - u.hp
	var gained := u.gain_xp(BattleUnit.xp_to_next(5))
	assert_eq(gained, 1)
	assert_eq(u.level, 6)
	assert_eq(u.max_hp - u.hp, missing, "level up keeps the damage taken")


func test_winner_gets_xp() -> void:
	var b := _duel(14, "firnleopard", "zirpo", 10)
	b.unit_at(1, 0).level = 3
	_autoplay(b)
	if b.winner == 0:
		assert_true(b.history.any(func(e): return e["type"] == "xp" and e["target"] == "s0p0"))
