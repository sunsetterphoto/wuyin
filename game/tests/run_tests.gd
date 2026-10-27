extends SceneTree
## Minimal headless test runner (no add-on dependency).
## Runs every res://tests/**/test_*.gd: each script extends TestCase, every
## method named test_* is a test. Exit code 0 = all passed.
##
##   godot --headless --path game -s res://tests/run_tests.gd [-- filter]

const TestCase := preload("res://tests/test_case.gd")


func _init() -> void:
	var filter := ""
	var user_args := OS.get_cmdline_user_args()
	if not user_args.is_empty():
		filter = user_args[0]
	var files := _find_tests("res://tests")
	files.sort()
	var passed := 0
	var failed: Array[String] = []
	for path in files:
		var script: GDScript = load(path)
		for method in script.get_script_method_list():
			var name: String = method["name"]
			if not name.begins_with("test_"):
				continue
			if filter != "" and not (filter in path or filter in name):
				continue
			var case: TestCase = script.new()
			case.call(name)
			if case.failures.is_empty():
				passed += 1
			else:
				failed.append("%s::%s\n    %s" % [path.get_file(), name, "\n    ".join(case.failures)])
	for f in failed:
		printerr("FAIL ", f)
	print("TESTS passed=%d failed=%d" % [passed, failed.size()])
	quit(0 if failed.is_empty() and passed > 0 else 1)


func _find_tests(dir_path: String) -> Array[String]:
	var out: Array[String] = []
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return out
	for sub in dir.get_directories():
		out.append_array(_find_tests(dir_path.path_join(sub)))
	for file in dir.get_files():
		if file.begins_with("test_") and file.ends_with(".gd"):
			out.append(dir_path.path_join(file))
	return out
