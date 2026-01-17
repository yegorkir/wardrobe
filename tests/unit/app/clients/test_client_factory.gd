extends GdUnitTestSuite

const ClientFactoryScript := preload("res://scripts/app/clients/client_factory.gd")
const WardrobeItemConfigScript := preload("res://scripts/ui/wardrobe_item_config.gd")
const ItemInstanceScript := preload("res://scripts/domain/storage/item_instance.gd")

func test_checkin_client_item_type_cycles() -> void:
	var factory := ClientFactoryScript.new()
	factory.configure(null, Callable())

	var prefixes := [
		WardrobeItemConfigScript.ITEM_ID_PREFIX_BOTTLE,
		WardrobeItemConfigScript.ITEM_ID_PREFIX_CHEST,
		WardrobeItemConfigScript.ITEM_ID_PREFIX_HAT,
		"coat_",
	]

	for index in range(4):
		var client = factory.build_checkin_client(index)
		var item: ItemInstance = client.get_coat_item()
		assert_that(item).is_not_null()
		assert_that(item.kind).is_equal(ItemInstanceScript.KIND_COAT)
		assert_bool(_has_any_prefix(String(item.id), prefixes)).is_true()

func _has_any_prefix(value: String, prefixes: Array) -> bool:
	for prefix in prefixes:
		if value.begins_with(String(prefix)):
			return true
	return false
