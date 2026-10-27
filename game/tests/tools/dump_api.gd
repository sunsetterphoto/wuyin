extends SceneTree
## Prints methods, properties and signals of classes whose name contains the filter.
##   godot --headless --path game -s res://tests/tools/dump_api.gd -- NobodyWho


func _initialize() -> void:
	var needle: String = OS.get_cmdline_user_args()[0] if not OS.get_cmdline_user_args().is_empty() else "NobodyWho"
	var classes := Array(ClassDB.get_class_list()).filter(func(c): return needle in c)
	classes.sort()
	for c in classes:
		print("== %s (extends %s)" % [c, ClassDB.get_parent_class(c)])
		for s in ClassDB.class_get_signal_list(c, true):
			print("  signal %s(%s)" % [s["name"], ", ".join(s["args"].map(func(a): return a["name"]))])
		for p in ClassDB.class_get_property_list(c, true):
			if p["usage"] & PROPERTY_USAGE_EDITOR or p["usage"] & PROPERTY_USAGE_STORAGE:
				print("  prop %s: %s" % [p["name"], type_string(p["type"])])
		for m in ClassDB.class_get_method_list(c, true):
			var args := ", ".join(m["args"].map(func(a): return "%s: %s" % [a["name"], type_string(a["type"]) if a["class_name"] == "" else a["class_name"]]))
			var ret: Dictionary = m["return"]
			print("  %sfunc %s(%s) -> %s" % ["static " if m["flags"] & METHOD_FLAG_STATIC else "", m["name"], args,
				ret["class_name"] if ret["class_name"] != "" else type_string(ret["type"])])
	quit()
