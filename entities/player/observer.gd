class_name ObserverPlayer
extends CharacterBody3D

signal health_changed(new_health: float, max_health: float)
signal player_died(killer_peer_id: int)

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
const DEFAULT_MAX_HEALTH: float = 100.0

@export var peer_id: int = 0
@export var stable_id: String = ""
@export var display_name: String = "Observer"
@export var view_pitch: float = 0.0
@export var replicated_position: Vector3 = Vector3.ZERO
@export_range(0.0001, 0.02, 0.0001) var mouse_sensitivity: float = LOOK_SENSITIVITY
@export_range(0.1, 10.0, 0.1) var controller_sensitivity: float = CONTROLLER_LOOK_SENSITIVITY
@export var max_health: float = DEFAULT_MAX_HEALTH
@export var health: float = DEFAULT_MAX_HEALTH

var held_prop: PhysicalProp = null
var is_alive: bool = true

var _local_yaw: float = 0.0
var _local_pitch: float = 0.0
var _wish_direction: Vector3 = Vector3.ZERO
var _local_move_direction: Vector3 = Vector3.ZERO
var _wants_sprint: bool = false
var _jump_requested: bool = false
var _jump_was_pressed: bool = false
var _interact_was_pressed: bool = false
var _throw_was_pressed: bool = false
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
		if event.button_index == MOUSE_BUTTON_LEFT:
			_handle_primary_action()
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			submit_adjust_distance_intent.rpc_id(1, 0.3)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			submit_adjust_distance_intent.rpc_id(1, -0.3)
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_E:
			_handle_interact_action()
		elif event.keycode == KEY_F:
			_handle_throw_action()
	elif event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_apply_mouse_motion(event.screen_relative)


func _handle_interact_action() -> void:
	if held_prop != null and is_instance_valid(held_prop):
		submit_release_intent.rpc_id(1)
	else:
		_raycast_and_grab()


func _handle_throw_action() -> void:
	if held_prop != null and is_instance_valid(held_prop):
		var aim_dir: Vector3 = (
			-_camera.global_transform.basis.z if is_instance_valid(_camera) else -transform.basis.z
		)
		submit_throw_intent.rpc_id(1, aim_dir)


func _handle_primary_action() -> void:
	if held_prop != null and is_instance_valid(held_prop):
		_handle_throw_action()
	else:
		_raycast_and_grab()


func _raycast_and_grab() -> void:
	if not is_instance_valid(_camera):
		return
	var space_state: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var ray_origin: Vector3 = _camera.global_position
	var ray_end: Vector3 = ray_origin - _camera.global_transform.basis.z * 4.5
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	query.exclude = [get_rid()]
	var hit: Dictionary = space_state.intersect_ray(query)
	if not hit.is_empty():
		var collider: Object = hit.get("collider")
		if collider is PhysicalProp:
			submit_grab_intent.rpc_id(1, (collider as PhysicalProp).get_path())


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
	if held_prop != null and is_instance_valid(held_prop):
		if held_prop.definition != null and held_prop.definition.is_two_handed:
			_wants_sprint = false
			target_speed = minf(target_speed, WALK_SPEED_M_S * 0.75)
		elif held_prop.mass > 25.0:
			target_speed *= clampf(1.0 - (held_prop.mass - 25.0) * 0.005, 0.5, 1.0)

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


func apply_damage(amount: float, dealer_peer_id: int) -> void:
	if not multiplayer.is_server() or not is_alive:
		return
	if amount <= 0.0:
		return
	health = maxf(health - amount, 0.0)
	health_changed.emit(health, max_health)
	if health <= 0.0:
		is_alive = false
		player_died.emit(dealer_peer_id)
		_release_held_prop()


func grab_prop_host(prop: PhysicalProp) -> bool:
	if not multiplayer.is_server() or not is_alive or prop == null:
		return false
	if held_prop != null:
		_release_held_prop()
	var success: bool = prop.grab(peer_id, self, 2.5)
	if success:
		held_prop = prop
	return success


func throw_held_prop_host(aim_direction: Vector3) -> void:
	if not multiplayer.is_server() or held_prop == null or not is_instance_valid(held_prop):
		return
	held_prop.throw_prop(peer_id, aim_direction, velocity)
	held_prop = null


func release_held_prop_host() -> void:
	_release_held_prop()


func _release_held_prop() -> void:
	if held_prop != null and is_instance_valid(held_prop):
		held_prop.release(peer_id)
		held_prop = null


func _exit_tree() -> void:
	_release_held_prop()


@rpc("any_peer", "call_remote", "reliable")
func submit_grab_intent(prop_path: NodePath) -> void:
	if not multiplayer.is_server() or multiplayer.get_remote_sender_id() != peer_id or not is_alive:
		return
	var prop: PhysicalProp = get_node_or_null(prop_path) as PhysicalProp
	if prop == null:
		return
	var max_reach: float = (
		prop.definition.max_grab_distance_m + 1.5 if prop.definition != null else 5.0
	)
	if global_position.distance_to(prop.global_position) > max_reach:
		return
	grab_prop_host(prop)


@rpc("any_peer", "call_remote", "reliable")
func submit_release_intent() -> void:
	if not multiplayer.is_server() or multiplayer.get_remote_sender_id() != peer_id:
		return
	release_held_prop_host()


@rpc("any_peer", "call_remote", "reliable")
func submit_throw_intent(aim_direction: Vector3) -> void:
	if not multiplayer.is_server() or multiplayer.get_remote_sender_id() != peer_id:
		return
	throw_held_prop_host(aim_direction)


@rpc("any_peer", "call_remote", "unreliable")
func submit_adjust_distance_intent(delta_distance: float) -> void:
	if not multiplayer.is_server() or multiplayer.get_remote_sender_id() != peer_id:
		return
	if held_prop != null and is_instance_valid(held_prop):
		held_prop.adjust_distance(peer_id, delta_distance)


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
