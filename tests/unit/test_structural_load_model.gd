extends GutTest


func test_static_joint_load_under_earth_gravity() -> void:
	# 50 kg mass under standard 9.80665 m/s^2 gravity: F = 50 * 9.80665 = 490.3325 N
	var load_n: float = StructuralLoadModel.calculate_joint_load_n(50.0)
	assert_almost_eq(load_n, 50.0 * 9.80665, 0.05)


func test_combined_load_with_external_impact() -> void:
	# 20 kg static load + 400 N impact force
	var total_load: float = StructuralLoadModel.calculate_joint_load_n(20.0, 400.0)
	var expected: float = (20.0 * 9.80665) + 400.0
	assert_almost_eq(total_load, expected, 0.05)


func test_overstressed_joint_evaluation() -> void:
	# Breaking limit is 750 N
	assert_false(StructuralLoadModel.is_joint_overstressed(600.0, 750.0))
	assert_true(StructuralLoadModel.is_joint_overstressed(850.0, 750.0))
