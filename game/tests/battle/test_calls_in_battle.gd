extends "res://tests/test_case.gd"
## Calls inside the battle: breath, deafness, obedience roll, situation bonus.


func _battle(seed_value := 1) -> Battle:
	return Battle.create(seed_value, [
		[{"id": "bambaer", "level": 10}, {"id": "wawalurch", "level": 10}],
		[{"id": "glutfasan", "level": 10}, {"id": "rollschupp", "level": 10}]], 2)


func test_breath_limits_calls_and_regenerates() -> void:
	var b := _battle()
	var ai := BattleAI.new(5)
	for i in Obedience.BREATH_MAX:
		assert_eq(b.submit(0, 0, Battle.call_action("bambusschlag", 1, 0, "offensive", false)), "", "call %d" % i)
		b.submit(0, 1, Battle.move_action("schlammwand", 0, 1))
		ai.fill(b, 1)
		if b.is_over():
			return
		b.resolve_turn()
		b.pending.clear()
	# Turn 3 regenerated one breath.
	assert_eq(b.breath[0], 1)
	assert_eq(b.submit(0, 0, Battle.call_action("bambusschlag", 1, 0, "offensive", false)), "")
	b.pending.clear()
	b.breath[0] = 0
	assert_eq(b.submit(0, 0, Battle.call_action("bambusschlag", 1, 0, "offensive", false)), "no breath left")
	assert_eq(b.submit(0, 0, Battle.move_action("bambusschlag", 1, 0)), "", "menu always works")


func test_deaf_unit_rejects_calls() -> void:
	var b := _battle()
	b.unit_at(0, 0).statuses["deaf"] = {"turns": 2, "applied_turn": 0}
	assert_eq(b.submit(0, 0, Battle.call_action("bambusschlag", 1, 0, "offensive", false)), "unit is deaf to calls")


func test_high_bond_gentle_always_obeys_protective() -> void:
	var u := BattleUnit.create("bambaer", 10)
	u.bond = 100
	assert_almost_eq(Obedience.chance(u, "protective", "heal"), 1.0)


func test_stubborn_low_bond_rarely_obeys() -> void:
	var u := BattleUnit.create("rollschupp", 10)
	u.bond = 0
	var low := Obedience.chance(u, "offensive", "attack")
	u.bond = 100
	var high := Obedience.chance(u, "offensive", "attack")
	assert_true(low < 0.35, "stubborn, bond 0: %.2f" % low)
	assert_true(high >= 0.95, "stubborn, bond 100: %.2f" % high)


func test_brave_ignores_retreat() -> void:
	var u := BattleUnit.create("glutfasan", 10)
	u.bond = 50
	assert_true(Obedience.chance(u, "defensive", "guard") < Obedience.chance(u, "offensive", "attack"))


func test_disobedience_happens_and_is_reproducible() -> void:
	var disobeyed := 0
	for seed_value in 30:
		var b := _battle(seed_value)
		b.unit_at(0, 0).bond = 0
		b.submit(0, 0, Battle.call_action("bambushain", 0, 0, "protective", false))
		b.submit(0, 1, Battle.move_action("schlammwand", 0, 1))
		BattleAI.new(seed_value).fill(b, 1)
		var events := b.resolve_turn()
		if events.any(func(e): return e["type"] == "disobey"):
			disobeyed += 1
	assert_true(disobeyed > 0 and disobeyed < 30, "gentle at bond 0 obeys mostly: %d/30 disobeyed" % disobeyed)
	var h1 := JSON.stringify(_one_call_turn(3))
	assert_eq(JSON.stringify(_one_call_turn(3)), h1, "same seed, same outcome")


func _one_call_turn(seed_value: int) -> Array:
	var b := _battle(seed_value)
	b.submit(0, 0, Battle.call_action("bambusschlag", 1, 1, "offensive", true))
	b.submit(0, 1, Battle.call_action("stroemungsruf", 1, 0, "offensive", true))
	BattleAI.new(seed_value).fill(b, 1)
	return b.resolve_turn()


func test_situation_bonus_requires_facts_and_is_capped() -> void:
	var b := _battle()
	var u := b.unit_at(0, 1)  # wawalurch, water
	var fire := b.unit_at(1, 0)
	var metal := b.unit_at(1, 1)
	var water_attack := GameData.move("stroemungsruf")
	assert_almost_eq(Obedience.situation_bonus(b, u, water_attack, fire, "offensive", true), 0.10, 0.0001, "water vs fire")
	assert_almost_eq(Obedience.situation_bonus(b, u, water_attack, fire, "offensive", false), 0.0, 0.0001, "model did not claim it")
	assert_almost_eq(Obedience.situation_bonus(b, u, water_attack, metal, "offensive", true), 0.0, 0.0001, "no advantage vs metal")
	fire.hp = 1
	assert_almost_eq(Obedience.situation_bonus(b, u, water_attack, fire, "offensive", true), 0.15, 0.0001, "capped at 15 %")


func test_bonus_raises_damage_in_battle() -> void:
	var with_bonus := 0
	var without := 0
	for seed_value in 20:
		for fits in [true, false]:
			var b := _battle(seed_value)
			b.unit_at(0, 1).bond = 100
			b.submit(0, 1, Battle.call_action("stroemungsruf", 1, 0, "offensive", fits))
			b.submit(0, 0, Battle.move_action("bambushain", 0, 0))
			b.submit(1, 0, Battle.move_action("glutkreischen", 0, 0))
			b.submit(1, 1, Battle.move_action("eisenstille", 0, 0))
			for e in b.resolve_turn():
				if e["type"] == "damage" and e["target"] == "s1p0":
					if fits:
						with_bonus += e["amount"]
					else:
						without += e["amount"]
	assert_true(with_bonus > without, "%d > %d" % [with_bonus, without])
