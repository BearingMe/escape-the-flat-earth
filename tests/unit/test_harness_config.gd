extends GutTest


func test_gut_discovers_only_unit_and_integration_suites() -> void:
	var config: Dictionary = _load_gut_config()
	assert_eq(config.get("dirs"), ["res://tests/unit", "res://tests/integration"])
	assert_true(config.get("include_subdirs", false))
	assert_eq(config.get("prefix"), "test_")
	assert_eq(config.get("suffix"), ".gd")


func test_unexpected_engine_and_push_errors_fail_the_suite() -> void:
	var config: Dictionary = _load_gut_config()
	var failure_types: Array = config.get("failure_error_types", [])
	assert_true(failure_types.has("engine"))
	assert_true(failure_types.has("gut"))
	assert_true(failure_types.has("push_error"))
	assert_false(config.get("no_error_tracking", true))


func test_gut_version_is_pinned_and_enabled() -> void:
	var gut_plugin: ConfigFile = ConfigFile.new()
	assert_eq(gut_plugin.load("res://addons/gut/plugin.cfg"), OK)
	assert_eq(gut_plugin.get_value("plugin", "version"), "9.7.1")

	var project_config: ConfigFile = ConfigFile.new()
	assert_eq(project_config.load("res://project.godot"), OK)
	var enabled_plugins: PackedStringArray = project_config.get_value("editor_plugins", "enabled")
	assert_true(enabled_plugins.has("res://addons/gut/plugin.cfg"))


func _load_gut_config() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://.gutconfig.json"))
	assert_true(parsed is Dictionary, "GUT config must be valid JSON object data.")
	if not (parsed is Dictionary):
		return {}
	return parsed
