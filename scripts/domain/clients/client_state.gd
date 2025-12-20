extends RefCounted

class_name ClientState

const ItemInstanceScript := preload("res://scripts/domain/storage/item_instance.gd")

const PHASE_DROP_OFF := StringName("DROP_OFF")
const PHASE_PICK_UP := StringName("PICK_UP")
const PHASE_DONE := StringName("DONE")

const PRESENCE_PRESENT := StringName("PRESENT")
const PRESENCE_AWAY := StringName("AWAY")

var client_id: StringName
var assigned_service_point_id: StringName
var phase: StringName = PHASE_DROP_OFF
var presence: StringName = PRESENCE_PRESENT
var color_id: StringName = StringName()

var _coat_item: ItemInstance
var _ticket_item: ItemInstance

func _init(
	id: StringName,
	coat_item: ItemInstance,
	ticket_item: ItemInstance = null,
	desk_id: StringName = StringName(),
	client_color_id: StringName = StringName()
) -> void:
	client_id = id
	_coat_item = coat_item
	_ticket_item = ticket_item
	assigned_service_point_id = desk_id
	color_id = client_color_id

func get_coat_item() -> ItemInstance:
	return _coat_item

func get_ticket_item() -> ItemInstance:
	return _ticket_item

func get_coat_id() -> StringName:
	if _coat_item == null:
		return StringName()
	return _coat_item.id

func get_ticket_id() -> StringName:
	if _ticket_item == null:
		return StringName()
	return _ticket_item.id

func assign_ticket_item(ticket_item: ItemInstance) -> void:
	_ticket_item = ticket_item

func set_phase(new_phase: StringName) -> void:
	phase = new_phase

func set_presence(new_presence: StringName) -> void:
	presence = new_presence

func set_assigned_service_point(desk_id: StringName) -> void:
	assigned_service_point_id = desk_id
