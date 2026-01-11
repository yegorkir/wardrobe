extends RefCounted

class_name WardrobeInteractionDomainEngine

const InteractionCommandScript := preload("res://scripts/domain/interaction/interaction_command.gd")
const InteractionEventScript := preload("res://scripts/domain/interaction/interaction_event.gd")
const InteractionResultScript := preload("res://scripts/domain/interaction/interaction_result.gd")
const ItemInstanceScript := preload("res://scripts/domain/storage/item_instance.gd")
const StorageStateScript := preload("res://scripts/domain/storage/wardrobe_storage_state.gd")

const ResolverScript := preload("res://scripts/app/interaction/pick_put_swap_resolver.gd")
const InteractionConfigScript := preload("res://scripts/app/interaction/interaction_config.gd")
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
const REASON_SWAP_DISABLED := StringName("swap_disabled")
const REASON_UNKNOWN_ACTION := StringName("unknown_action")

var _resolver := ResolverScript.new()

func setup(config: InteractionConfigScript) -> void:
	if _resolver and _resolver.has_method("setup"):
		_resolver.setup(config)

func process_command(
	command: InteractionCommandScript,
	context: Variant,
	hand_item: ItemInstance = null
) -> InteractionResultScript:
	if context is WardrobeStorageState:
		return _process_with_storage(command, context as WardrobeStorageState, hand_item)
	return _make_result(false, REASON_CONTEXT_MISSING, ResolverScript.ACTION_NONE, [], hand_item)

func _process_with_storage(
	command: InteractionCommandScript,
	storage_state: WardrobeStorageState,
	hand_item: ItemInstance
) -> InteractionResultScript:
	if storage_state == null:
		return _make_result(false, REASON_CONTEXT_MISSING, ResolverScript.ACTION_NONE, [], hand_item)
	if command == null:
		return _make_result(false, REASON_PAYLOAD_MISSING, ResolverScript.ACTION_NONE, [], hand_item)
	var tick := command.tick
	var slot_id := command.slot_id
	var slot_item := storage_state.get_slot_item(slot_id)
	var validation := _validate_request(storage_state, command, slot_id, slot_item, hand_item, tick)
	if validation != null:
		return validation
	var resolution := _resolve_action_result(command, hand_item != null, slot_item != null)
	var desired_action: String = resolution.get("action", ResolverScript.ACTION_NONE)
	var resolved_reason: StringName = resolution.get("reason", REASON_NOTHING_TO_DO)
	match desired_action:
		ResolverScript.ACTION_PICK:
			return _execute_pick(storage_state, slot_id, tick)
		ResolverScript.ACTION_PUT:
			return _execute_put(storage_state, slot_id, hand_item, tick)
		ResolverScript.ACTION_NONE:
			return _reject_with_event(resolved_reason, slot_id, hand_item, tick)
		_:
			return _reject_with_event(REASON_UNKNOWN_ACTION, slot_id, hand_item, tick)

func _validate_request(
	storage_state: WardrobeStorageState,
	command: InteractionCommandScript,
	slot_id: StringName,
	slot_item: ItemInstance,
	hand_item: ItemInstance,
	tick: int
) -> InteractionResultScript:
	if slot_id == StringName():
		return _reject_with_event(REASON_SLOT_MISSING, slot_id, hand_item, tick)
	if not storage_state.has_slot(slot_id):
		return _reject_with_event(REASON_SLOT_MISSING, slot_id, hand_item, tick)
	if not _validate_expected_item(command.slot_item_id, slot_item):
		return _reject_with_event(REASON_SLOT_MISMATCH, slot_id, hand_item, tick)
	if not _validate_expected_item(command.hand_item_id, hand_item):
		return _reject_with_event(REASON_HAND_MISMATCH, slot_id, hand_item, tick)
	return null

func _resolve_action_result(
	command: InteractionCommandScript,
	hand_present: bool,
	slot_present: bool
) -> Dictionary:
	var requested: StringName = command.action
	if requested == InteractionCommandScript.TYPE_PICK:
		return {"action": ResolverScript.ACTION_PICK, "reason": REASON_NOTHING_TO_DO}
	if requested == InteractionCommandScript.TYPE_PUT:
		return {"action": ResolverScript.ACTION_PUT, "reason": REASON_NOTHING_TO_DO}
	var resolved := _resolver.resolve(hand_present, slot_present)
	return {
		"action": str(resolved.get("action", ResolverScript.ACTION_NONE)),
		"reason": StringName(str(resolved.get("reason", REASON_NOTHING_TO_DO))),
	}

func _validate_expected_item(expected_id: StringName, actual: ItemInstance) -> bool:
	if expected_id == StringName():
		return true
	if actual == null:
		return false
	return actual.id == expected_id

func _execute_pick(
	storage_state: WardrobeStorageState,
	slot_id: StringName,
	tick: int
) -> InteractionResultScript:
	var pick_result := storage_state.pick(slot_id)
	if not pick_result.success:
		var reason: StringName = pick_result.reason
		return _reject_with_event(reason, slot_id, null, tick)
	var picked: ItemInstance = pick_result.item
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
) -> InteractionResultScript:
	if hand_item == null:
		return _reject_with_event(REASON_HAND_EMPTY, slot_id, hand_item, tick)
	var put_result := storage_state.put(slot_id, hand_item)
	if not put_result.success:
		var reason: StringName = put_result.reason
		return _reject_with_event(reason, slot_id, hand_item, tick)
	var events := [
		_make_event(EventSchema.EVENT_ITEM_PLACED, {
			EventSchema.PAYLOAD_SLOT_ID: slot_id,
			EventSchema.PAYLOAD_ITEM: hand_item.to_snapshot(),
			EventSchema.PAYLOAD_TICK: tick,
		})
	]
	return _make_result(true, WardrobeStorageState.REASON_OK, ResolverScript.ACTION_PUT, events, null)


func _reject_with_event(
	reason: StringName,
	slot_id: StringName,
	hand_item: ItemInstance,
	tick: int
) -> InteractionResultScript:
	var events := [
		_make_event(EventSchema.EVENT_ACTION_REJECTED, {
			EventSchema.PAYLOAD_SLOT_ID: slot_id,
			EventSchema.PAYLOAD_REASON: reason,
			EventSchema.PAYLOAD_TICK: tick,
		})
	]
	return _make_result(false, reason, ResolverScript.ACTION_NONE, events, hand_item)

func _make_event(event_type: StringName, payload: Dictionary) -> InteractionEventScript:
	return InteractionEventScript.new(event_type, payload)

func _make_result(
	success: bool,
	reason: StringName,
	action: String,
	events: Array,
	hand_item: ItemInstance
) -> InteractionResultScript:
	return InteractionResultScript.new(success, reason, action, events, hand_item)
