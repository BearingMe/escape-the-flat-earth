class_name TerrainChunkPopulation
extends RefCounted

var cell_coordinates: Array[Vector2i] = []
var stable_ids: Array[String] = []
var positions: PackedVector3Array = PackedVector3Array()
var surface_normals: PackedVector3Array = PackedVector3Array()
var prop_kinds: PackedInt32Array = PackedInt32Array()
var biome_ids: PackedInt32Array = PackedInt32Array()
var scales: PackedFloat32Array = PackedFloat32Array()
var yaws: PackedFloat32Array = PackedFloat32Array()
var fingerprint: int = 0


func size() -> int:
	return prop_kinds.size()
