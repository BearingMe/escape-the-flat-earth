extends GutTest


func test_suspension_spring_force() -> void:
	# Rest length 0.75m, distance 0.50m -> compression = 0.25m
	# Zero compression speed -> F = 0.25 * 4500 = 1125 N
	var force: float = VehicleKinematics.calculate_suspension_force(0.75, 0.50, 0.0, 4500.0, 280.0)
	assert_almost_eq(force, 1125.0, 0.01)

	# Fully uncompressed (distance >= rest length) -> 0 force
	var no_force: float = VehicleKinematics.calculate_suspension_force(0.75, 0.80, 0.0)
	assert_almost_eq(no_force, 0.0, 0.01)


func test_lateral_friction_force() -> void:
	var right_dir: Vector3 = Vector3(1.0, 0.0, 0.0)
	# Pure forward motion -> lateral velocity is 0
	var fwd_vel: Vector3 = Vector3(0.0, 0.0, -10.0)
	var lat_f_zero: Vector3 = VehicleKinematics.calculate_lateral_friction_force(
		right_dir, fwd_vel, 10.0
	)
	assert_almost_eq(lat_f_zero.length(), 0.0, 0.01)

	# Sideways slide at +5.0 m/s along right_dir -> opposes with -X force
	var slide_vel: Vector3 = Vector3(5.0, 0.0, -5.0)
	var lat_f: Vector3 = VehicleKinematics.calculate_lateral_friction_force(
		right_dir, slide_vel, 10.0
	)
	assert_almost_eq(lat_f.x, -50.0, 0.01)


func test_drive_force_and_fuel_depletion() -> void:
	var fwd_dir: Vector3 = Vector3(0.0, 0.0, -1.0)
	# Full throttle, 1500 N, full fuel
	var drive_f: Vector3 = VehicleKinematics.calculate_drive_force(fwd_dir, 1.0, 1500.0, 100.0)
	assert_almost_eq(drive_f.z, -1500.0, 0.01)

	# Empty fuel -> 0 drive force
	var empty_drive_f: Vector3 = VehicleKinematics.calculate_drive_force(fwd_dir, 1.0, 1500.0, 0.0)
	assert_almost_eq(empty_drive_f.length(), 0.0, 0.01)

	# Fuel burn: 100 fuel, full throttle, rate 0.5/sec, for 10 seconds -> burns 5 fuel
	var next_fuel: float = VehicleKinematics.update_fuel(100.0, 1.0, 0.5, 10.0)
	assert_almost_eq(next_fuel, 95.0, 0.01)
