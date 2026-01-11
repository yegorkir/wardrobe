extends RefCounted

const MagicConfigScript := preload("res://scripts/domain/magic/magic_config.gd")
const MagicEventScript := preload("res://scripts/domain/magic/magic_event.gd")
const INSURANCE_MODE_FREE := StringName("FREE")
const INSURANCE_MODE_SOFT_LIMIT := StringName("SOFT_LIMIT")

const EMERGENCY_COST_DEBT := StringName("DEBT")
const EMERGENCY_COST_TIPS := StringName("TIPS")
const EMERGENCY_COST_SHIFT_CASH := StringName("SHIFT_CASH")

const SEARCH_EFFECT_REVEAL_SLOT := StringName("REVEAL_SLOT")

var _config: MagicConfigScript = _build_default_config()

func setup(config: MagicConfigScript) -> void:
	_config = config.duplicate_config() if config else _build_default_config()

func get_config() -> MagicConfigScript:
	return _config.duplicate_config()

func apply_insurance(
	run_state: RunState,
	ticket_number: int,
	item_ids: Array[StringName]
) -> MagicEventScript:
	run_state.set_magic_links(ticket_number, item_ids)
	return MagicEventScript.new(
		MagicEventScript.TYPE_INSURANCE_LINK,
		ticket_number,
		item_ids,
		_config.insurance_mode,
		StringName(),
		_config.insurance_cost,
		null
	)

func request_emergency_locate(_run_state: RunState, ticket_number: int) -> MagicEventScript:
	return MagicEventScript.new(
		MagicEventScript.TYPE_EMERGENCY_LOCATE,
		ticket_number,
		[],
		_config.search_effect,
		_config.emergency_cost_mode,
		_config.emergency_cost_value,
		null
	)

func _build_default_config() -> MagicConfigScript:
	return MagicConfigScript.new(
		INSURANCE_MODE_FREE,
		EMERGENCY_COST_DEBT,
		0,
		0,
		0,
		SEARCH_EFFECT_REVEAL_SLOT
	)
