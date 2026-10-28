class_name StructuralLoadModel
extends RefCounted

const STANDARD_GRAVITY_ACCEL: float = 9.80665


static func calculate_joint_load_n(
	supported_mass_kg: float,
	external_force_n: float = 0.0,
	effective_gravity: float = STANDARD_GRAVITY_ACCEL
) -> float:
	if not is_finite(supported_mass_kg) or not is_finite(external_force_n):
		return 0.0
	var static_load: float = maxf(supported_mass_kg, 0.0) * maxf(effective_gravity, 0.0)
	return static_load + maxf(external_force_n, 0.0)


static func is_joint_overstressed(load_n: float, joint_limit_n: float) -> bool:
	if not is_finite(load_n) or not is_finite(joint_limit_n):
		return true
	return load_n > joint_limit_n
