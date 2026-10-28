class_name VictoryScreen
extends CanvasLayer

signal restart_requested

@onready var _panel: Control = %VictoryPanel
@onready var _certificate_label: Label = %CertificateLabel
@onready var _restart_button: Button = %RestartButton
@onready var _dismiss_button: Button = %DismissButton


func _ready() -> void:
	if is_instance_valid(_panel):
		_panel.visible = false
	if not World.match_concluded.is_connected(_on_match_concluded):
		World.match_concluded.connect(_on_match_concluded)
	if is_instance_valid(_restart_button):
		_restart_button.pressed.connect(_on_restart_pressed)
	if is_instance_valid(_dismiss_button):
		_dismiss_button.pressed.connect(_on_dismiss_pressed)


func display_victory(summary: VictorySummary) -> void:
	if summary == null:
		return
	if is_instance_valid(_certificate_label):
		_certificate_label.text = summary.certificate_text
	if is_instance_valid(_panel):
		_panel.visible = true


func hide_victory() -> void:
	if is_instance_valid(_panel):
		_panel.visible = false


func _on_match_concluded(winner_id: int, reason: String, strategy: String) -> void:
	var winner_display: String = "Player_%d" % winner_id
	var summary: VictorySummary = VictorySummary.create_summary(
		winner_id, winner_display, reason, strategy, World.match_time_sec
	)
	display_victory(summary)


func _on_restart_pressed() -> void:
	hide_victory()
	restart_requested.emit()
	if World.has_host_authority():
		World.set_seed(World.config.world_seed)


func _on_dismiss_pressed() -> void:
	hide_victory()
