extends RefCounted

class_name WardrobeInteractionDomainEngine

const ResolverScript := preload("res://scripts/app/interaction/pick_put_swap_resolver.gd")
const CommandScript := preload("res://scripts/app/interaction/interaction_command.gd")
const EventSchema := preload("res://scripts/domain/events/event_schema.gd")

const REASON_CONTEXT_MISSING := StringName("context_missing")
const REASON_PAYLOAD_MISSING := StringName("payload_missing")
const REASON_SLOT_MISSING := WardrobeStorageState.REASON_SLOT_MISSING
const REASON_SLOT_EMPTY := WardrobeStorageState.REASON_SLOT_EMPTY
const REASON_SLOT_BLOCKED := WardrobeStorageState.REASON_SLOT_BLOCKED
const REASON_SLOT_MISMATCH := StringName("slot_mismatch")
const REASON_HAND_MISMATCH := StringName("hand_mismatch")
const REASON_HAND_EMPTY := StringName("hand_empty")
const REASON_NOTHING_TO_DO := StringName("nothing_to_do")
const REASON_UNKNOWN_ACTION := StringName("unknown_action")

var _resolver := ResolverScript.new()

func process_command(command: Dictionary, context: Variant, hand_item: ItemInstance = null) -> InteractionResult:
	if context is WardrobeStorageState:
		return _process_with_storage(command, context as WardrobeStorageState, hand_item)
	return _make_result(false, REASON_CONTEXT_MISSING, ResolverScript.ACTION_NONE, [], hand_item)

func _process_with_storage(
	command: Dictionary,
	storage_state: WardrobeStorageState,
	hand_item: ItemInstance
) -> InteractionResult:
	if storage_state == null:
		return _make_result(false, REASON_CONTEXT_MISSING, ResolverScript.ACTION_NONE, [], hand_item)
	var tick := _read_tick(command)
	var payload := _read_payload(command)
	if payload.is_empty():
		return _make_result(false, REASON_PAYLOAD_MISSING, ResolverScript.ACTION_NONE, [], hand_item)
	var slot_id_variant: Variant = payload.get(CommandScript.PAYLOAD_SLOT_ID, "")
	var slot_id := StringName(str(slot_id_variant))
	var slot_item := storage_state.get_slot_item(slot_id)
	var validation := _validate_request(storage_state, payload, slot_id, slot_item, hand_item, tick)
	if validation != null:
		return validation
	var desired_action := _resolve_action(command, hand_item != null, slot_item != null)
	match desired_action:
		ResolverScript.ACTION_PICK:
			return _execute_pick(storage_state, slot_id, tick)
		ResolverScript.ACTION_PUT:
			return _execute_put(storage_state, slot_id, hand_item, tick)
		ResolverScript.ACTION_SWAP:
			return _execute_swap(storage_state, slot_id, hand_item, tick)
		ResolverScript.ACTION_NONE:
			return _reject_with_event(REASON_NOTHING_TO_DO, slot_id, hand_item, tick)
		_:
			return _reject_with_event(REASON_UNKNOWN_ACTION, slot_id, hand_item, tick)

func _validate_request(
	storage_state: WardrobeStorageState,
	payload: Dictionary,
	slot_id: StringName,
	slot_item: ItemInstance,
	hand_item: ItemInstance,
	tick: int
) -> InteractionResult:
	if slot_id == StringName():
		return _reject_with_event(REASON_SLOT_MISSING, slot_id, hand_item, tick)
	if not storage_state.has_slot(slot_id):
		return _reject_with_event(REASON_SLOT_MISSING, slot_id, hand_item, tick)
	if not _validate_expected_item(payload, CommandScript.PAYLOAD_SLOT_ITEM_ID, slot_item):
		return _reject_with_event(REASON_SLOT_MISMATCH, slot_id, hand_item, tick)
	if not _validate_expected_item(payload, CommandScript.PAYLOAD_HAND_ITEM_ID, hand_item):
		return _reject_with_event(REASON_HAND_MISMATCH, slot_id, hand_item, tick)
	return null

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

func _execute_pick(storage_state: WardrobeStorageState, slot_id: StringName, tick: int) -> InteractionResult:
	var pick_result := storage_state.pick(slot_id)
	if not pick_result.get(WardrobeStorageState.RESULT_KEY_SUCCESS, false):
		var reason: StringName = pick_result.get(WardrobeStorageState.RESULT_KEY_REASON, REASON_SLOT_EMPTY)
		return _reject_with_event(reason, slot_id, null, tick)
	var picked: ItemInstance = pick_result.get(WardrobeStorageState.RESULT_KEY_ITEM)
	var events := [
		_make_event(EventSchema.EVENT_ITEM_PICKED, {
			EventSchema.PAYLOAD_SLOT_ID: slot_id,
			EventSchema.PAYLOAD_ITEM: picked.to_snapshot(),
			EventSchema.PAYLOAD_TICK: tick,
		})
	]
	return _make_result(true, WardrobeStorageState.REASON_OK, ResolverScript.ACTION_PICK, events, picked)

func _execute_put(
	storage_state: WardrobeStorageState,
	slot_id: StringName,
	hand_item: ItemInstance,
	tick: int
) -> InteractionResult:
	if hand_item == null:
		return _reject_with_event(REASON_HAND_EMPTY, slot_id, hand_item, tick)
	var put_result := storage_state.put(slot_id, hand_item)
	if not put_result.get(WardrobeStorageState.RESULT_KEY_SUCCESS, false):
		var reason: StringName = put_result.get(WardrobeStorageState.RESULT_KEY_REASON, REASON_SLOT_BLOCKED)
		return _reject_with_event(reason, slot_id, hand_item, tick)
	var events := [
		_make_event(EventSchema.EVENT_ITEM_PLACED, {
			EventSchema.PAYLOAD_SLOT_ID: slot_id,
			EventSchema.PAYLOAD_ITEM: hand_item.to_snapshot(),
			EventSchema.PAYLOAD_TICK: tick,
		})
	]
	return _make_result(true, WardrobeStorageState.REASON_OK, ResolverScript.ACTION_PUT, events, null)

func _execute_swap(
	storage_state: WardrobeStorageState,
	slot_id: StringName,
	hand_item: ItemInstance,
	tick: int
) -> InteractionResult:
	if hand_item == null:
		return _reject_with_event(REASON_HAND_EMPTY, slot_id, hand_item, tick)
	var swap_result := storage_state.swap(slot_id, hand_item)
	if not swap_result.get(WardrobeStorageState.RESULT_KEY_SUCCESS, false):
		var reason: StringName = swap_result.get(WardrobeStorageState.RESULT_KEY_REASON, REASON_SLOT_EMPTY)
		return _reject_with_event(reason, slot_id, hand_item, tick)
	var outgoing: ItemInstance = swap_result.get(WardrobeStorageState.RESULT_KEY_OUTGOING)
	var events := [
		_make_event(EventSchema.EVENT_ITEM_SWAPPED, {
			EventSchema.PAYLOAD_SLOT_ID: slot_id,
			EventSchema.PAYLOAD_INCOMING_ITEM: hand_item.to_snapshot(),
			EventSchema.PAYLOAD_OUTGOING_ITEM: outgoing.to_snapshot(),
			EventSchema.PAYLOAD_TICK: tick,
		})
	]
	return _make_result(true, WardrobeStorageState.REASON_OK, ResolverScript.ACTION_SWAP, events, outgoing)

func _reject_with_event(
	reason: StringName,
	slot_id: StringName,
	hand_item: ItemInstance,
	tick: int
) -> InteractionResult:
	var events := [
		_make_event(EventSchema.EVENT_ACTION_REJECTED, {
			EventSchema.PAYLOAD_SLOT_ID: slot_id,
			EventSchema.PAYLOAD_REASON: reason,
			EventSchema.PAYLOAD_TICK: tick,
		})
	]
	return _make_result(false, reason, ResolverScript.ACTION_NONE, events, hand_item)

func _make_event(event_type: StringName, payload: Dictionary) -> Dictionary:
	return {
		EventSchema.EVENT_KEY_TYPE: event_type,
		EventSchema.EVENT_KEY_PAYLOAD: payload.duplicate(true),
	}

func _make_result(
	success: bool,
	reason: StringName,
	action: String,
	events: Array,
	hand_item: ItemInstance
) -> InteractionResult:
	return InteractionResult.new(success, reason, action, events, hand_item)
