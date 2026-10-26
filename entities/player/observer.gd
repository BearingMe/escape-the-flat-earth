class_name ObserverPlayer
extends Node3D

const WALK_SPEED_M_S: float = 60.0
const LOOK_SENSITIVITY: float = 0.0025
const MAX_VIEW_PITCH: float = 1.45

@export var peer_id: int = 0
@export var stable_id: String = ""
@export var display_name: String = "Observer"
@export var view_pitch: float = 0.0

var _local_yaw: float = 0.0
var _local_pitch: float = 0.0
var _wish_direction: Vector3 = Vector3.ZERO
var _e2e_drive: bool = false

@onready var _camera: Camera3D = %Camera3D
@onready var _name_label: Label3D = %NameLabel


func configure(new_peer_id: int, new_stable_id: String, new_display_name: String) -> void:
	peer_id = new_peer_id
	stable_id = new_stable_id
	display_name = new_display_name
	name = "Player_%d" % peer_id
	position = _spawn_position()


func _ready() -> void:
	add_to_group("network_players")
	_name_label.text = display_name
	_local_yaw = rotation.y
	_local_pitch = view_pitch
	var is_local_player: bool = (
		multiplayer.multiplayer_peer != null and peer_id == multiplayer.get_unique_id()
	)
	_camera.current = is_local_player
	_e2e_drive = OS.get_cmdline_user_args().has("--e2e-drive")
	if is_local_player and DisplayServer.get_name() != "headless":
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	if multiplayer.multiplayer_peer == null or peer_id != multiplayer.get_unique_id():
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.mouse_mode = (
			Input.MOUSE_MODE_VISIBLE
			if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
			else Input.MOUSE_MODE_CAPTURED
		)
	elif event is InputEventMouseButton and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_local_yaw = wrapf(_local_yaw - event.relative.x * LOOK_SENSITIVITY, -PI, PI)
		_local_pitch = clampf(
			_local_pitch - event.relative.y * LOOK_SENSITIVITY, -MAX_VIEW_PITCH, MAX_VIEW_PITCH
		)


func _physics_process(delta: float) -> void:
	if peer_id <= 0 or multiplayer.multiplayer_peer == null:
		return
	if multiplayer.is_server():
		if peer_id == multiplayer.get_unique_id():
			_wish_direction = _read_local_intent()
			rotation.y = _local_yaw
			view_pitch = _local_pitch
			_camera.rotation.x = _local_pitch
		position += _wish_direction * WALK_SPEED_M_S * delta
		return
	if peer_id == multiplayer.get_unique_id():
		_wish_direction = _read_local_intent()
		_camera.rotation = Vector3(_local_pitch, wrapf(_local_yaw - rotation.y, -PI, PI), 0.0)
		if multiplayer.multiplayer_peer != null:
			submit_movement_intent.rpc_id(1, _wish_direction, _local_yaw, _local_pitch)
	else:
		_camera.rotation.x = view_pitch


@rpc("any_peer", "call_remote", "unreliable", 1)
func submit_movement_intent(wish_direction: Vector3, yaw: float, pitch: float) -> void:
	if (
		multiplayer.multiplayer_peer == null
		or not multiplayer.is_server()
		or multiplayer.get_remote_sender_id() != peer_id
	):
		return
	if not wish_direction.is_finite() or not is_finite(yaw) or not is_finite(pitch):
		return
	if wish_direction.length_squared() > 1.0001:
		return
	_wish_direction = wish_direction
	_local_yaw = wrapf(yaw, -PI, PI)
	_local_pitch = clampf(pitch, -MAX_VIEW_PITCH, MAX_VIEW_PITCH)
	rotation.y = _local_yaw
	view_pitch = _local_pitch


func _read_local_intent() -> Vector3:
	var local_intent: Vector3 = Vector3.ZERO
	if _e2e_drive:
		local_intent.z = -1.0
	else:
		local_intent.x = (
			float(Input.is_physical_key_pressed(KEY_D))
			- float(Input.is_physical_key_pressed(KEY_A))
		)
		local_intent.y = (
			float(Input.is_physical_key_pressed(KEY_SPACE))
			- float(Input.is_physical_key_pressed(KEY_CTRL))
		)
		local_intent.z = (
			float(Input.is_physical_key_pressed(KEY_S))
			- float(Input.is_physical_key_pressed(KEY_W))
		)
	if local_intent.length_squared() > 1.0:
		local_intent = local_intent.normalized()
	return Basis(Vector3.UP, _local_yaw) * local_intent


func _spawn_position() -> Vector3:
	var config: WorldConfig = World.config
	return Vector3(0.0, config.disk_thickness_m * 0.5 + 20.0, -config.disk_radius_m * 0.35)
