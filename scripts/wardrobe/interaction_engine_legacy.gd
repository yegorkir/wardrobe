extends RefCounted

const ResolverScript := preload("res://scripts/app/interaction/pick_put_swap_resolver.gd")
const CommandScript := preload("res://scripts/app/interaction/interaction_command.gd")
const EventSchema := preload("res://scripts/domain/interaction/interaction_event_schema.gd")

const REASON_CONTEXT_MISSING := StringName("context_missing")
const REASON_PAYLOAD_MISSING := StringName("payload_missing")
const REASON_SLOT_MISSING := StringName("slot_missing")
const REASON_UNKNOWN_ACTION := StringName("unknown_action")

var _resolver := ResolverScript.new()

func process_command(command: Dictionary, context: Variant, _hand_item: Variant = null) -> Dictionary:
	return _process_with_target(command, context)

func _process_with_target(command: Dictionary, target: Variant) -> Dictionary:
	if target == null:
		return _make_result(false, REASON_CONTEXT_MISSING, ResolverScript.ACTION_NONE, [], null)
	var payload := _read_payload(command)
	if payload.is_empty():
		return _make_result(false, REASON_PAYLOAD_MISSING, ResolverScript.ACTION_NONE, [], null)
	var slot_id := str(payload.get(CommandScript.PAYLOAD_SLOT_ID, ""))
	var carrier_slot: Variant = target.get_slot(slot_id)
	if carrier_slot == null:
		return _make_result(false, REASON_SLOT_MISSING, ResolverScript.ACTION_NONE, [], null)
	var hand_item_id := str(payload.get(CommandScript.PAYLOAD_HAND_ITEM_ID, ""))
	var slot_item_id := str(payload.get(CommandScript.PAYLOAD_SLOT_ITEM_ID, ""))
	var hand_state: Variant = target.get_hand_item(hand_item_id)
	var slot_state: Variant = target.get_slot_item(carrier_slot, slot_item_id)
	var resolved := _resolver.resolve(hand_state != null, slot_state != null)
	if not resolved.get("success", false):
		var fail := resolved.duplicate(true)
		fail[EventSchema.RESULT_KEY_ACTION] = resolved.get("action", ResolverScript.ACTION_NONE)
		return fail
	var action := str(resolved.get("action", ResolverScript.ACTION_NONE))
	match action:
		ResolverScript.ACTION_PICK:
			var outcome: Dictionary = target.perform_pick(carrier_slot)
			outcome[EventSchema.RESULT_KEY_ACTION] = action
			return outcome
		ResolverScript.ACTION_PUT:
			var put_outcome: Dictionary = target.perform_put(carrier_slot)
			put_outcome[EventSchema.RESULT_KEY_ACTION] = action
			return put_outcome
		ResolverScript.ACTION_SWAP:
			var swap_outcome: Dictionary = target.perform_swap(carrier_slot)
			swap_outcome[EventSchema.RESULT_KEY_ACTION] = action
			return swap_outcome
		_:
			return _make_result(false, REASON_UNKNOWN_ACTION, action, [], null)

func _read_payload(command: Dictionary) -> Dictionary:
	var payload_variant: Variant = command.get(CommandScript.KEY_PAYLOAD, {})
	if payload_variant is Dictionary:
		return payload_variant as Dictionary
	return {}

func _make_result(
	success: bool,
	reason: StringName,
	action: String,
	events: Array,
	hand_item: Variant
) -> Dictionary:
	return {
		EventSchema.RESULT_KEY_SUCCESS: success,
		EventSchema.RESULT_KEY_REASON: reason,
		EventSchema.RESULT_KEY_ACTION: action,
		EventSchema.RESULT_KEY_EVENTS: events,
		EventSchema.RESULT_KEY_HAND_ITEM: hand_item,
	}
