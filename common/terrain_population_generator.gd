class_name TerrainPopulationGenerator
extends RefCounted

enum PropKind { TREE, SHRUB, ROCK, DEBRIS, ICE_FORMATION }

const GRID_CELL_SIZE_M: float = 16.0
const MAX_CELL_JITTER_RATIO: float = 0.2
const SPAWN_CLEAR_RADIUS_M: float = 42.0
const DISK_EDGE_CLEARANCE_M: float = 10.0
const SURFACE_PROBE_DISTANCE_M: float = 2.0
const HASH_MODULUS: int = 2147483647
const HASH_MULTIPLIER: int = 48271
const MAX_SLOPE_DEGREES = [24.0, 38.0, 55.0, 44.0, 32.0]
const MIN_PROP_SCALE = [0.9, 0.65, 0.6, 0.5, 0.8]
const MAX_PROP_SCALE = [1.5, 1.15, 1.8, 1.4, 1.7]
const PROP_FOOTPRINT_RADIUS_M = [2.4, 1.1, 1.6, 0.9, 1.2]

var _config: WorldConfig
var _terrain_generator: DiskTerrainGenerator
var _world_seed: int


func configure(
	config: WorldConfig, terrain_generator: DiskTerrainGenerator, world_seed: int
) -> Error:
	if (
		config == null
		or config.validate() != OK
		or terrain_generator == null
		or TerrainBiomeCatalog.validate() != OK
	):
		return ERR_INVALID_PARAMETER
	_config = config.duplicate(true) as WorldConfig
	_terrain_generator = terrain_generator
	_world_seed = world_seed
	return OK


func build_chunk_population(chunk_coordinate: Vector2i) -> TerrainChunkPopulation:
	var population: TerrainChunkPopulation = TerrainChunkPopulation.new()
	if _config == null or _terrain_generator == null:
		return population
	var chunk_size: float = _config.terrain_chunk_size_m
	var origin_x: float = float(chunk_coordinate.x) * chunk_size
	var origin_z: float = float(chunk_coordinate.y) * chunk_size
	var first_cell_x: int = floori(origin_x / GRID_CELL_SIZE_M) - 1
	var first_cell_z: int = floori(origin_z / GRID_CELL_SIZE_M) - 1
	var last_cell_x: int = floori((origin_x + chunk_size) / GRID_CELL_SIZE_M) + 1
	var last_cell_z: int = floori((origin_z + chunk_size) / GRID_CELL_SIZE_M) + 1
	var fingerprint: int = 17
	for cell_x: int in range(first_cell_x, last_cell_x + 1):
		for cell_z: int in range(first_cell_z, last_cell_z + 1):
			var world_x: float = _cell_position(cell_x, cell_z, 0)
			var world_z: float = _cell_position(cell_x, cell_z, 1)
			if (
				Vector2i(floori(world_x / chunk_size), floori(world_z / chunk_size))
				!= chunk_coordinate
			):
				continue
			var biome_id: int = _terrain_generator.sample_biome_id(world_x, world_z)
			var biome: TerrainBiomeDefinition = TerrainBiomeCatalog.get_biome(biome_id)
			var prop_kind: int = _choose_prop_kind(biome, cell_x, cell_z)
			if prop_kind < 0:
				continue
			var scale: float = lerpf(
				MIN_PROP_SCALE[prop_kind],
				MAX_PROP_SCALE[prop_kind],
				_cell_random(cell_x, cell_z, 7)
			)
			var footprint_radius: float = PROP_FOOTPRINT_RADIUS_M[prop_kind] * scale
			var distance_from_center: float = Vector2(world_x, world_z).length()
			if (
				distance_from_center < SPAWN_CLEAR_RADIUS_M + footprint_radius
				or (
					distance_from_center + footprint_radius
					> _config.disk_radius_m - DISK_EDGE_CLEARANCE_M
				)
			):
				continue
			var height: float = _terrain_generator.sample_height(world_x, world_z)
			if height < 0.25:
				continue
			var normal: Vector3 = _sample_surface_normal(world_x, world_z)
			var max_slope_radians: float = deg_to_rad(MAX_SLOPE_DEGREES[prop_kind])
			if normal.y < cos(max_slope_radians):
				continue
			var yaw: float = _cell_random(cell_x, cell_z, 11) * TAU
			population.cell_coordinates.append(Vector2i(cell_x, cell_z))
			population.stable_ids.append("prop_%d_%d_%d" % [_world_seed, cell_x, cell_z])
			population.positions.append(
				Vector3(world_x, height + DiskTerrainGenerator.SURFACE_CLEARANCE_M, world_z)
			)
			population.surface_normals.append(normal)
			population.prop_kinds.append(prop_kind)
			population.biome_ids.append(biome_id)
			population.scales.append(scale)
			population.yaws.append(yaw)
			fingerprint = _mix_fingerprint(fingerprint, _cell_hash(cell_x, cell_z, 13))
			fingerprint = _mix_fingerprint(fingerprint, prop_kind * 7 + biome_id)
			fingerprint = _mix_fingerprint(fingerprint, roundi(scale * 1000.0))
	population.fingerprint = fingerprint
	return population


func _choose_prop_kind(biome: TerrainBiomeDefinition, cell_x: int, cell_z: int) -> int:
	if biome == null:
		return -1
	var roll: float = _cell_random(cell_x, cell_z, 5)
	var selected_kind: int = -1
	var threshold: float = biome.tree_density
	if roll < threshold:
		selected_kind = PropKind.TREE
	threshold += biome.shrub_density
	if selected_kind < 0 and roll < threshold:
		selected_kind = PropKind.SHRUB
	threshold += biome.rock_density
	if selected_kind < 0 and roll < threshold:
		selected_kind = PropKind.ROCK
	threshold += biome.debris_density
	if selected_kind < 0 and roll < threshold:
		selected_kind = PropKind.DEBRIS
	threshold += biome.ice_formation_density
	if selected_kind < 0 and roll < threshold:
		selected_kind = PropKind.ICE_FORMATION
	return selected_kind


func _cell_position(cell_x: int, cell_z: int, axis_salt: int) -> float:
	var jitter: float = _cell_random(cell_x, cell_z, axis_salt + 3) - 0.5
	var cell_coordinate: int = cell_x if axis_salt == 0 else cell_z
	return (float(cell_coordinate) + 0.5 + jitter * MAX_CELL_JITTER_RATIO) * GRID_CELL_SIZE_M


func _cell_random(cell_x: int, cell_z: int, salt: int) -> float:
	return float(_cell_hash(cell_x, cell_z, salt)) / float(HASH_MODULUS)


func _cell_hash(cell_x: int, cell_z: int, salt: int) -> int:
	var value: int = posmod(_world_seed, HASH_MODULUS)
	value = posmod(
		value * HASH_MULTIPLIER + cell_x * 69621 + cell_z * 30397 + salt * 8363, HASH_MODULUS
	)
	value = posmod(
		value * HASH_MULTIPLIER + cell_z * 91421 + cell_x * 36973 + salt * 19391, HASH_MODULUS
	)
	return value


func _sample_surface_normal(world_x: float, world_z: float) -> Vector3:
	var delta: float = SURFACE_PROBE_DISTANCE_M
	var height_left: float = _terrain_generator.sample_height(world_x - delta, world_z)
	var height_right: float = _terrain_generator.sample_height(world_x + delta, world_z)
	var height_back: float = _terrain_generator.sample_height(world_x, world_z - delta)
	var height_front: float = _terrain_generator.sample_height(world_x, world_z + delta)
	return Vector3(height_left - height_right, delta * 2.0, height_back - height_front).normalized()


func _mix_fingerprint(current: int, value: int) -> int:
	return posmod(current * 31 + value, HASH_MODULUS)
