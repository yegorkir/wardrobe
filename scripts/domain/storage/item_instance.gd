extends RefCounted

class_name ItemInstance

const KIND_COAT := StringName("COAT")
const KIND_TICKET := StringName("TICKET")
const KIND_ANCHOR_TICKET := StringName("ANCHOR_TICKET")

var id: StringName
var kind: StringName
var color: Color

func _init(item_id: StringName, item_kind: StringName, item_color: Color = Color.WHITE) -> void:
	id = item_id
	kind = item_kind
	color = item_color

func duplicate_instance() -> ItemInstance:
	return get_script().new(id, kind, color) as ItemInstance

func to_snapshot() -> Dictionary:
	return {
		"id": id,
		"kind": kind,
		"color": color,
	}
