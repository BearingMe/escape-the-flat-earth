extends GutTest

const BEAM_DEF: ConstructionPartDefinition = preload(
	"res://common/data/construction/wood_beam.tres"
)
const RAMP_DEF: ConstructionPartDefinition = preload(
	"res://common/data/construction/metal_ramp.tres"
)


func test_definitions_valid() -> void:
	assert_not_null(BEAM_DEF)
	assert_eq(BEAM_DEF.validate(), OK)
	assert_almost_eq(BEAM_DEF.mass_kg, 20.0, 0.01)
	assert_almost_eq(BEAM_DEF.joint_breaking_force_n, 750.0, 0.01)
	assert_eq(BEAM_DEF.sockets.size(), 3)

	assert_not_null(RAMP_DEF)
	assert_eq(RAMP_DEF.validate(), OK)
	assert_almost_eq(RAMP_DEF.mass_kg, 35.0, 0.01)
	assert_gt(RAMP_DEF.joint_breaking_force_n, BEAM_DEF.joint_breaking_force_n)


func test_invalid_definition_rejected() -> void:
	var def: ConstructionPartDefinition = ConstructionPartDefinition.new()
	def.part_type_id = ""
	assert_eq(def.validate(), ERR_INVALID_DATA)
