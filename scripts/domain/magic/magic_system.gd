extends RefCounted

const INSURANCE_MODE_FREE := "FREE"
const INSURANCE_MODE_SOFT_LIMIT := "SOFT_LIMIT"

const EMERGENCY_COST_DEBT := "DEBT"
const EMERGENCY_COST_TIPS := "TIPS"
const EMERGENCY_COST_SHIFT_CASH := "SHIFT_CASH"

var _config := {}

func setup(config: Dictionary) -> void:
	_config = {
		"insurance_mode": INSURANCE_MODE_FREE,
		"emergency_cost_mode": EMERGENCY_COST_DEBT,
		"insurance_cost": 0,
		"emergency_cost_value": 0,
		"soft_limit": 0,
		"search_effect": "REVEAL_SLOT",
	}
	for key in config.keys():
		_config[key] = config[key]

func get_config() -> Dictionary:
	return _config.duplicate(true)

func apply_insurance(run_state: RunState, ticket_number: int, item_ids: Array) -> Dictionary:
	run_state.set_magic_links(ticket_number, item_ids)
	return {
		"type": "insurance_link",
		"ticket_number": ticket_number,
		"items": item_ids.duplicate(true),
		"mode": _config["insurance_mode"],
		"cost": _config["insurance_cost"],
	}

func request_emergency_locate(_run_state: RunState, ticket_number: int) -> Dictionary:
	var cost_type: String = _config["emergency_cost_mode"]
	var cost_value: int = _config["emergency_cost_value"]
	return {
		"type": "emergency_locate",
		"ticket_number": ticket_number,
		"highlight": null,
		"cost_type": cost_type,
		"cost_value": cost_value,
		"mode": _config["search_effect"],
	}
