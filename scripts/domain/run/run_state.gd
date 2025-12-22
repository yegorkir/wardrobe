extends RefCounted

class_name RunState

var shift_index: int = 0
var wave_index: int = 0
var cleanliness_or_entropy: float = 0.0
var inspector_risk: float = 0.0
var magic_links: Dictionary = {}
var shift_payout_debt: int = 0
var magic_config: Dictionary = {}
var inspection_config: Dictionary = {}

func reset_for_shift() -> void:
	shift_index += 1
	wave_index = 1
	cleanliness_or_entropy = 0.0
	inspector_risk = 0.0
	shift_payout_debt = 0
	magic_links.clear()

func set_magic_links(ticket_number: int, item_ids: Array) -> void:
	magic_links[ticket_number] = item_ids.duplicate(true)

func get_magic_links() -> Dictionary:
	return magic_links.duplicate(true)
