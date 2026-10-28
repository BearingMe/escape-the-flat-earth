extends GutTest

const VICTORY_SCENE: PackedScene = preload("res://ui/menu/victory_screen.tscn")

var _screen: VictoryScreen


func before_each() -> void:
	World.set_seed(17320508)
	World.escape_tracker.configure(5000.0)
	_screen = VICTORY_SCENE.instantiate() as VictoryScreen
	add_child_autofree(_screen)


func test_victory_screen_hidden_by_default() -> void:
	assert_false(_screen._panel.visible)


func test_victory_signal_triggers_display() -> void:
	# Trigger match concluded
	World.match_concluded.emit(1, "ESCAPE", "FOOT_VAULT")

	assert_true(_screen._panel.visible)
	assert_true(_screen._certificate_label.text.contains("Player_1"))
	assert_true(_screen._certificate_label.text.contains("FOOT_VAULT"))


func test_restart_button_resets_and_hides() -> void:
	World.match_concluded.emit(1, "ESCAPE", "FOOT_VAULT")
	assert_true(_screen._panel.visible)

	_screen._on_restart_pressed()
	assert_false(_screen._panel.visible)
