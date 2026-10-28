class_name VehicleEntity
extends RigidBody3D

signal vehicle_rammed(target: Node, damage: float)
signal player_mounted(peer_id: int, is_driver: bool)
signal player_dismounted(peer_id: int)

const SUSPENSION_REST_LENGTH_M: float = 0.75
const SPRING_STIFFNESS: float = 4800.0
const SPRING_DAMPING: float = 320.0
const TIRE_GRIP: float = 14.0

@export var max_fuel: float = 100.0
@export var fuel: float = 100.0
@export var engine_power: float = 1500.0
@export var fuel_burn_rate: float = 0.5

var driver_peer_id: int = 0
var passenger_peer_id: int = 0

var _throttle: float = 0.0
var _steer: float = 0.0
var _braking: bool = false
var _driver_player: ObserverPlayer = null
var _passenger_player: ObserverPlayer = null
var _prev_linear_vel: Vector3 = Vector3.ZERO
var _prev_suspension_lengths: Dictionary = {}

@onready var _driver_seat: Marker3D = %DriverSeat
@onready var _passenger_seat: Marker3D = %PassengerSeat
@onready var _wheel_fl: RayCast3D = %WheelFL
@onready var _wheel_fr: RayCast3D = %WheelFR
@onready var _wheel_rl: RayCast3D = %WheelRL
@onready var _wheel_rr: RayCast3D = %WheelRR


func _ready() -> void:
	contact_monitor = true
	max_contacts_reported = 4
	body_entered.connect(_on_body_entered)


func set_driving_input(throttle: float, steer: float, brake: bool) -> void:
	_throttle = clampf(throttle, -1.0, 1.0)
	_steer = clampf(steer, -1.0, 1.0)
	_braking = brake


func mount_player(player: ObserverPlayer, as_driver: bool) -> bool:
	if player == null or not player.is_alive:
		return false

	if as_driver:
		if driver_peer_id > 0:
			return false
		driver_peer_id = player.peer_id
		_driver_player = player
	else:
		if passenger_peer_id > 0:
			return false
		passenger_peer_id = player.peer_id
		_passenger_player = player

	player.set_movement_enabled(false)
	player_mounted.emit(player.peer_id, as_driver)
	sleeping = false
	return true


func dismount_player(peer_id: int) -> bool:
	var dismounted_player: ObserverPlayer = null
	if driver_peer_id == peer_id:
		driver_peer_id = 0
		dismounted_player = _driver_player
		_driver_player = null
		_throttle = 0.0
		_steer = 0.0
	elif passenger_peer_id == peer_id:
		passenger_peer_id = 0
		dismounted_player = _passenger_player
		_passenger_player = null

	if dismounted_player != null and is_instance_valid(dismounted_player):
		dismounted_player.set_movement_enabled(true)
		var exit_pos: Vector3 = global_position + (global_transform.basis * Vector3(-2.0, 0.5, 0.0))
		dismounted_player.global_position = exit_pos
		dismounted_player.replicated_position = exit_pos
		player_dismounted.emit(peer_id)
		return true

	return false


func _physics_process(delta: float) -> void:
	if driver_peer_id > 0:
		fuel = VehicleKinematics.update_fuel(fuel, _throttle, fuel_burn_rate, delta)

	_simulate_wheel(_wheel_fl, true, delta)
	_simulate_wheel(_wheel_fr, true, delta)
	_simulate_wheel(_wheel_rl, false, delta)
	_simulate_wheel(_wheel_rr, false, delta)

	_sync_seated_positions()
	_prev_linear_vel = linear_velocity


func _simulate_wheel(wheel: RayCast3D, is_front: bool, delta: float) -> void:
	if wheel == null or not wheel.is_colliding():
		return

	var contact_pt: Vector3 = wheel.get_collision_point()
	var ray_origin: Vector3 = wheel.global_position
	var hit_dist: float = ray_origin.distance_to(contact_pt)

	var prev_dist: float = _prev_suspension_lengths.get(wheel, hit_dist)
	var comp_speed: float = (prev_dist - hit_dist) / maxf(delta, 0.001)
	_prev_suspension_lengths[wheel] = hit_dist

	var susp_force_mag: float = VehicleKinematics.calculate_suspension_force(
		SUSPENSION_REST_LENGTH_M, hit_dist, comp_speed, SPRING_STIFFNESS, SPRING_DAMPING
	)
	var susp_force: Vector3 = wheel.global_transform.basis.y * susp_force_mag
	apply_force(susp_force, contact_pt - global_position)

	# Steer rotation for front wheels
	var steer_angle: float = -_steer * 0.52 if is_front else 0.0
	var wheel_basis: Basis = global_transform.basis.rotated(global_transform.basis.y, steer_angle)

	var wheel_forward: Vector3 = -wheel_basis.z
	var wheel_right: Vector3 = wheel_basis.x
	var wheel_vel: Vector3 = linear_velocity

	# Drive force
	if not _braking:
		var drive_f: Vector3 = VehicleKinematics.calculate_drive_force(
			wheel_forward, _throttle, engine_power * 0.5, fuel
		)
		apply_force(drive_f, contact_pt - global_position)
	else:
		apply_central_force(-linear_velocity * 40.0)

	# Lateral tire grip
	var lat_force: Vector3 = VehicleKinematics.calculate_lateral_friction_force(
		wheel_right, wheel_vel, TIRE_GRIP * mass
	)
	apply_force(lat_force, contact_pt - global_position)


func _sync_seated_positions() -> void:
	if _driver_player != null and is_instance_valid(_driver_player):
		var seat_pos: Vector3 = (
			_driver_seat.global_position if is_instance_valid(_driver_seat) else global_position
		)
		_driver_player.global_position = seat_pos
		_driver_player.replicated_position = seat_pos
		_driver_player.velocity = linear_velocity

	if _passenger_player != null and is_instance_valid(_passenger_player):
		var seat_pos: Vector3 = (
			_passenger_seat.global_position
			if is_instance_valid(_passenger_seat)
			else global_position
		)
		_passenger_player.global_position = seat_pos
		_passenger_player.replicated_position = seat_pos
		_passenger_player.velocity = linear_velocity


func _on_body_entered(body: Node) -> void:
	if body == self:
		return
	var speed: float = _prev_linear_vel.length()
	if speed > 5.0:
		var ram_damage: float = ImpactDamageModel.calculate_impact_damage(mass, speed, 0.08, 30.0)
		if ram_damage > 0.0:
			vehicle_rammed.emit(body, ram_damage)
			if body.has_method("apply_damage"):
				body.call("apply_damage", ram_damage, driver_peer_id)
