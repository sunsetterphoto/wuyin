extends SceneTree
## Minimal headless test runner (no add-on dependency).
## Runs every res://tests/**/test_*.gd: each script extends TestCase, every
## method named test_* is a test. Exit code 0 = all passed.
##
##   godot --headless --path game -s res://tests/run_tests.gd [-- filter]
## Tests may be coroutines (await); they may call skip("reason") when a
## prerequisite such as a running llama-server is missing.

const TestCase := preload("res://tests/test_case.gd")


## Collects engine/script errors so a test that aborts on a runtime error
## (GDScript just returns from the function) still counts as failed.
class ErrorCollector extends Logger:
	var errors: Array[String] = []
	var _mutex := Mutex.new()

	func _log_error(function: String, file: String, line: int, code: String, rationale: String,
			_editor_notify: bool, error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
		if error_type == ERROR_TYPE_WARNING:
			return  # warnings (e.g. from native plugins) don't fail tests
		_mutex.lock()
		errors.append("%s (%s:%d %s)" % [rationale if rationale else code, file.get_file(), line, function])
		_mutex.unlock()

	func _log_message(_message: String, _error: bool) -> void:
		pass


const SUITE_TIMEOUT_S := 300.0


func _initialize() -> void:
	# Guard against a coroutine test that never resumes.
	create_timer(SUITE_TIMEOUT_S, true, false, true).timeout.connect(func():
		printerr("FAIL suite timeout after %d s" % SUITE_TIMEOUT_S)
		quit(1))
	_run()


func _run() -> void:
	var filter := ""
	var user_args := OS.get_cmdline_user_args()
	if not user_args.is_empty():
		filter = user_args[0]
	var files := _find_tests("res://tests")
	files.sort()
	var passed := 0
	var skipped: Array[String] = []
	var failed: Array[String] = []
	var collector := ErrorCollector.new()
	OS.add_logger(collector)
	for path in files:
		var script: GDScript = load(path)
		if script == null or not script.can_instantiate():
			failed.append("%s\n    does not compile" % path.get_file())
			continue
		for method in script.get_script_method_list():
			var name: String = method["name"]
			if not name.begins_with("test_"):
				continue
			if filter != "" and not (filter in path or filter in name):
				continue
			var case: TestCase = script.new()
			if OS.has_environment("WUYIN_TEST_VERBOSE"):
				print("RUN ", path.get_file(), "::", name)
			var errors_before := collector.errors.size()
			await case.call(name)
			for i in range(errors_before, collector.errors.size()):
				case.failures.append("runtime error: " + collector.errors[i])
			if case.skip_reason != "" and case.failures.is_empty():
				skipped.append("%s::%s (%s)" % [path.get_file(), name, case.skip_reason])
			elif case.failures.is_empty():
				passed += 1
			else:
				failed.append("%s::%s\n    %s" % [path.get_file(), name, "\n    ".join(case.failures)])
	for f in failed:
		printerr("FAIL ", f)
	for s in skipped:
		print("SKIP ", s)
	print("TESTS passed=%d failed=%d skipped=%d" % [passed, failed.size(), skipped.size()])
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
