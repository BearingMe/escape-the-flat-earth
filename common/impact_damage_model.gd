class_name ImpactDamageModel
extends RefCounted

const MIN_DAMAGE_MOMENTUM_THRESHOLD: float = 24.0  # kg * m/s
const MAX_DAMAGE_CAP: float = 120.0


static func calculate_momentum(mass_kg: float, speed_m_s: float) -> float:
	if not is_finite(mass_kg) or not is_finite(speed_m_s):
		return 0.0
	return maxf(mass_kg, 0.0) * maxf(speed_m_s, 0.0)


static func calculate_impact_damage(
	mass_kg: float,
	impact_speed_m_s: float,
	damage_multiplier: float = 0.06,
	momentum_threshold: float = MIN_DAMAGE_MOMENTUM_THRESHOLD
) -> float:
	var momentum: float = calculate_momentum(mass_kg, impact_speed_m_s)
	if momentum <= momentum_threshold:
		return 0.0
	var raw_damage: float = (momentum - momentum_threshold) * maxf(damage_multiplier, 0.0)
	return clampf(raw_damage, 0.0, MAX_DAMAGE_CAP)


static func calculate_throw_velocity(
	aim_direction: Vector3, thrower_velocity: Vector3, throw_impulse: float, mass_kg: float
) -> Vector3:
	if not aim_direction.is_finite() or not thrower_velocity.is_finite():
		return Vector3.ZERO
	var dir: Vector3 = (
		aim_direction.normalized() if aim_direction.length_squared() > 0.0 else Vector3.FORWARD
	)
	var effective_mass: float = maxf(mass_kg, 1.0)
	# Heavier objects have lower launch speed: v = impulse / mass
	var launch_speed: float = throw_impulse / (1.0 + effective_mass * 0.05)
	return dir * launch_speed + thrower_velocity * 0.5
