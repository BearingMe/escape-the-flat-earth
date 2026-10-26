extends SceneTree

const GUT_SCRIPT_PATH: String = "res://addons/gut/gut_cmdln.gd"
const NO_TESTS_MARKER: String = "Nothing was run."


func _initialize() -> void:
	if _count_test_scripts() == 0:
		push_error("No GUT tests found in tests/unit or tests/integration.")
		quit(1)
		return

	var output: Array = []
	var project_path: String = ProjectSettings.globalize_path("res://").trim_suffix("/")
	var exit_code: int = OS.execute(
		OS.get_executable_path(),
		PackedStringArray(["--headless", "--path", project_path, "-s", GUT_SCRIPT_PATH, "-gexit"]),
		output,
		true
	)
	var output_text: String = ""
	if not output.is_empty():
		output_text = str(output[0])
		print(output_text)

	if exit_code != 0:
		quit(1)
		return
	if output_text.contains(NO_TESTS_MARKER):
		push_error("GUT discovered no tests; refusing to report a passing suite.")
		quit(1)
		return

	quit(0)


func _count_test_scripts() -> int:
	var test_count: int = 0
	for test_directory: String in ["res://tests/unit", "res://tests/integration"]:
		test_count += _count_test_scripts_in(test_directory)
	return test_count


func _count_test_scripts_in(path: String) -> int:
	var directory: DirAccess = DirAccess.open(path)
	if directory == null:
		return 0

	var test_count: int = 0
	directory.list_dir_begin()
	var entry: String = directory.get_next()
	while not entry.is_empty():
		if entry != "." and entry != "..":
			if directory.current_is_dir():
				test_count += _count_test_scripts_in(path.path_join(entry))
			elif entry.begins_with("test_") and entry.ends_with(".gd"):
				test_count += 1
		entry = directory.get_next()
	directory.list_dir_end()
	return test_count
