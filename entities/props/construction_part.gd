class_name ConstructionPart
extends RigidBody3D

signal joint_snapped(part_id: String)

@export var part_id: String = ""
@export var definition: ConstructionPartDefinition
@export var is_anchored_to_ground: bool = false

var parent_part: ConstructionPart = null
var child_parts: Array[ConstructionPart] = []
var socket_index_on_parent: int = 0
var _joint: Generic6DOFJoint3D = null


func _ready() -> void:
	if definition != null:
		mass = definition.mass_kg
	if is_anchored_to_ground:
		freeze = true


func attach_to_parent(parent: ConstructionPart, socket_idx: int) -> bool:
	if parent == null or parent == self:
		return false
	if parent_part != null:
		detach_from_parent()

	parent_part = parent
	socket_index_on_parent = socket_idx
	parent.child_parts.append(self)

	# Position at parent's socket anchor
	var socket_offset: Vector3 = Vector3.ZERO
	if (
		parent.definition != null
		and socket_idx >= 0
		and socket_idx < parent.definition.sockets.size()
	):
		socket_offset = parent.definition.sockets[socket_idx]

	global_position = parent.global_position + parent.global_transform.basis * socket_offset

	# Create physics joint
	_joint = Generic6DOFJoint3D.new()
	_joint.node_a = parent.get_path()
	_joint.node_b = get_path()
	add_child(_joint)

	if is_anchored_to_ground:
		freeze = true

	return true


func detach_from_parent() -> void:
	if _joint != null and is_instance_valid(_joint):
		_joint.queue_free()
		_joint = null
	if parent_part != null:
		parent_part.child_parts.erase(self)
		parent_part = null
	freeze = false
	sleeping = false


func calculate_cumulative_mass() -> float:
	var total: float = mass
	for child: ConstructionPart in child_parts:
		if is_instance_valid(child):
			total += child.calculate_cumulative_mass()
	return total


func evaluate_joint_stress(external_force_n: float = 0.0) -> bool:
	if parent_part == null or is_anchored_to_ground:
		return false

	var supported_mass: float = calculate_cumulative_mass()
	var load_n: float = StructuralLoadModel.calculate_joint_load_n(supported_mass, external_force_n)
	var limit_n: float = definition.joint_breaking_force_n if definition != null else 800.0

	if StructuralLoadModel.is_joint_overstressed(load_n, limit_n):
		joint_snapped.emit(part_id)
		detach_from_parent()
		return true

	return false


func to_dictionary() -> Dictionary:
	return {
		"part_id": part_id,
		"type_id": definition.part_type_id if definition != null else "wood_beam",
		"position_x": position.x,
		"position_y": position.y,
		"position_z": position.z,
		"rotation_y": rotation.y,
		"is_anchored": is_anchored_to_ground,
		"parent_id": parent_part.part_id if parent_part != null else "",
		"socket_index": socket_index_on_parent,
	}
