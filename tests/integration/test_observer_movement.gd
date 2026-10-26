extends GutTest

var _active_observer: ObserverPlayer


func after_each() -> void:
	_active_observer = null


func _physics_process(delta: float) -> void:
	if is_instance_valid(_active_observer):
		_active_observer._simulate_authoritative_movement(delta)


func test_observer_falls_under_earth_gravity_lands_and_jumps() -> void:
	_add_disk()
	var surface_y: float = World.config.disk_thickness_m * 0.5
	_active_observer = _add_observer(Vector3(0.0, surface_y + 8.0, -100.0))

	await wait_physics_frames(150)
	assert_true(_active_observer.is_on_floor())
	assert_almost_eq(_active_observer.position.y, surface_y, 0.08)
	assert_eq(ProjectSettings.get_setting("physics/3d/default_gravity"), 9.8)

	var grounded_y: float = _active_observer.position.y
	_active_observer._jump_requested = true
	await wait_physics_frames(1)
	assert_gt(_active_observer.velocity.y, 0.0)
	await wait_physics_frames(12)
	assert_gt(_active_observer.position.y, grounded_y + 0.5)

	_active_observer = null


func test_observer_collides_with_a_wall_while_grounded() -> void:
	_add_disk()
	var surface_y: float = World.config.disk_thickness_m * 0.5
	var wall: StaticBody3D = StaticBody3D.new()
	autofree(wall)
	wall.position = Vector3(0.0, surface_y + 1.5, -100.0)
	var wall_shape: CollisionShape3D = CollisionShape3D.new()
	var wall_box: BoxShape3D = BoxShape3D.new()
	wall_box.size = Vector3(1.0, 3.0, 4.0)
	wall_shape.shape = wall_box
	wall.add_child(wall_shape)
	add_child(wall)
	_active_observer = _add_observer(Vector3(-3.0, surface_y + 0.05, -100.0))
	_active_observer._local_move_direction = Vector3.RIGHT
	_active_observer._wish_direction = Vector3.RIGHT

	await wait_physics_frames(90)
	assert_true(_active_observer.is_on_floor())
	assert_lt(_active_observer.position.x, -0.6)
	assert_gt(_active_observer.position.x, -1.4)
	_active_observer = null


func test_observer_can_walk_up_a_traversable_slope() -> void:
	_add_disk()
	var surface_y: float = World.config.disk_thickness_m * 0.5
	var slope: StaticBody3D = StaticBody3D.new()
	autofree(slope)
	slope.position = Vector3(-5.0, surface_y, -100.0)
	slope.rotation.z = deg_to_rad(20.0)
	var slope_shape: CollisionShape3D = CollisionShape3D.new()
	var slope_plane: WorldBoundaryShape3D = WorldBoundaryShape3D.new()
	slope_plane.plane = Plane(Vector3.UP, 0.0)
	slope_shape.shape = slope_plane
	slope.add_child(slope_shape)
	add_child(slope)
	_active_observer = _add_observer(Vector3(-7.0, surface_y + 0.05, -100.0))
	_active_observer._local_move_direction = Vector3.RIGHT
	_active_observer._wish_direction = Vector3.RIGHT

	await wait_physics_frames(100)
	assert_true(_active_observer.is_on_floor())
	assert_gt(_active_observer.position.x, -2.0)
	assert_gt(_active_observer.position.y, surface_y + 0.75)
	_active_observer = null


func test_observer_falls_downward_after_leaving_the_disk_edge() -> void:
	_add_disk()
	var surface_y: float = World.config.disk_thickness_m * 0.5
	_active_observer = _add_observer(
		Vector3(World.config.disk_radius_m - 2.0, surface_y + 0.05, 0.0)
	)
	_active_observer._local_move_direction = Vector3.RIGHT
	_active_observer._wish_direction = Vector3.RIGHT

	await wait_physics_frames(120)
	assert_gt(_active_observer.position.x, World.config.disk_radius_m + 0.5)
	assert_lt(_active_observer.position.y, surface_y - 0.5)
	assert_almost_eq(_active_observer.velocity.z, 0.0, 0.0001)
	_active_observer = null


func _add_disk() -> void:
	var disk_scene: PackedScene = load("res://entities/world/disk.tscn") as PackedScene
	var disk: Node = disk_scene.instantiate()
	autofree(disk)
	add_child(disk)


func _add_observer(start_position: Vector3) -> ObserverPlayer:
	var observer_scene: PackedScene = load("res://entities/player/observer.tscn") as PackedScene
	var observer: ObserverPlayer = observer_scene.instantiate() as ObserverPlayer
	observer.peer_id = 0
	autofree(observer)
	add_child(observer)
	observer.position = start_position
	_active_observer = observer
	return observer
