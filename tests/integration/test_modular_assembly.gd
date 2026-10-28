extends GutTest

const PART_SCENE: PackedScene = preload("res://entities/props/construction_part.tscn")
const BEAM_DEF: ConstructionPartDefinition = preload(
	"res://common/data/construction/wood_beam.tres"
)

var _assembly: ConstructionAssembly


func before_each() -> void:
	_assembly = ConstructionAssembly.new()
	_assembly.assembly_id = "test_ramp"


func test_add_parts_and_cumulative_mass() -> void:
	var root_part: ConstructionPart = PART_SCENE.instantiate() as ConstructionPart
	root_part.part_id = "root_1"
	root_part.is_anchored_to_ground = true
	add_child_autofree(root_part)

	var success_root: bool = _assembly.add_part(root_part)
	assert_true(success_root)
	assert_eq(_assembly.get_part_count(), 1)

	var child_part: ConstructionPart = PART_SCENE.instantiate() as ConstructionPart
	child_part.part_id = "child_1"
	add_child_autofree(child_part)

	var success_child: bool = _assembly.add_part(child_part, "root_1", 1)
	assert_true(success_child)
	assert_eq(_assembly.get_part_count(), 2)

	# Cumulative mass of root should be 20 (root) + 20 (child) = 40 kg
	assert_almost_eq(root_part.calculate_cumulative_mass(), 40.0, 0.01)
	assert_almost_eq(child_part.calculate_cumulative_mass(), 20.0, 0.01)


func test_joint_failure_under_excessive_load() -> void:
	var root: ConstructionPart = PART_SCENE.instantiate() as ConstructionPart
	root.part_id = "root_anchor"
	root.is_anchored_to_ground = true
	add_child_autofree(root)
	_assembly.add_part(root)

	var beam: ConstructionPart = PART_SCENE.instantiate() as ConstructionPart
	beam.part_id = "overstressed_beam"
	add_child_autofree(beam)
	_assembly.add_part(beam, "root_anchor", 1)

	# Normal static load (20kg * 9.8 = 196N < 750N limit) -> holds
	assert_false(beam.evaluate_joint_stress())
	assert_not_null(beam.parent_part)

	# Severe impact load (900N external force + 196N = 1096N > 750N limit) -> snaps!
	var broken: bool = beam.evaluate_joint_stress(900.0)
	assert_true(broken)
	assert_null(beam.parent_part)


func test_max_part_safeguard() -> void:
	for i: int in range(ConstructionAssembly.MAX_PARTS_PER_ASSEMBLY):
		var p: ConstructionPart = PART_SCENE.instantiate() as ConstructionPart
		p.part_id = "part_%d" % i
		add_child_autofree(p)
		var added: bool = _assembly.add_part(p)
		assert_true(added)

	assert_eq(_assembly.get_part_count(), ConstructionAssembly.MAX_PARTS_PER_ASSEMBLY)

	# 51st part should be rejected by safeguard
	var extra: ConstructionPart = PART_SCENE.instantiate() as ConstructionPart
	extra.part_id = "extra_part"
	add_child_autofree(extra)
	var extra_added: bool = _assembly.add_part(extra)
	assert_false(extra_added)


func test_blueprint_save_serialization() -> void:
	var root: ConstructionPart = PART_SCENE.instantiate() as ConstructionPart
	root.part_id = "bp_root"
	root.position = Vector3(10.0, 5.0, 0.0)
	add_child_autofree(root)
	_assembly.add_part(root)

	var bp: Dictionary = _assembly.save_blueprint()
	assert_eq(bp["assembly_id"], "test_ramp")
	assert_eq(bp["part_count"], 1)
	var parts: Array = bp["parts"]
	assert_eq(parts[0]["part_id"], "bp_root")
	assert_almost_eq(float(parts[0]["position_x"]), 10.0, 0.01)
