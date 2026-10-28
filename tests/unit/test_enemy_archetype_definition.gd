extends GutTest

const DRONE_RES: EnemyArchetypeDefinition = preload("res://common/data/enemies/geodetic_drone.tres")
const SENTINEL_RES: EnemyArchetypeDefinition = preload(
	"res://common/data/enemies/ice_sentinel.tres"
)
const SWARMER_RES: EnemyArchetypeDefinition = preload("res://common/data/enemies/void_swarmer.tres")
const ROVER_RES: EnemyArchetypeDefinition = preload("res://common/data/enemies/patrol_rover.tres")
const ANOMALY_RES: EnemyArchetypeDefinition = preload(
	"res://common/data/enemies/magnetic_anomaly.tres"
)


func test_all_five_archetypes_valid() -> void:
	var archetypes: Array[EnemyArchetypeDefinition] = [
		DRONE_RES, SENTINEL_RES, SWARMER_RES, ROVER_RES, ANOMALY_RES
	]
	assert_eq(archetypes.size(), 5)
	for a: EnemyArchetypeDefinition in archetypes:
		assert_not_null(a)
		assert_eq(a.validate(), OK, "Archetype %s must be valid" % a.display_name)


func test_distinct_mechanics_and_roles() -> void:
	# Drone is fast aerial scout
	assert_gt(DRONE_RES.movement_speed_m_s, 8.0)

	# Sentinel is high-health brute
	assert_gt(SENTINEL_RES.max_health, 200.0)
	assert_gt(SENTINEL_RES.attack_range_m, 10.0)

	# Swarmer has rapid attack cooldown
	assert_lt(SWARMER_RES.attack_cooldown_sec, 1.2)


func test_invalid_archetype_rejected() -> void:
	var def: EnemyArchetypeDefinition = EnemyArchetypeDefinition.new()
	def.display_name = ""
	assert_eq(def.validate(), ERR_INVALID_DATA)
