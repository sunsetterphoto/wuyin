extends "res://tests/test_case.gd"
## Farm and breeding (GDD "Zucht"): same seed, same nights; hybrids by element;
## unique Lingshou never breed; pens hold two; changing form makes a Lingshou stronger.


func _farm_with_pair(seed_value: int, a_sp: String, b_sp: String) -> GameState:
	var s := GameState.new_game("Test")
	s.seed = seed_value
	s.bells = 1
	s.add_lingshou("wawalurch", 5)
	var a := s.add_lingshou(a_sp, 8)
	var b := s.add_lingshou(b_sp, 8)
	a["sex"] = "f"
	b["sex"] = "m"
	Farm.assign(s, s.farm.find(a), 0)
	Farm.assign(s, s.farm.find(b), 0)
	a["happy"] = 90
	b["happy"] = 90
	return s


func test_same_seed_same_nights() -> void:
	var results := []
	for run in 2:
		var s := _farm_with_pair(1234, "bambaer", "bambaer")
		var log := []
		for night in 6:
			log.append(JSON.stringify(s.sleep()))
		results.append(log)
		assert_true(int(s.stats.get("hatched", 0)) >= 1, "an egg hatched")
	assert_eq(results[0], results[1], "reproducible nights")


func test_hybrid_from_same_element() -> void:
	var s := _farm_with_pair(7, "bambaer", "nebelaffe")
	for night in 5:
		s.sleep()
	var young := s.farm.filter(func(r): return r.get("stage", "") == "young" or r.has("parents"))
	assert_false(young.is_empty(), "young one hatched")
	assert_eq(young[0]["species"], "blattbaer", "wood hybrid")


func test_unique_ones_do_not_breed() -> void:
	var s := GameState.new_game("Test")
	var a := {"species": "qinglong", "sex": "f", "uid": "a"}
	var b := {"species": "qinglong", "sex": "m", "uid": "b"}
	assert_false(Farm.compatible(a, b), "guardians are unique")
	var c := {"species": "bambaer", "sex": "f", "uid": "c"}
	var d := {"species": "glutfasan", "sex": "m", "uid": "d"}
	assert_false(Farm.compatible(c, d), "different elements")


func test_pen_holds_two() -> void:
	var s := GameState.new_game("Test")
	s.bells = 1
	s.add_lingshou("wawalurch", 5)
	for i in 3:
		s.add_lingshou("reisquak", 5)
	var in_pen := Farm.residents(s, 0).size() + Farm.residents(s, 1).size()
	assert_eq(in_pen, 3, "three housed in two pens")
	assert_false(Farm.assign(s, 0, 0) and Farm.residents(s, 0).size() > 2, "never more than two")


func test_awakening_makes_stronger() -> void:
	var rec := BattleUnit.create("bambaer", 25, "x").to_record()
	rec["bond"] = 75
	assert_true(BattleUnit.can_awaken(rec))
	var before := BattleUnit.from_record(rec)
	rec["awakened"] = true
	var after := BattleUnit.from_record(rec)
	assert_true(after.atk > before.atk and after.max_hp > before.max_hp, "stronger")
	assert_false(BattleUnit.can_awaken(rec), "only once")
