extends RefCounted

class_name DeskRejectOutcomeSystem

const EventSchema := preload("res://scripts/domain/events/event_schema.gd")
const StorageStateScript := preload("res://scripts/domain/storage/wardrobe_storage_state.gd")
const DeskRejectConsequencePolicyScript := preload("res://scripts/app/desk/reject_consequence_policy.gd")
const FloorResolverScript := preload("res://scripts/app/wardrobe/floor_resolver.gd")
const ClientStateScript := preload("res://scripts/domain/clients/client_state.gd")

var _policy = DeskRejectConsequencePolicyScript.new()
var _storage_state: WardrobeStorageState
var _clients: Dictionary = {}
var _floor_resolver
var _apply_patience_penalty: Callable

func configure(
	storage_state: WardrobeStorageState,
	clients: Dictionary,
	floor_resolver,
	apply_patience_penalty: Callable
) -> void:
	_storage_state = storage_state
	_clients = clients
	_floor_resolver = floor_resolver
	_apply_patience_penalty = apply_patience_penalty

func process_desk_events(events: Array) -> Array:
	if events.is_empty():
		return []
	var extra_events: Array = []
	for event_data in events:
		var event_type: StringName = event_data.get(EventSchema.EVENT_KEY_TYPE, StringName())
		if event_type != EventSchema.EVENT_DESK_REJECTED_DELIVERY:
			continue
		var payload: Dictionary = event_data.get(EventSchema.EVENT_KEY_PAYLOAD, {})
		extra_events.append_array(_handle_reject(payload))
	return extra_events

func _handle_reject(payload: Dictionary) -> Array:
	if _storage_state == null:
		return []
	var reason_code: StringName = StringName(str(payload.get(EventSchema.PAYLOAD_REASON_CODE, "")))
	var client_phase: StringName = StringName(str(payload.get(EventSchema.PAYLOAD_CLIENT_PHASE, "")))
	var desk_slot_id: StringName = StringName(str(payload.get(EventSchema.PAYLOAD_DESK_SLOT_ID, "")))
	var client_id: StringName = StringName(str(payload.get(EventSchema.PAYLOAD_CLIENT_ID, "")))
	var item_instance_id: StringName = StringName(str(payload.get(EventSchema.PAYLOAD_ITEM_INSTANCE_ID, "")))
	var policy_result: Dictionary = _policy.evaluate(reason_code, client_phase)
	if policy_result.is_empty():
		return []
	var drop_to_floor: bool = bool(policy_result.get("drop_to_floor", false))
	var apply_penalty: bool = bool(policy_result.get("apply_patience_penalty", false))
	var penalty_reason: StringName = policy_result.get("penalty_reason", StringName())

	var slot_item := _storage_state.get_slot_item(desk_slot_id)
	if slot_item == null or slot_item.id != item_instance_id:
		return []
	var pop_result := _storage_state.pop_slot_item(desk_slot_id)
	if not pop_result.success:
		return []
	var events: Array = []
	if apply_penalty:
		var penalty_value := _resolve_penalty_for_client(client_id)
		if penalty_value > 0.0 and _apply_patience_penalty.is_valid():
			_apply_patience_penalty.call(client_id, penalty_value, penalty_reason)
	if drop_to_floor:
		var floor_id := _resolve_floor_id(desk_slot_id)
		if floor_id != StringName():
			events.append(_make_event(EventSchema.EVENT_ITEM_DROPPED, {
				EventSchema.PAYLOAD_ITEM_INSTANCE_ID: item_instance_id,
				EventSchema.PAYLOAD_FROM: desk_slot_id,
				EventSchema.PAYLOAD_TO: floor_id,
				EventSchema.PAYLOAD_CAUSE: EventSchema.REASON_WRONG_ITEM,
				EventSchema.PAYLOAD_CLIENT_ID: client_id,
			}))
	return events

func _resolve_penalty_for_client(client_id: StringName) -> float:
	if client_id == StringName():
		return 0.0
	var client: ClientState = _clients.get(client_id, null) as ClientState
	if client == null:
		return 0.0
	return client.get_wrong_item_patience_penalty()

func _resolve_floor_id(desk_slot_id: StringName) -> StringName:
	if _floor_resolver == null:
		return StringName()
	return _floor_resolver.resolve_floor_for_desk(desk_slot_id)

func _make_event(event_type: StringName, payload: Dictionary) -> Dictionary:
	return {
		EventSchema.EVENT_KEY_TYPE: event_type,
		EventSchema.EVENT_KEY_PAYLOAD: payload.duplicate(true),
	}
