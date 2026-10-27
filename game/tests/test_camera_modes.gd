extends "res://tests/test_case.gd"
## M0.6: classic 2D is always scaled by a whole number.

const TestMap := preload("res://scripts/world/test_map.gd")


func test_classic_scale_is_whole_and_fits() -> void:
	var cases := {Vector2(1280, 720): 2, Vector2(1920, 1080): 3, Vector2(2400, 1080): 3,
		Vector2(2560, 1440): 4, Vector2(3200, 1440): 4, Vector2(800, 480): 1, Vector2(1280, 800): 2}
	for screen in cases:
		var f := TestMap.classic_scale(screen)
		assert_eq(f, cases[screen], str(screen))
		assert_true(TestMap.CLASSIC_RES.x * f <= screen.x and TestMap.CLASSIC_RES.y * f <= screen.y, "fits %s" % str(screen))
