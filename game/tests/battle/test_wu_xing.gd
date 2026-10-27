extends "res://tests/test_case.gd"
## Every overcoming pair (type advantage) and every generating pair (team bonus).

const OVERCOME_PAIRS := [["wood", "earth"], ["earth", "water"], ["water", "fire"], ["fire", "metal"], ["metal", "wood"]]
const GENERATE_PAIRS := [["wood", "fire"], ["fire", "earth"], ["earth", "metal"], ["metal", "water"], ["water", "wood"]]


func test_overcoming_gives_advantage() -> void:
	for p in OVERCOME_PAIRS:
		assert_almost_eq(WuXing.effectiveness(p[0], p[1]), 1.5, 0.0001, "%s vs %s" % p)


func test_overcome_attack_is_weakened() -> void:
	for p in OVERCOME_PAIRS:
		assert_almost_eq(WuXing.effectiveness(p[1], p[0]), 0.75, 0.0001, "%s vs %s" % [p[1], p[0]])


func test_other_pairs_are_neutral() -> void:
	for a in WuXing.ELEMENTS:
		assert_almost_eq(WuXing.effectiveness(a, a), 1.0, 0.0001, "%s vs itself" % a)
		assert_almost_eq(WuXing.effectiveness(WuXing.NEUTRAL, a), 1.0, 0.0001, "neutral vs %s" % a)
	for p in GENERATE_PAIRS:
		assert_almost_eq(WuXing.effectiveness(p[0], p[1]), 1.0, 0.0001, "generating %s->%s is not an advantage" % p)


func test_each_element_overcomes_exactly_one() -> void:
	for a in WuXing.ELEMENTS:
		var beaten := WuXing.ELEMENTS.filter(func(b): return WuXing.overcomes(a, b))
		assert_eq(beaten.size(), 1, a)


func test_generating_pairs_give_team_bonus_both_orders() -> void:
	for p in GENERATE_PAIRS:
		assert_almost_eq(WuXing.team_bonus(p[0], p[1]), 0.10, 0.0001, "%s+%s" % p)
		assert_almost_eq(WuXing.team_bonus(p[1], p[0]), 0.10, 0.0001, "%s+%s" % [p[1], p[0]])


func test_non_generating_pairs_have_no_bonus() -> void:
	for p in OVERCOME_PAIRS:
		assert_almost_eq(WuXing.team_bonus(p[0], p[1]), 0.0, 0.0001, "%s+%s" % p)
	for a in WuXing.ELEMENTS:
		assert_almost_eq(WuXing.team_bonus(a, a), 0.0, 0.0001, "%s+%s" % [a, a])


func test_resonance_doubles_team_bonus() -> void:
	for p in GENERATE_PAIRS:
		assert_almost_eq(WuXing.team_bonus(p[0], p[1], true), 0.20, 0.0001, "%s+%s" % p)
	assert_almost_eq(WuXing.team_bonus("wood", "earth", true), 0.0, 0.0001, "no pair, nothing to double")
