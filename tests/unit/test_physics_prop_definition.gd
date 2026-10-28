extends GutTest

const WOOD_CRATE_DEF: PhysicalPropDefinition = preload("res://common/data/props/wood_crate.tres")
const IRON_ANVIL_DEF: PhysicalPropDefinition = preload("res://common/data/props/iron_anvil.tres")


func test_wood_crate_definition() -> void:
	assert_not_null(WOOD_CRATE_DEF)
	assert_eq(WOOD_CRATE_DEF.validate(), OK)
	assert_eq(WOOD_CRATE_DEF.prop_id, "wood_crate")
	assert_almost_eq(WOOD_CRATE_DEF.mass_kg, 18.0, 0.01)
	assert_false(WOOD_CRATE_DEF.is_two_handed)
	assert_gt(WOOD_CRATE_DEF.base_throw_impulse, 10.0)


func test_iron_anvil_definition() -> void:
	assert_not_null(IRON_ANVIL_DEF)
	assert_eq(IRON_ANVIL_DEF.validate(), OK)
	assert_eq(IRON_ANVIL_DEF.prop_id, "iron_anvil")
	assert_almost_eq(IRON_ANVIL_DEF.mass_kg, 75.0, 0.01)
	assert_true(IRON_ANVIL_DEF.is_two_handed)
	assert_lt(IRON_ANVIL_DEF.base_throw_impulse, WOOD_CRATE_DEF.base_throw_impulse)


func test_invalid_definition_rejected() -> void:
	var def: PhysicalPropDefinition = PhysicalPropDefinition.new()
	def.prop_id = ""
	def.display_name = ""
	assert_eq(def.validate(), ERR_INVALID_DATA)

	def.prop_id = "test"
	def.display_name = "Test"
	def.mass_kg = -5.0
	assert_eq(def.validate(), ERR_INVALID_PARAMETER)
