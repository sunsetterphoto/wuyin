extends "res://tests/test_case.gd"
## Terraces must never cut off a part of a map: every spawn, warp, person and
## object stays reachable from the first spawn with the step rule of World._free.

func test_every_place_reachable_over_steps() -> void:
	for id in MapData.all_ids():
		var m := MapData.load_map(id)
		if m.def.get("heights", []).is_empty():
			continue
		var start: Vector2 = m.spawn(m.def["spawns"].keys()[0])
		var from := Vector2i(roundi(start.x), roundi(start.y))
		var targets: Array[Vector2i] = []
		for s in m.def["spawns"].values():
			targets.append(Vector2i(int(s[0]), int(s[1])))
		for w in m.def.get("warps", []):
			targets.append(Vector2i(int(w["rect"][0]), int(w["rect"][1])))
		for t in targets:
			if t != from and m.walkable(t.x, t.y):
				assert_false(m.path(from, t, 20000).is_empty(), "%s: %s reachable from %s" % [id, t, from])
