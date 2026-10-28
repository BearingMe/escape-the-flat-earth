class_name PlayerTraversalState
extends RefCounted

enum State {
	NORMAL,
	CLIMBING,
	RAGDOLL,
	CARRIED,
}

const CLIMB_SPEED_M_S: float = 3.5
const CLIMB_STAMINA_MAX_SEC: float = 6.0
const RAGDOLL_RECOVERY_TIME_SEC: float = 1.5
const KNOCKDOWN_DAMAGE_THRESHOLD: float = 20.0
const HARD_FALL_SPEED_THRESHOLD: float = 18.0
const PLAYER_PAYLOAD_MASS_KG: float = 75.0


static func state_name(state: int) -> String:
	match state:
		State.CLIMBING:
			return "Climbing"
		State.RAGDOLL:
			return "Ragdoll"
		State.CARRIED:
			return "Carried"
		_:
			return "Normal"


static func can_climb(wall_normal: Vector3) -> bool:
	if not wall_normal.is_finite():
		return false
	# Climbable if wall is steep (normal Y between -0.4 and 0.4)
	return absf(wall_normal.y) < 0.45 and wall_normal.length_squared() > 0.5


static func should_knockdown_from_damage(damage: float) -> bool:
	return damage >= KNOCKDOWN_DAMAGE_THRESHOLD


static func should_stumble_from_fall(fall_speed: float) -> bool:
	return fall_speed >= HARD_FALL_SPEED_THRESHOLD
