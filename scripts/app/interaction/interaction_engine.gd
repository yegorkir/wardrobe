extends RefCounted

class_name WardrobeInteractionEngine

const ResolverScript := preload("res://scripts/app/interaction/pick_put_swap_resolver.gd")
const CommandScript := preload("res://scripts/app/interaction/interaction_command.gd")
const StorageState := preload("res://scripts/domain/storage/wardrobe_storage_state.gd")
const ItemInstance := preload("res://scripts/domain/storage/item_instance.gd")

const RESULT_KEY_SUCCESS := "success"
const RESULT_KEY_REASON := "reason"
const RESULT_KEY_ACTION := "action"
const RESULT_KEY_EVENTS := "events"
const RESULT_KEY_HAND_ITEM := "hand_item"

const EVENT_KEY_TYPE := "type"
const EVENT_KEY_PAYLOAD := "payload"
const EVENT_ITEM_PLACED := StringName("item_placed")
const EVENT_ITEM_PICKED := StringName("item_picked")
const EVENT_ITEM_SWAPPED := StringName("item_swapped")
const EVENT_ACTION_REJECTED := StringName("action_rejected")

const PAYLOAD_SLOT_ID := StringName("slot_id")
const PAYLOAD_ITEM := StringName("item")
const PAYLOAD_OUTGOING_ITEM := StringName("outgoing_item")
const PAYLOAD_INCOMING_ITEM := StringName("incoming_item")
const PAYLOAD_REASON := StringName("reason")
const PAYLOAD_TICK := StringName("tick")

const REASON_CONTEXT_MISSING := StringName("context_missing")
const REASON_PAYLOAD_MISSING := StringName("payload_missing")
const REASON_SLOT_MISSING := StorageState.REASON_SLOT_MISSING
const REASON_SLOT_EMPTY := StorageState.REASON_SLOT_EMPTY
const REASON_SLOT_BLOCKED := StorageState.REASON_SLOT_BLOCKED
const REASON_SLOT_MISMATCH := StringName("slot_mismatch")
const REASON_HAND_MISMATCH := StringName("hand_mismatch")
const REASON_HAND_EMPTY := StringName("hand_empty")
const REASON_NOTHING_TO_DO := StringName("nothing_to_do")
const REASON_UNKNOWN_ACTION := StringName("unknown_action")

var _resolver := ResolverScript.new()

func process_command(command: Dictionary, context: Variant, hand_item: ItemInstance = null) -> Dictionary:
	if context is StorageState:
		return _process_with_storage(command, context as StorageState, hand_item)
	if context != null and context.has_method("get_slot"):
		return _process_with_target(command, context)
	return _make_result(false, REASON_CONTEXT_MISSING, ResolverScript.ACTION_NONE, [], hand_item)

func _process_with_storage(
	command: Dictionary,
	storage_state: StorageState,
	hand_item: ItemInstance
) -> Dictionary:
	if storage_state == null:
		return _make_result(false, REASON_CONTEXT_MISSING, ResolverScript.ACTION_NONE, [], hand_item)
	var payload := _read_payload(command)
	if payload.is_empty():
		return _make_result(false, REASON_PAYLOAD_MISSING, ResolverScript.ACTION_NONE, [], hand_item)
	var slot_id_variant: Variant = payload.get(CommandScript.PAYLOAD_SLOT_ID, "")
	var slot_id := StringName(str(slot_id_variant))
	if slot_id == StringName():
		return _reject_with_event(REASON_SLOT_MISSING, slot_id, hand_item, _read_tick(command))
	if not storage_state.has_slot(slot_id):
		return _reject_with_event(REASON_SLOT_MISSING, slot_id, hand_item, _read_tick(command))
	var slot_item := storage_state.get_slot_item(slot_id)
	if not _validate_expected_item(payload, CommandScript.PAYLOAD_SLOT_ITEM_ID, slot_item):
		return _reject_with_event(REASON_SLOT_MISMATCH, slot_id, hand_item, _read_tick(command))
	if not _validate_expected_item(payload, CommandScript.PAYLOAD_HAND_ITEM_ID, hand_item):
		return _reject_with_event(REASON_HAND_MISMATCH, slot_id, hand_item, _read_tick(command))
	var desired_action := _resolve_action(command, hand_item != null, slot_item != null)
	match desired_action:
		ResolverScript.ACTION_PICK:
			return _execute_pick(storage_state, slot_id, _read_tick(command))
		ResolverScript.ACTION_PUT:
			return _execute_put(storage_state, slot_id, hand_item, _read_tick(command))
		ResolverScript.ACTION_SWAP:
			return _execute_swap(storage_state, slot_id, hand_item, _read_tick(command))
		ResolverScript.ACTION_NONE:
			return _reject_with_event(REASON_NOTHING_TO_DO, slot_id, hand_item, _read_tick(command))
		_:
			return _reject_with_event(REASON_UNKNOWN_ACTION, slot_id, hand_item, _read_tick(command))

func _read_payload(command: Dictionary) -> Dictionary:
	var payload_variant: Variant = command.get(CommandScript.KEY_PAYLOAD, {})
	if payload_variant is Dictionary:
		return payload_variant as Dictionary
	return {}

func _read_tick(command: Dictionary) -> int:
	return int(command.get(CommandScript.KEY_TICK, 0))

func _resolve_action(command: Dictionary, hand_present: bool, slot_present: bool) -> String:
	var requested: StringName = command.get(CommandScript.KEY_TYPE, CommandScript.TYPE_AUTO)
	if requested == CommandScript.TYPE_PICK:
		return ResolverScript.ACTION_PICK
	if requested == CommandScript.TYPE_PUT:
		return ResolverScript.ACTION_PUT
	if requested == CommandScript.TYPE_SWAP:
		return ResolverScript.ACTION_SWAP
	var resolved := _resolver.resolve(hand_present, slot_present)
	return str(resolved.get("action", ResolverScript.ACTION_NONE))

func _validate_expected_item(payload: Dictionary, key: StringName, actual: ItemInstance) -> bool:
	var expected_variant: Variant = payload.get(key, "")
	if expected_variant == null:
		return true
	var expected_id := StringName(str(expected_variant))
	if expected_id == StringName():
		return true
	if actual == null:
		return false
	return actual.id == expected_id

func _execute_pick(storage_state: StorageState, slot_id: StringName, tick: int) -> Dictionary:
	var pick_result := storage_state.pick(slot_id)
	if not pick_result.get(StorageState.RESULT_KEY_SUCCESS, false):
		var reason: StringName = pick_result.get(StorageState.RESULT_KEY_REASON, REASON_SLOT_EMPTY)
		return _reject_with_event(reason, slot_id, null, tick)
	var picked: ItemInstance = pick_result.get(StorageState.RESULT_KEY_ITEM)
	var events := [
		_make_event(EVENT_ITEM_PICKED, {
			PAYLOAD_SLOT_ID: slot_id,
			PAYLOAD_ITEM: picked.to_snapshot(),
			PAYLOAD_TICK: tick,
		})
	]
	return _make_result(true, StorageState.REASON_OK, ResolverScript.ACTION_PICK, events, picked)

func _execute_put(
	storage_state: StorageState,
	slot_id: StringName,
	hand_item: ItemInstance,
	tick: int
) -> Dictionary:
	if hand_item == null:
		return _reject_with_event(REASON_HAND_EMPTY, slot_id, hand_item, tick)
	var put_result := storage_state.put(slot_id, hand_item)
	if not put_result.get(StorageState.RESULT_KEY_SUCCESS, false):
		var reason: StringName = put_result.get(StorageState.RESULT_KEY_REASON, REASON_SLOT_BLOCKED)
		return _reject_with_event(reason, slot_id, hand_item, tick)
	var events := [
		_make_event(EVENT_ITEM_PLACED, {
			PAYLOAD_SLOT_ID: slot_id,
			PAYLOAD_ITEM: hand_item.to_snapshot(),
			PAYLOAD_TICK: tick,
		})
	]
	return _make_result(true, StorageState.REASON_OK, ResolverScript.ACTION_PUT, events, null)

func _execute_swap(
	storage_state: StorageState,
	slot_id: StringName,
	hand_item: ItemInstance,
	tick: int
) -> Dictionary:
	if hand_item == null:
		return _reject_with_event(REASON_HAND_EMPTY, slot_id, hand_item, tick)
	var swap_result := storage_state.swap(slot_id, hand_item)
	if not swap_result.get(StorageState.RESULT_KEY_SUCCESS, false):
		var reason: StringName = swap_result.get(StorageState.RESULT_KEY_REASON, REASON_SLOT_EMPTY)
		return _reject_with_event(reason, slot_id, hand_item, tick)
	var outgoing: ItemInstance = swap_result.get(StorageState.RESULT_KEY_OUTGOING)
	var events := [
		_make_event(EVENT_ITEM_SWAPPED, {
			PAYLOAD_SLOT_ID: slot_id,
			PAYLOAD_INCOMING_ITEM: hand_item.to_snapshot(),
			PAYLOAD_OUTGOING_ITEM: outgoing.to_snapshot(),
			PAYLOAD_TICK: tick,
		})
	]
	return _make_result(true, StorageState.REASON_OK, ResolverScript.ACTION_SWAP, events, outgoing)

func _reject_with_event(
	reason: StringName,
	slot_id: StringName,
	hand_item: ItemInstance,
	tick: int
) -> Dictionary:
	var events := [
		_make_event(EVENT_ACTION_REJECTED, {
			PAYLOAD_SLOT_ID: slot_id,
			PAYLOAD_REASON: reason,
			PAYLOAD_TICK: tick,
		})
	]
	return _make_result(false, reason, ResolverScript.ACTION_NONE, events, hand_item)

func _make_event(event_type: StringName, payload: Dictionary) -> Dictionary:
	return {
		EVENT_KEY_TYPE: event_type,
		EVENT_KEY_PAYLOAD: payload.duplicate(true),
	}

func _make_result(
	success: bool,
	reason: StringName,
	action: String,
	events: Array,
	hand_item: ItemInstance
) -> Dictionary:
	return {
		RESULT_KEY_SUCCESS: success,
		RESULT_KEY_REASON: reason,
		RESULT_KEY_ACTION: action,
		RESULT_KEY_EVENTS: events,
		RESULT_KEY_HAND_ITEM: hand_item,
	}

# Legacy Node-based interaction path; kept for UI until adapters migrate to domain state.
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
		fail[RESULT_KEY_ACTION] = resolved.get("action", ResolverScript.ACTION_NONE)
		return fail
	var action := str(resolved.get("action", ResolverScript.ACTION_NONE))
	match action:
		ResolverScript.ACTION_PICK:
			var outcome: Dictionary = target.perform_pick(carrier_slot)
			outcome[RESULT_KEY_ACTION] = action
			return outcome
		ResolverScript.ACTION_PUT:
			var put_outcome: Dictionary = target.perform_put(carrier_slot)
			put_outcome[RESULT_KEY_ACTION] = action
			return put_outcome
		ResolverScript.ACTION_SWAP:
			var swap_outcome: Dictionary = target.perform_swap(carrier_slot)
			swap_outcome[RESULT_KEY_ACTION] = action
			return swap_outcome
		_:
			return _make_result(false, REASON_UNKNOWN_ACTION, action, [], null)
