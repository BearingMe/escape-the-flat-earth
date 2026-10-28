extends GutTest

const OBSERVER_SCENE: PackedScene = preload("res://entities/player/observer.tscn")
const BEANS_RES: ConsumableDefinition = preload("res://common/data/consumables/canned_beans.tres")
const MEDKIT_RES: ConsumableDefinition = preload("res://common/data/consumables/medical_kit.tres")

var _medic: ObserverPlayer
var _patient: ObserverPlayer


func before_each() -> void:
	World.set_seed(17320508)
	_medic = OBSERVER_SCENE.instantiate() as ObserverPlayer
	_medic.configure(1, "player_1_1", "MedicPlayer")
	_medic.position = Vector3(0.0, 0.0, 0.0)
	add_child_autofree(_medic)

	_patient = OBSERVER_SCENE.instantiate() as ObserverPlayer
	_patient.configure(2, "player_1_2", "PatientPlayer")
	_patient.position = Vector3(2.0, 0.0, 0.0)
	add_child_autofree(_patient)


func test_consumption_restores_health_and_hunger() -> void:
	_medic.survival.hunger = 30.0
	_medic.survival.health = 40.0

	var consumed: bool = _medic.consume_item_host(BEANS_RES)
	assert_true(consumed)
	assert_gt(_medic.survival.hunger, 30.0)
	assert_gt(_medic.survival.health, 40.0)


func test_lethal_damage_incapacitation_and_revival() -> void:
	# Deal 120 damage to patient -> down-but-not-out incapacitation
	_patient.apply_damage(120.0, 1)

	assert_true(_patient.survival.is_incapacitated)
	assert_almost_eq(_patient.health, 0.0, 0.01)
	assert_eq(_patient.movement_state, PlayerTraversalState.State.RAGDOLL)

	# Medic revives patient
	var revived: bool = _medic.revive_target_host(_patient)
	assert_true(revived)
	assert_false(_patient.survival.is_incapacitated)
	assert_gt(_patient.health, 20.0)
	assert_eq(_patient.movement_state, PlayerTraversalState.State.NORMAL)
