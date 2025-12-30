extends RefCounted
class_name WardrobeItemConfig

const PlacementTypes := preload("res://scripts/app/wardrobe/placement/placement_types.gd")
const ItemInstanceScript := preload("res://scripts/domain/storage/item_instance.gd")

const ITEM_ID_PREFIX_BOTTLE := "bottle_"
const ITEM_ID_PREFIX_CHEST := "chest_"
const ITEM_ID_PREFIX_HAT := "hat_"

const ITEM_DATA := {
	ItemNode.ItemType.COAT: {
		"place_flags": PlacementTypes.PlaceFlags.HANG,
		"kind": ItemInstanceScript.KIND_COAT,
	},
	ItemNode.ItemType.TICKET: {
		"place_flags": PlacementTypes.PlaceFlags.HANG,
		"kind": ItemInstanceScript.KIND_TICKET,
	},
	ItemNode.ItemType.ANCHOR_TICKET: {
		"place_flags": PlacementTypes.PlaceFlags.HANG,
		"kind": ItemInstanceScript.KIND_ANCHOR_TICKET,
	},
	ItemNode.ItemType.BOTTLE: {
		"place_flags": PlacementTypes.PlaceFlags.LAY,
		"kind": ItemInstanceScript.KIND_COAT,
	},
	ItemNode.ItemType.CHEST: {
		"place_flags": PlacementTypes.PlaceFlags.LAY,
		"kind": ItemInstanceScript.KIND_COAT,
	},
	ItemNode.ItemType.HAT: {
		"place_flags": PlacementTypes.PlaceFlags.HANG | PlacementTypes.PlaceFlags.LAY,
		"kind": ItemInstanceScript.KIND_COAT,
	},
}

const DEMO_ITEM_TYPES_BY_CLIENT := [
	ItemNode.ItemType.BOTTLE,
	ItemNode.ItemType.HAT,
	ItemNode.ItemType.CHEST,
	ItemNode.ItemType.COAT,
]

static func get_place_flags(item_type: int) -> int:
	return int(_get_item_data(item_type).get("place_flags", 0))

static func get_kind_for_item_type(item_type: int) -> StringName:
	return StringName(_get_item_data(item_type).get("kind", ItemInstanceScript.KIND_COAT))

static func resolve_item_type(item_id: StringName, kind: StringName) -> ItemNode.ItemType:
	var id_text := String(item_id)
	if id_text.begins_with(ITEM_ID_PREFIX_BOTTLE):
		return ItemNode.ItemType.BOTTLE
	if id_text.begins_with(ITEM_ID_PREFIX_CHEST):
		return ItemNode.ItemType.CHEST
	if id_text.begins_with(ITEM_ID_PREFIX_HAT):
		return ItemNode.ItemType.HAT
	match kind:
		ItemInstanceScript.KIND_TICKET:
			return ItemNode.ItemType.TICKET
		ItemInstanceScript.KIND_ANCHOR_TICKET:
			return ItemNode.ItemType.ANCHOR_TICKET
		_:
			return ItemNode.ItemType.COAT

static func build_client_item_id(item_type: int, index: int) -> StringName:
	match item_type:
		ItemNode.ItemType.BOTTLE:
			return StringName("%s%02d" % [ITEM_ID_PREFIX_BOTTLE, index])
		ItemNode.ItemType.CHEST:
			return StringName("%s%02d" % [ITEM_ID_PREFIX_CHEST, index])
		ItemNode.ItemType.HAT:
			return StringName("%s%02d" % [ITEM_ID_PREFIX_HAT, index])
		_:
			return StringName("coat_%02d" % index)

static func get_demo_item_type_for_client(index: int) -> int:
	if DEMO_ITEM_TYPES_BY_CLIENT.is_empty():
		return ItemNode.ItemType.COAT
	return DEMO_ITEM_TYPES_BY_CLIENT[index % DEMO_ITEM_TYPES_BY_CLIENT.size()]

static func _get_item_data(item_type: int) -> Dictionary:
	return ITEM_DATA.get(item_type, ITEM_DATA[ItemNode.ItemType.COAT])
