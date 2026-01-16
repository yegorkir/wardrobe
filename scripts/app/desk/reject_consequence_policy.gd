extends RefCounted

class_name DeskRejectConsequencePolicy

const EventSchema := preload("res://scripts/domain/events/event_schema.gd")
const ClientStateScript := preload("res://scripts/domain/clients/client_state.gd")

func evaluate(reason_code: StringName, _client_phase: StringName) -> Dictionary:
	var apply_patience_penalty := false
	var penalty_reason := StringName()
	if reason_code == EventSchema.REASON_WRONG_ITEM:
		apply_patience_penalty = true
		penalty_reason = EventSchema.REASON_WRONG_ITEM
	return {
		"apply_patience_penalty": apply_patience_penalty,
		"penalty_reason": penalty_reason,
	}
