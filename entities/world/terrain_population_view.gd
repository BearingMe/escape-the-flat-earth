class_name TerrainPopulationView
extends Node3D

const NEAR_TREE_END_M: float = 185.0
const FAR_TREE_BEGIN_M: float = 145.0
const PROP_VISIBILITY_END_M: float = 450.0
const VISIBILITY_FADE_MARGIN_M: float = 24.0

static var _mesh_cache: Dictionary = {}
static var _material_cache: Dictionary = {}


func configure(
	population: TerrainChunkPopulation, chunk_coordinate: Vector2i, chunk_size_m: float
) -> Error:
	if population == null or not is_finite(chunk_size_m) or chunk_size_m <= 0.0:
		return ERR_INVALID_PARAMETER
	var batches: Dictionary = {}
	var chunk_origin_x: float = float(chunk_coordinate.x) * chunk_size_m
	var chunk_origin_z: float = float(chunk_coordinate.y) * chunk_size_m
	for placement_index: int in range(population.size()):
		var root_position: Vector3 = population.positions[placement_index]
		root_position.x -= chunk_origin_x
		root_position.z -= chunk_origin_z
		var normal: Vector3 = population.surface_normals[placement_index]
		var yaw: float = population.yaws[placement_index]
		var prop_scale: float = population.scales[placement_index]
		match population.prop_kinds[placement_index]:
			TerrainPopulationGenerator.PropKind.TREE:
				_append_batch(
					batches,
					"tree_trunk",
					_make_transform(root_position, normal, yaw, prop_scale, 1.1, Vector3.ONE)
				)
				_append_batch(
					batches,
					"tree_canopy",
					_make_transform(
						root_position, normal, yaw, prop_scale, 2.55, Vector3(1.2, 1.35, 1.2)
					)
				)
				_append_batch(
					batches,
					"tree_far",
					_make_transform(
						root_position, normal, yaw, prop_scale, 1.5, Vector3(1.2, 1.5, 1.2)
					)
				)
			TerrainPopulationGenerator.PropKind.SHRUB:
				_append_batch(
					batches,
					"shrub",
					_make_transform(
						root_position, normal, yaw, prop_scale, 0.52, Vector3(0.8, 0.62, 0.8)
					)
				)
			TerrainPopulationGenerator.PropKind.ROCK:
				_append_batch(
					batches,
					"rock",
					_make_transform(
						root_position, normal, yaw, prop_scale, 0.55, Vector3(1.0, 0.72, 0.92)
					)
				)
			TerrainPopulationGenerator.PropKind.DEBRIS:
				_append_batch(
					batches,
					"debris",
					_make_transform(
						root_position, normal, yaw, prop_scale, 0.12, Vector3(1.2, 0.28, 0.72)
					)
				)
			TerrainPopulationGenerator.PropKind.ICE_FORMATION:
				_append_batch(
					batches,
					"ice",
					_make_transform(
						root_position, normal, yaw, prop_scale, 1.2, Vector3(0.9, 1.4, 0.9)
					)
				)
	for batch_key: Variant in batches.keys():
		var transforms: Array = batches[batch_key]
		if not transforms.is_empty():
			_add_multimesh(batch_key, transforms)
	return OK


func _append_batch(batches: Dictionary, batch_key: String, transform: Transform3D) -> void:
	if not batches.has(batch_key):
		batches[batch_key] = []
	(batches[batch_key] as Array).append(transform)


func _make_transform(
	root_position: Vector3,
	normal: Vector3,
	yaw: float,
	prop_scale: float,
	vertical_offset: float,
	shape_scale: Vector3
) -> Transform3D:
	var surface_up: Vector3 = normal.normalized()
	var align_to_surface: Quaternion = Quaternion(Vector3.UP, surface_up)
	var yaw_rotation: Quaternion = Quaternion(surface_up, yaw)
	var orientation: Basis = Basis(yaw_rotation * align_to_surface)
	var translation: Vector3 = (
		root_position + orientation * Vector3(0.0, vertical_offset * prop_scale, 0.0)
	)
	var scaled_basis: Basis = orientation.scaled(shape_scale * prop_scale)
	return Transform3D(scaled_basis, translation)


func _add_multimesh(batch_key: String, transforms: Array) -> void:
	var mesh_instance: MultiMeshInstance3D = MultiMeshInstance3D.new()
	mesh_instance.name = "Population_%s" % batch_key
	var multimesh: MultiMesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = _get_mesh(batch_key)
	multimesh.instance_count = transforms.size()
	multimesh.visible_instance_count = transforms.size()
	for instance_index: int in range(transforms.size()):
		multimesh.set_instance_transform(instance_index, transforms[instance_index])
	mesh_instance.multimesh = multimesh
	mesh_instance.material_override = _get_material(batch_key)
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if batch_key == "tree_far":
		mesh_instance.visibility_range_begin = FAR_TREE_BEGIN_M
		mesh_instance.visibility_range_begin_margin = VISIBILITY_FADE_MARGIN_M
		mesh_instance.visibility_range_end = PROP_VISIBILITY_END_M
		mesh_instance.visibility_range_end_margin = VISIBILITY_FADE_MARGIN_M
		mesh_instance.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
	else:
		mesh_instance.visibility_range_end = (
			NEAR_TREE_END_M
			if batch_key == "tree_trunk" or batch_key == "tree_canopy"
			else PROP_VISIBILITY_END_M
		)
		mesh_instance.visibility_range_end_margin = VISIBILITY_FADE_MARGIN_M
		mesh_instance.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
	add_child(mesh_instance)


static func _get_mesh(batch_key: String) -> Mesh:
	if _mesh_cache.has(batch_key):
		return _mesh_cache[batch_key] as Mesh
	var mesh: Mesh
	match batch_key:
		"tree_trunk":
			var trunk: CylinderMesh = CylinderMesh.new()
			trunk.top_radius = 0.24
			trunk.bottom_radius = 0.34
			trunk.height = 2.2
			trunk.radial_segments = 6
			mesh = trunk
		"tree_canopy":
			var canopy: SphereMesh = SphereMesh.new()
			canopy.radial_segments = 8
			canopy.rings = 4
			mesh = canopy
		"tree_far":
			var far_tree: CylinderMesh = CylinderMesh.new()
			far_tree.top_radius = 0.02
			far_tree.bottom_radius = 1.0
			far_tree.height = 3.0
			far_tree.radial_segments = 5
			mesh = far_tree
		"shrub":
			var shrub: SphereMesh = SphereMesh.new()
			shrub.radial_segments = 7
			shrub.rings = 3
			mesh = shrub
		"rock":
			var rock: SphereMesh = SphereMesh.new()
			rock.radial_segments = 6
			rock.rings = 3
			mesh = rock
		"debris":
			mesh = BoxMesh.new()
		"ice":
			var ice: CylinderMesh = CylinderMesh.new()
			ice.top_radius = 0.02
			ice.bottom_radius = 0.72
			ice.height = 2.0
			ice.radial_segments = 5
			mesh = ice
	if mesh == null:
		return null
	_mesh_cache[batch_key] = mesh
	return mesh


static func _get_material(batch_key: String) -> StandardMaterial3D:
	if _material_cache.has(batch_key):
		return _material_cache[batch_key] as StandardMaterial3D
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.roughness = 0.92
	match batch_key:
		"tree_trunk":
			material.albedo_color = Color("#60462f")
		"tree_canopy", "tree_far":
			material.albedo_color = Color("#32663a")
		"shrub":
			material.albedo_color = Color("#587d40")
		"rock":
			material.albedo_color = Color("#77736b")
		"debris":
			material.albedo_color = Color("#655d50")
		"ice":
			material.albedo_color = Color("#a9dceb")
	_material_cache[batch_key] = material
	return material
