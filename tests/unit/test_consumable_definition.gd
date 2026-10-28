extends GutTest

const BEANS_RES: ConsumableDefinition = preload("res://common/data/consumables/canned_beans.tres")
const CANTEEN_RES: ConsumableDefinition = preload(
	"res://common/data/consumables/water_canteen.tres"
)
const MEDKIT_RES: ConsumableDefinition = preload("res://common/data/consumables/medical_kit.tres")


func test_consumable_resources_valid() -> void:
	assert_not_null(BEANS_RES)
	assert_eq(BEANS_RES.validate(), OK)
	assert_gt(BEANS_RES.nutrition_value, 20.0)

	assert_not_null(CANTEEN_RES)
	assert_eq(CANTEEN_RES.validate(), OK)
	assert_gt(CANTEEN_RES.hydration_value, 30.0)

	assert_not_null(MEDKIT_RES)
	assert_eq(MEDKIT_RES.validate(), OK)
	assert_gt(MEDKIT_RES.health_value, 50.0)


func test_invalid_consumable_rejected() -> void:
	var item: ConsumableDefinition = ConsumableDefinition.new()
	item.item_id = ""
	item.display_name = ""
	assert_eq(item.validate(), ERR_INVALID_DATA)
