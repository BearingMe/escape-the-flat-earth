class_name ObserverPlayer
extends CharacterBody3D

const WALK_SPEED_M_S: float = 6.0
const SPRINT_SPEED_M_S: float = 9.0
const GROUND_ACCELERATION_M_S2: float = 24.0
const GROUND_BRAKING_M_S2: float = 36.0
const AIR_ACCELERATION_M_S2: float = 6.0
const AIR_BRAKING_M_S2: float = 2.0
const JUMP_SPEED_M_S: float = 5.5
const MAX_FALL_SPEED_M_S: float = 55.0
const REMOTE_INTENT_TIMEOUT_USEC: int = 350_000
const MAX_E2E_INTENT_DELAY_USEC: int = 1_000_000
const POSITION_SNAP_DISTANCE_M: float = 6.0
const POSITION_INTERPOLATION_SPEED: float = 12.0
const SPAWN_RING_RADIUS_M: float = 3.0
const LOOK_SENSITIVITY: float = 0.0025
const CONTROLLER_LOOK_SENSITIVITY: float = 2.0
const CONTROLLER_LOOK_DEADZONE: float = 0.18
const MAX_VIEW_PITCH: float = 1.45

@export var peer_id: int = 0
@export var stable_id: String = ""
@export var display_name: String = "Observer"
@export var view_pitch: float = 0.0
@export var replicated_position: Vector3 = Vector3.ZERO
@export_range(0.0001, 0.02, 0.0001) var mouse_sensitivity: float = LOOK_SENSITIVITY
@export_range(0.1, 10.0, 0.1) var controller_sensitivity: float = CONTROLLER_LOOK_SENSITIVITY

var _local_yaw: float = 0.0
var _local_pitch: float = 0.0
var _wish_direction: Vector3 = Vector3.ZERO
var _local_move_direction: Vector3 = Vector3.ZERO
var _wants_sprint: bool = false
var _jump_requested: bool = false
var _jump_was_pressed: bool = false
var _last_intent_usec: int = 0
var _movement_enabled: bool = true
var _e2e_intent_delay_usec: int = 0
var _pending_local_intents: Array[Dictionary] = []
var _e2e_drive: bool = false
var _e2e_camera_look: bool = false
var _e2e_camera_look_applied: bool = false

@onready var _camera: Camera3D = %Camera3D
@onready var _body: MeshInstance3D = %Body
@onready var _name_label: Label3D = %NameLabel


func configure(new_peer_id: int, new_stable_id: String, new_display_name: String) -> void:
	peer_id = new_peer_id
	stable_id = new_stable_id
	display_name = new_display_name
	name = "Player_%d" % peer_id
	position = _spawn_position(new_stable_id)
	replicated_position = position


func _ready() -> void:
	add_to_group("network_players")
	_name_label.text = display_name
	_local_yaw = rotation.y
	_local_pitch = view_pitch
	var is_local_player: bool = _is_local_player()
	_camera.current = is_local_player
	_body.visible = not is_local_player
	_name_label.visible = not is_local_player
	_e2e_drive = OS.get_cmdline_user_args().has("--e2e-drive")
	_e2e_camera_look = OS.get_cmdline_user_args().has("--e2e-camera-look")
	_e2e_intent_delay_usec = _read_e2e_intent_delay_usec()
	if is_local_player and DisplayServer.get_name() != "headless":
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	if not _is_local_player():
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
		_apply_mouse_motion(event.screen_relative)


func _process(_delta: float) -> void:
	if not is_instance_valid(_camera):
		return
	if _is_local_player() and not _camera.current:
		_camera.make_current()
	elif not _is_local_player() and _camera.current:
		_camera.clear_current()
	if multiplayer.multiplayer_peer != null and not multiplayer.is_server():
		var position_error: Vector3 = replicated_position - position
		if position_error.length() >= POSITION_SNAP_DISTANCE_M:
			position = replicated_position
		else:
			position = position.lerp(
				replicated_position, clampf(_delta * POSITION_INTERPOLATION_SPEED, 0.0, 1.0)
			)


func _physics_process(delta: float) -> void:
	if peer_id <= 0 or multiplayer.multiplayer_peer == null:
		return
	if _is_local_player():
		if _e2e_camera_look and not _e2e_camera_look_applied:
			_apply_mouse_motion(Vector2(40.0, -20.0))
			_e2e_camera_look_applied = true
		_update_controller_look(delta)
	if multiplayer.is_server():
		if not _movement_enabled:
			_local_move_direction = Vector3.ZERO
			_wish_direction = Vector3.ZERO
			_wants_sprint = false
			_jump_requested = false
			velocity.x = 0.0
			velocity.z = 0.0
		elif peer_id == multiplayer.get_unique_id():
			_read_local_movement_intent()
			_wish_direction = Basis(Vector3.UP, _local_yaw) * _local_move_direction
			rotation.y = _local_yaw
			view_pitch = _local_pitch
		elif Time.get_ticks_usec() - _last_intent_usec > REMOTE_INTENT_TIMEOUT_USEC:
			_local_move_direction = Vector3.ZERO
			_wish_direction = Vector3.ZERO
			_wants_sprint = false
			_jump_requested = false
		_simulate_authoritative_movement(delta)
		if _is_local_player():
			_camera.rotation.x = _local_pitch
		else:
			_camera.rotation.x = view_pitch
		return
	if peer_id == multiplayer.get_unique_id():
		_read_local_movement_intent()
		_camera.rotation = Vector3(_local_pitch, wrapf(_local_yaw - rotation.y, -PI, PI), 0.0)
		_queue_or_send_local_intent()
		_jump_requested = false
	else:
		_camera.rotation.x = view_pitch


@rpc("any_peer", "call_remote", "unreliable", 1)
func submit_movement_intent(
	local_direction: Vector3, wants_sprint: bool, jump_requested: bool, yaw: float, pitch: float
) -> void:
	if (
		multiplayer.multiplayer_peer == null
		or not multiplayer.is_server()
		or multiplayer.get_remote_sender_id() != peer_id
		or not _movement_enabled
	):
		return
	if not is_valid_movement_intent(local_direction, yaw, pitch):
		return
	_local_yaw = wrapf(yaw, -PI, PI)
	_local_pitch = clampf(pitch, -MAX_VIEW_PITCH, MAX_VIEW_PITCH)
	_local_move_direction = local_direction
	_wish_direction = Basis(Vector3.UP, _local_yaw) * _local_move_direction
	_wants_sprint = wants_sprint
	if jump_requested:
		_jump_requested = true
	_last_intent_usec = Time.get_ticks_usec()
	rotation.y = _local_yaw
	view_pitch = _local_pitch


func _read_local_movement_intent() -> void:
	_local_move_direction = Vector3.ZERO
	_wants_sprint = false
	var jump_pressed: bool = false
	if _e2e_drive:
		_local_move_direction.z = -1.0
	else:
		_local_move_direction.x = (
			float(Input.is_physical_key_pressed(KEY_D))
			- float(Input.is_physical_key_pressed(KEY_A))
		)
		_local_move_direction.z = (
			float(Input.is_physical_key_pressed(KEY_S))
			- float(Input.is_physical_key_pressed(KEY_W))
		)
		jump_pressed = Input.is_physical_key_pressed(KEY_SPACE)
		_wants_sprint = Input.is_physical_key_pressed(KEY_SHIFT)
	_local_move_direction.y = 0.0
	if _local_move_direction.length_squared() > 1.0:
		_local_move_direction = _local_move_direction.normalized()
	_jump_requested = jump_pressed and not _jump_was_pressed
	_jump_was_pressed = jump_pressed


func _queue_or_send_local_intent() -> void:
	var intent: Dictionary = {
		"direction": _local_move_direction,
		"sprint": _wants_sprint,
		"jump": _jump_requested,
		"yaw": _local_yaw,
		"pitch": _local_pitch,
		"sent_usec": Time.get_ticks_usec()
	}
	if _e2e_intent_delay_usec <= 0:
		_send_movement_intent(intent)
		return
	_pending_local_intents.append(intent)
	var now_usec: int = Time.get_ticks_usec()
	while not _pending_local_intents.is_empty():
		var oldest_intent: Dictionary = _pending_local_intents.front()
		if now_usec - int(oldest_intent["sent_usec"]) < _e2e_intent_delay_usec:
			return
		_pending_local_intents.pop_front()
		_send_movement_intent(oldest_intent)


func _send_movement_intent(intent: Dictionary) -> void:
	if multiplayer.multiplayer_peer == null:
		return
	var local_direction: Vector3 = intent["direction"]
	var wants_sprint: bool = intent["sprint"]
	var jump_requested: bool = intent["jump"]
	var yaw: float = intent["yaw"]
	var pitch: float = intent["pitch"]
	submit_movement_intent.rpc_id(1, local_direction, wants_sprint, jump_requested, yaw, pitch)


func _read_e2e_intent_delay_usec() -> int:
	for argument: String in OS.get_cmdline_user_args():
		if not argument.begins_with("--e2e-intent-delay-ms="):
			continue
		var value: String = argument.trim_prefix("--e2e-intent-delay-ms=")
		if value.is_valid_int():
			return clampi(value.to_int(), 0, MAX_E2E_INTENT_DELAY_USEC / 1000) * 1000
	return 0


func _simulate_authoritative_movement(delta: float) -> void:
	var is_grounded: bool = is_on_floor()
	var target_speed: float = SPRINT_SPEED_M_S if _wants_sprint else WALK_SPEED_M_S
	var acceleration: float = GROUND_ACCELERATION_M_S2 if is_grounded else AIR_ACCELERATION_M_S2
	if _wish_direction.is_zero_approx():
		acceleration = GROUND_BRAKING_M_S2 if is_grounded else AIR_BRAKING_M_S2
	velocity = approach_horizontal_velocity(
		velocity, _local_move_direction, _local_yaw, target_speed, acceleration, delta
	)
	if is_grounded:
		if _jump_requested:
			velocity.y = JUMP_SPEED_M_S
		else:
			velocity.y = 0.0
	else:
		var gravity_m_s2: float = float(ProjectSettings.get_setting("physics/3d/default_gravity"))
		velocity.y = maxf(velocity.y - gravity_m_s2 * delta, -MAX_FALL_SPEED_M_S)
	_jump_requested = false
	move_and_slide()
	replicated_position = position


func set_movement_enabled(enabled: bool) -> void:
	_movement_enabled = enabled
	if not enabled:
		_local_move_direction = Vector3.ZERO
		_wish_direction = Vector3.ZERO
		_wants_sprint = false
		_jump_requested = false
		velocity.x = 0.0
		velocity.z = 0.0


static func approach_horizontal_velocity(
	current_velocity: Vector3,
	local_direction: Vector3,
	yaw: float,
	target_speed: float,
	acceleration: float,
	delta: float
) -> Vector3:
	if (
		not current_velocity.is_finite()
		or not local_direction.is_finite()
		or not is_finite(yaw)
		or not is_finite(target_speed)
		or not is_finite(acceleration)
		or not is_finite(delta)
	):
		return Vector3.ZERO
	var bounded_direction: Vector3 = Vector3(local_direction.x, 0.0, local_direction.z)
	if bounded_direction.length_squared() > 1.0:
		bounded_direction = bounded_direction.normalized()
	var target_velocity: Vector3 = (
		Basis(Vector3.UP, yaw) * bounded_direction * maxf(target_speed, 0.0)
	)
	var current_horizontal: Vector3 = Vector3(current_velocity.x, 0.0, current_velocity.z)
	var next_horizontal: Vector3 = current_horizontal.move_toward(
		target_velocity, maxf(acceleration, 0.0) * maxf(delta, 0.0)
	)
	return Vector3(next_horizontal.x, current_velocity.y, next_horizontal.z)


static func is_valid_movement_intent(local_direction: Vector3, yaw: float, pitch: float) -> bool:
	return (
		local_direction.is_finite()
		and absf(local_direction.y) <= 0.001
		and local_direction.length_squared() <= 1.0001
		and is_finite(yaw)
		and is_finite(pitch)
	)


func _is_local_player() -> bool:
	return multiplayer.multiplayer_peer != null and peer_id == multiplayer.get_unique_id()


func is_camera_current() -> bool:
	return is_instance_valid(_camera) and _camera.current


func has_applied_e2e_camera_look() -> bool:
	return _e2e_camera_look_applied


func e2e_intent_delay_msec() -> int:
	return _e2e_intent_delay_usec / 1000


func _apply_look_delta(look_delta: Vector2) -> void:
	_local_yaw = wrapf(_local_yaw - look_delta.x, -PI, PI)
	_local_pitch = clampf(_local_pitch - look_delta.y, -MAX_VIEW_PITCH, MAX_VIEW_PITCH)


func _apply_mouse_motion(screen_relative: Vector2) -> void:
	_apply_look_delta(screen_relative * mouse_sensitivity)


func _update_controller_look(delta: float) -> void:
	var connected_joypads: Array[int] = Input.get_connected_joypads()
	if connected_joypads.is_empty():
		return
	var device_id: int = connected_joypads[0]
	var stick: Vector2 = Vector2(
		Input.get_joy_axis(device_id, JOY_AXIS_RIGHT_X),
		Input.get_joy_axis(device_id, JOY_AXIS_RIGHT_Y)
	)
	var look_input: Vector2 = shape_controller_look(stick)
	_apply_look_delta(look_input * controller_sensitivity * delta)


static func shape_controller_look(stick: Vector2) -> Vector2:
	if not stick.is_finite():
		return Vector2.ZERO
	var magnitude: float = minf(stick.length(), 1.0)
	if magnitude <= CONTROLLER_LOOK_DEADZONE:
		return Vector2.ZERO
	var remapped_magnitude: float = (
		(magnitude - CONTROLLER_LOOK_DEADZONE) / (1.0 - CONTROLLER_LOOK_DEADZONE)
	)
	return stick.normalized() * remapped_magnitude


func _spawn_position(new_stable_id: String) -> Vector3:
	var config: WorldConfig = World.config
	var spawn_sequence: int = maxi(1, new_stable_id.get_slice("_", 2).to_int()) - 1
	var spawn_angle: float = (
		TAU * float(spawn_sequence % config.max_players) / float(config.max_players)
	)
	var spawn_x: float = cos(spawn_angle) * SPAWN_RING_RADIUS_M
	var spawn_z: float = sin(spawn_angle) * SPAWN_RING_RADIUS_M
	var terrain_generator: DiskTerrainGenerator = DiskTerrainGenerator.new()
	var terrain_height: float = 0.0
	if terrain_generator.configure(config, config.world_seed) == OK:
		terrain_height = terrain_generator.sample_mesh_cell_max_height(spawn_x, spawn_z)
	return Vector3(spawn_x, config.disk_thickness_m * 0.5 + terrain_height + 0.1, spawn_z)
