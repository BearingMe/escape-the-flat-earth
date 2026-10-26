extends GutTest


func test_disk_scene_builds_configured_mesh_and_full_thickness_collision() -> void:
	var packed_scene: PackedScene = load("res://entities/world/disk.tscn") as PackedScene
	var disk: StaticBody3D = packed_scene.instantiate() as StaticBody3D
	autofree(disk)
	add_child(disk)
	await wait_physics_frames(1)

	var collision: CollisionShape3D = disk.get_node("CollisionShape3D") as CollisionShape3D
	var shape: CylinderShape3D = collision.shape as CylinderShape3D
	var top: MeshInstance3D = disk.get_node("TopSurface") as MeshInstance3D
	var mesh: CylinderMesh = top.mesh as CylinderMesh
	assert_not_null(shape)
	assert_almost_eq(shape.radius, World.config.disk_radius_m, 0.01)
	assert_almost_eq(shape.height, World.config.disk_thickness_m, 0.01)
	assert_almost_eq(mesh.top_radius, World.config.disk_radius_m, 0.01)
	assert_almost_eq(top.position.y + mesh.height * 0.5, World.config.disk_thickness_m * 0.5, 0.01)
