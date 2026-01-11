extends RefCounted

class_name RunState

const SHIFT_STATUS_RUNNING := StringName("running")
const SHIFT_STATUS_FAILED := StringName("failed")
const SHIFT_STATUS_SUCCESS := StringName("success")

var shift_index: int = 0
var wave_index: int = 0
var cleanliness_or_entropy: float = 0.0
var inspector_risk: float = 0.0
var magic_links: Dictionary = {}
var shift_payout_debt: int = 0
var magic_config: Dictionary = {}
var inspection_config: Dictionary = {}
var shift_status: StringName = SHIFT_STATUS_RUNNING
var total_clients: int = 0
var served_clients: int = 0
var active_clients: int = 0

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

func set_magic_links(ticket_number: int, item_ids: Array) -> void:
	magic_links[ticket_number] = item_ids.duplicate(true)

func get_magic_links() -> Dictionary:
	return magic_links.duplicate(true)
