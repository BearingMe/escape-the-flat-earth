extends GutTest

const VEHICLE_SCENE: PackedScene = preload("res://entities/props/vehicle_entity.tscn")
const OBSERVER_SCENE: PackedScene = preload("res://entities/player/observer.tscn")

var _vehicle: VehicleEntity
var _driver: ObserverPlayer
var _passenger: ObserverPlayer


func before_each() -> void:
	_vehicle = VEHICLE_SCENE.instantiate() as VehicleEntity
	_vehicle.position = Vector3(0.0, 1.0, 0.0)
	add_child_autofree(_vehicle)

	_driver = OBSERVER_SCENE.instantiate() as ObserverPlayer
	_driver.configure(1, "player_1_1", "Driver")
	add_child_autofree(_driver)

	_passenger = OBSERVER_SCENE.instantiate() as ObserverPlayer
	_passenger.configure(2, "player_1_2", "Passenger")
	add_child_autofree(_passenger)


func test_mounting_and_multi_passenger_capacity() -> void:
	# Driver mounts
	var mount_drv: bool = _vehicle.mount_player(_driver, true)
	assert_true(mount_drv)
	assert_eq(_vehicle.driver_peer_id, 1)

	# Passenger mounts
	var mount_pass: bool = _vehicle.mount_player(_passenger, false)
	assert_true(mount_pass)
	assert_eq(_vehicle.passenger_peer_id, 2)

	# 3rd player attempts mount -> rejected
	var extra_player: ObserverPlayer = OBSERVER_SCENE.instantiate() as ObserverPlayer
	extra_player.configure(3, "player_1_3", "Extra")
	add_child_autofree(extra_player)

	var extra_mount: bool = _vehicle.mount_player(extra_player, true)
	assert_false(extra_mount)


func test_dismounting_restores_player_movement() -> void:
	_vehicle.mount_player(_driver, true)
	_vehicle.mount_player(_passenger, false)

	# Dismount passenger
	var dis_pass: bool = _vehicle.dismount_player(2)
	assert_true(dis_pass)
	assert_eq(_vehicle.passenger_peer_id, 0)

	# Dismount driver
	var dis_drv: bool = _vehicle.dismount_player(1)
	assert_true(dis_drv)
	assert_eq(_vehicle.driver_peer_id, 0)
