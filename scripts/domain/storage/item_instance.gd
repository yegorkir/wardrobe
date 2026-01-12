extends RefCounted

class_name ItemInstance

const ItemQualityConfigScript := preload("res://scripts/domain/quality/item_quality_config.gd")
const ItemQualityStateScript := preload("res://scripts/domain/quality/item_quality_state.gd")

const KIND_COAT := StringName("COAT")
const KIND_TICKET := StringName("TICKET")
const KIND_ANCHOR_TICKET := StringName("ANCHOR_TICKET")

var id: StringName
var kind: StringName
var color: Color
var quality_state: RefCounted # ItemQualityState

func _init(item_id: StringName, item_kind: StringName, item_color: Color = Color.WHITE, p_quality_state: RefCounted = null) -> void:
	id = item_id
	kind = item_kind
	color = item_color
	
	if p_quality_state:
		quality_state = p_quality_state
	else:
		# MVP Default: 3 stars
		var default_config = ItemQualityConfigScript.new(3)
		quality_state = ItemQualityStateScript.new(default_config)

func duplicate_instance() -> ItemInstance:
	var dup_quality = null
	if quality_state:
		dup_quality = quality_state.call("duplicate_state")
	return get_script().new(id, kind, color, dup_quality) as ItemInstance

func to_snapshot() -> Dictionary:
	var snapshot := {
		"id": id,
		"kind": kind,
		"color": color,
	}
	if quality_state:
		snapshot["quality"] = quality_state.call("to_snapshot")
	return snapshot
