class_name VehicleKinematics
extends RefCounted


static func calculate_suspension_force(
	rest_length: float,
	current_distance: float,
	compression_speed: float,
	spring_stiffness: float = 4500.0,
	damping: float = 280.0
) -> float:
	if not is_finite(current_distance) or current_distance >= rest_length:
		return 0.0
	var compression: float = clampf(rest_length - current_distance, 0.0, rest_length)
	var spring_force: float = compression * spring_stiffness
	var damp_force: float = compression_speed * damping
	return maxf(spring_force - damp_force, 0.0)


static func calculate_lateral_friction_force(
	wheel_right_dir: Vector3, wheel_velocity: Vector3, tire_grip_factor: float = 12.0
) -> Vector3:
	if not wheel_right_dir.is_finite() or not wheel_velocity.is_finite():
		return Vector3.ZERO
	var lateral_speed: float = wheel_velocity.dot(wheel_right_dir)
	return -wheel_right_dir * (lateral_speed * tire_grip_factor)


static func calculate_drive_force(
	wheel_forward_dir: Vector3, throttle: float, engine_power_n: float, fuel_level: float
) -> Vector3:
	if fuel_level <= 0.0 or not wheel_forward_dir.is_finite():
		return Vector3.ZERO
	var clamped_throttle: float = clampf(throttle, -1.0, 1.0)
	return wheel_forward_dir * (clamped_throttle * engine_power_n)


static func update_fuel(
	current_fuel: float, throttle: float, burn_rate_per_sec: float, delta: float
) -> float:
	if current_fuel <= 0.0 or delta <= 0.0:
		return 0.0
	var consumption: float = absf(throttle) * burn_rate_per_sec * delta
	return maxf(current_fuel - consumption, 0.0)
