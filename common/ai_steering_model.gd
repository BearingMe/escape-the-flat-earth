class_name AISteeringModel
extends RefCounted


static func calculate_pursuit_velocity(
	current_pos: Vector3, target_pos: Vector3, max_speed: float
) -> Vector3:
	if not current_pos.is_finite() or not target_pos.is_finite() or max_speed <= 0.0:
		return Vector3.ZERO
	var delta: Vector3 = target_pos - current_pos
	# Horizontal pursuit
	var delta_2d: Vector3 = Vector3(delta.x, 0.0, delta.z)
	if delta_2d.length_squared() < 0.01:
		return Vector3.ZERO
	return delta_2d.normalized() * max_speed


static func calculate_flee_velocity(
	current_pos: Vector3, threat_pos: Vector3, max_speed: float
) -> Vector3:
	return -calculate_pursuit_velocity(current_pos, threat_pos, max_speed)


static func calculate_magnetic_pull(
	entity_pos: Vector3, anomaly_pos: Vector3, max_dist: float = 18.0, strength: float = 350.0
) -> Vector3:
	if not entity_pos.is_finite() or not anomaly_pos.is_finite() or max_dist <= 0.0:
		return Vector3.ZERO
	var dist: float = entity_pos.distance_to(anomaly_pos)
	if dist > max_dist or dist < 0.5:
		return Vector3.ZERO
	var falloff: float = 1.0 - (dist / max_dist)
	var pull_dir: Vector3 = (anomaly_pos - entity_pos).normalized()
	return pull_dir * (strength * falloff)


static func is_target_in_range(pos_a: Vector3, pos_b: Vector3, range_m: float) -> bool:
	if not pos_a.is_finite() or not pos_b.is_finite():
		return false
	return pos_a.distance_squared_to(pos_b) <= (range_m * range_m)
