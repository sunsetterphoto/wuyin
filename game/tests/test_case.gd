extends RefCounted
## Base class for tests run by run_tests.gd. Assertions record failures
## instead of aborting, so one test reports every broken expectation.

var failures: Array[String] = []


func assert_true(value: bool, msg := "expected true") -> void:
	if not value:
		failures.append(msg)


func assert_false(value: bool, msg := "expected false") -> void:
	if value:
		failures.append(msg)


func assert_eq(actual: Variant, expected: Variant, msg := "") -> void:
	if typeof(actual) != typeof(expected) or actual != expected:
		failures.append("%sexpected %s, got %s" % [msg + ": " if msg else "", var_to_str(expected), var_to_str(actual)])


func assert_ne(actual: Variant, unexpected: Variant, msg := "") -> void:
	if typeof(actual) == typeof(unexpected) and actual == unexpected:
		failures.append("%sdid not expect %s" % [msg + ": " if msg else "", var_to_str(unexpected)])


func assert_almost_eq(actual: float, expected: float, tolerance := 0.0001, msg := "") -> void:
	if absf(actual - expected) > tolerance:
		failures.append("%sexpected %f ± %f, got %f" % [msg + ": " if msg else "", expected, tolerance, actual])
