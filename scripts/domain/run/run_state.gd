extends RefCounted

class_name RunState

const MagicConfigScript := preload("res://scripts/domain/magic/magic_config.gd")
const InspectionConfigScript := preload("res://scripts/domain/inspection/inspection_config.gd")
const ItemInstanceScript := preload("res://scripts/domain/storage/item_instance.gd")

const SHIFT_STATUS_RUNNING := StringName("running")
const SHIFT_STATUS_FAILED := StringName("failed")
const SHIFT_STATUS_SUCCESS := StringName("success")

var shift_index: int = 0
var wave_index: int = 0
var cleanliness_or_entropy: float = 0.0
var inspector_risk: float = 0.0
var magic_links: Dictionary = {}
var shift_payout_debt: int = 0
var magic_config: MagicConfigScript
var inspection_config: InspectionConfigScript
var shift_status: StringName = SHIFT_STATUS_RUNNING
var total_clients: int = 0
var served_clients: int = 0
var active_clients: int = 0
var target_checkin: int = 0
var target_checkout: int = 0
var checkin_done: int = 0
var checkout_done: int = 0
var completed_checkins: Dictionary = {}
var completed_checkouts: Dictionary = {}
var item_registry: Dictionary = {} # item_id -> ItemInstance

func reset_for_shift() -> void:
	shift_index += 1
	wave_index = 1
	cleanliness_or_entropy = 0.0
	inspector_risk = 0.0
	shift_payout_debt = 0
	magic_links.clear()
	shift_status = SHIFT_STATUS_RUNNING
	total_clients = 0
	served_clients = 0
	active_clients = 0
	target_checkin = 0
	target_checkout = 0
	checkin_done = 0
	checkout_done = 0
	completed_checkins.clear()
	completed_checkouts.clear()
	item_registry.clear()

func register_item(item: ItemInstanceScript) -> void:
	if item == null:
		return
	item_registry[item.id] = item

func find_item(item_id: StringName) -> ItemInstanceScript:
	return item_registry.get(item_id) as ItemInstanceScript

func set_magic_links(ticket_number: int, item_ids: Array[StringName]) -> void:
	magic_links[ticket_number] = item_ids.duplicate(true)

func get_magic_links() -> Dictionary:
	return magic_links.duplicate(true)

func configure_shift_targets(checkin_target: int, checkout_target: int) -> void:
	target_checkin = max(0, checkin_target)
	target_checkout = max(0, checkout_target)
	checkin_done = 0
	checkout_done = 0
	completed_checkins.clear()
	completed_checkouts.clear()

func register_checkin_completed(client_id: StringName) -> bool:
	if client_id == StringName():
		return false
	if completed_checkins.has(client_id):
		return false
	completed_checkins[client_id] = true
	checkin_done += 1
	return true

func register_checkout_completed(client_id: StringName) -> bool:
	if client_id == StringName():
		return false
	if completed_checkouts.has(client_id):
		return false
	completed_checkouts[client_id] = true
	checkout_done += 1
	return true

func get_need_checkin() -> int:
	return max(0, target_checkin - checkin_done)

func get_need_checkout() -> int:
	return max(0, target_checkout - checkout_done)

func get_outstanding_checkout() -> int:
	return checkin_done - checkout_done