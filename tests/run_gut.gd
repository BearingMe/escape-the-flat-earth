extends SceneTree

const GUT_RUNNER_SCENE: PackedScene = preload("res://addons/gut/gui/GutRunner.tscn")
const GUT_CONFIG_SCRIPT: Script = preload("res://addons/gut/gut_config.gd")


func _initialize() -> void:
	if _count_test_scripts() == 0:
		push_error("No GUT tests found in tests/unit or tests/integration.")
		quit(1)
		return
	call_deferred("_run_suite")


func _run_suite() -> void:
	var config: Object = GUT_CONFIG_SCRIPT.new()
	var config_result: int = config.load_options("res://.gutconfig.json")
	if config_result < 0:
		push_error("Could not load .gutconfig.json: %s" % config_result)
		quit(1)
		return
	config.options.should_exit = true
	config.options.log_level = 0
	config.options.disable_colors = true
	var runner: Node = GUT_RUNNER_SCENE.instantiate()
	root.add_child(runner)
	runner.set_gut_config(config)
	var gut: Object = runner.get_gut()
	var result_callback: Callable = _report_suite_result.bind(gut)
	if not gut.end_run.is_connected(result_callback):
		gut.end_run.connect(result_callback)
	runner.run_tests(false)


func _report_suite_result(gut: Object) -> void:
	var test_count: int = gut.get_test_count()
	var pass_count: int = gut.get_pass_count()
	var fail_count: int = gut.get_fail_count()
	print("GUT_RESULT tests=%d passed=%d failed=%d" % [test_count, pass_count, fail_count])
	if test_count == 0:
		push_error("GUT discovered no runnable tests; refusing to report a passing suite.")
		quit(1)


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
