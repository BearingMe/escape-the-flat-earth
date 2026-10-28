class_name PhysicalProp
extends RigidBody3D

signal prop_impact(target: Node, damage: float, velocity: Vector3)

const SPRING_STIFFNESS: float = 14.0
const SPRING_DAMPING: float = 6.0
const MIN_HOLD_DISTANCE_M: float = 1.0
const MAX_HOLD_DISTANCE_M: float = 5.0

@export var definition: PhysicalPropDefinition

var _holders: Dictionary = {}
var _last_holder_peer_id: int = 0
var _prev_linear_velocity: Vector3 = Vector3.ZERO


func _ready() -> void:
	contact_monitor = true
	max_contacts_reported = 4
	if definition != null:
		mass = definition.mass_kg
		physics_material_override = PhysicsMaterial.new()
		physics_material_override.friction = definition.friction
		physics_material_override.bounce = definition.bounce
	body_entered.connect(_on_body_entered)


func grab(peer_id: int, anchor_node: Node3D, distance: float = 2.0) -> bool:
	if peer_id <= 0 or anchor_node == null:
		return false
	if _holders.size() >= 2 and not _holders.has(peer_id):
		# Max 2 players can hold simultaneously (tug of war / coop lift)
		return false

	var clamped_dist: float = clampf(
		distance,
		MIN_HOLD_DISTANCE_M,
		definition.max_grab_distance_m if definition != null else MAX_HOLD_DISTANCE_M
	)
	_holders[peer_id] = {
		"anchor": anchor_node,
		"distance": clamped_dist,
	}
	_last_holder_peer_id = peer_id
	sleeping = false
	return true


func release(peer_id: int) -> void:
	_holders.erase(peer_id)


func adjust_distance(peer_id: int, delta_dist: float) -> void:
	if not _holders.has(peer_id):
		return
	var holder_info: Dictionary = _holders[peer_id]
	var current_dist: float = float(holder_info.get("distance", 2.0))
	var max_dist: float = (
		definition.max_grab_distance_m if definition != null else MAX_HOLD_DISTANCE_M
	)
	holder_info["distance"] = clampf(current_dist + delta_dist, MIN_HOLD_DISTANCE_M, max_dist)


func throw_prop(peer_id: int, aim_dir: Vector3, thrower_vel: Vector3) -> void:
	if _holders.has(peer_id):
		release(peer_id)
	_last_holder_peer_id = peer_id

	var impulse_val: float = definition.base_throw_impulse if definition != null else 16.0
	var throw_vel: Vector3 = ImpactDamageModel.calculate_throw_velocity(
		aim_dir, thrower_vel, impulse_val, mass
	)
	linear_velocity = throw_vel
	angular_velocity = Vector3(randf_range(-4, 4), randf_range(-4, 4), randf_range(-4, 4))
	sleeping = false


func is_held_by(peer_id: int) -> bool:
	return _holders.has(peer_id)


func is_held() -> bool:
	return not _holders.is_empty()


func get_holder_count() -> int:
	return _holders.size()


func get_last_thrower_peer_id() -> int:
	return _last_holder_peer_id


func _physics_process(_delta: float) -> void:
	if _holders.is_empty():
		_prev_linear_velocity = linear_velocity
		return

	sleeping = false
	var active_holders: int = _holders.size()
	for p_id: int in _holders:
		var info: Dictionary = _holders[p_id]
		var anchor: Node3D = info.get("anchor") as Node3D
		if anchor == null or not is_instance_valid(anchor):
			continue
		var hold_dist: float = float(info.get("distance", 2.0))
		var target_pos: Vector3 = (
			anchor.global_position + (-anchor.global_transform.basis.z * hold_dist)
		)

		var delta_pos: Vector3 = target_pos - global_position
		var desired_vel: Vector3 = delta_pos * SPRING_STIFFNESS
		var vel_error: Vector3 = desired_vel - linear_velocity
		var force: Vector3 = vel_error * mass * SPRING_DAMPING

		apply_central_force(force / float(active_holders))

	_prev_linear_velocity = linear_velocity


func _on_body_entered(body: Node) -> void:
	if body == self:
		return
	var impact_speed: float = _prev_linear_velocity.length()
	var damage_mult: float = definition.damage_multiplier if definition != null else 0.06
	var damage: float = ImpactDamageModel.calculate_impact_damage(mass, impact_speed, damage_mult)

	if damage > 0.0:
		prop_impact.emit(body, damage, _prev_linear_velocity)
		if body.has_method("apply_damage"):
			body.call("apply_damage", damage, _last_holder_peer_id)
