class_name ConstructionAssembly
extends RefCounted

const MAX_PARTS_PER_ASSEMBLY: int = 50

var assembly_id: String = "assembly_default"
var _parts: Dictionary = {}


func get_part_count() -> int:
	return _parts.size()


func get_part(part_id: String) -> ConstructionPart:
	return _parts.get(part_id) as ConstructionPart


func add_part(part: ConstructionPart, parent_id: String = "", socket_idx: int = 0) -> bool:
	if part == null or part.part_id.is_empty():
		return false
	if _parts.size() >= MAX_PARTS_PER_ASSEMBLY:
		return false
	if _parts.has(part.part_id):
		return false

	if not parent_id.is_empty():
		var parent: ConstructionPart = get_part(parent_id)
		if parent == null:
			return false
		part.attach_to_parent(parent, socket_idx)

	_parts[part.part_id] = part
	return true


func remove_part(part_id: String) -> Array[ConstructionPart]:
	var removed: Array[ConstructionPart] = []
	if not _parts.has(part_id):
		return removed

	var target: ConstructionPart = _parts[part_id]
	_collect_subtree(target, removed)

	for p: ConstructionPart in removed:
		_parts.erase(p.part_id)
		p.detach_from_parent()

	return removed


func _collect_subtree(root: ConstructionPart, out_list: Array[ConstructionPart]) -> void:
	if root == null or not is_instance_valid(root):
		return
	out_list.append(root)
	for child: ConstructionPart in root.child_parts:
		_collect_subtree(child, out_list)


func evaluate_structural_integrity() -> Array[String]:
	var broken_ids: Array[String] = []
	for p_id: String in _parts:
		var part: ConstructionPart = _parts[p_id]
		if is_instance_valid(part) and part.evaluate_joint_stress():
			broken_ids.append(p_id)
	return broken_ids


func save_blueprint() -> Dictionary:
	var part_records: Array[Dictionary] = []
	for p_id: String in _parts:
		var part: ConstructionPart = _parts[p_id]
		if is_instance_valid(part):
			part_records.append(part.to_dictionary())
	return {
		"assembly_id": assembly_id,
		"part_count": part_records.size(),
		"parts": part_records,
	}
