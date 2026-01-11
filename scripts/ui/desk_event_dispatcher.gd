extends RefCounted

class_name DeskEventDispatcher

const DeskServicePointSystemScript := preload("res://scripts/app/desk/desk_service_point_system.gd")
const DeskRejectOutcomeSystemScript := preload("res://scripts/app/desk/desk_reject_outcome_system.gd")
const FloorResolverScript := preload("res://scripts/app/wardrobe/floor_resolver.gd")
const EventSchema := preload("res://scripts/domain/events/event_schema.gd")
const ClientQueueStateScript := preload("res://scripts/domain/clients/client_queue_state.gd")
const WardrobeStorageStateScript := preload("res://scripts/domain/storage/wardrobe_storage_state.gd")

var _desk_states: Array = []
var _desk_by_slot_id: Dictionary = {}
var _desk_system: DeskServicePointSystem
var _client_queue_state: ClientQueueState
var _clients: Dictionary = {}
var _storage_state: WardrobeStorageState
var _reject_outcome_system = DeskRejectOutcomeSystemScript.new()
var _floor_resolver
var _apply_patience_penalty: Callable

func configure(
	desk_states: Array,
	desk_by_slot_id: Dictionary,
	desk_system: DeskServicePointSystem,
	client_queue_state: ClientQueueState,
	clients: Dictionary,
	storage_state: WardrobeStorageState,
	floor_resolver,
	apply_patience_penalty: Callable
) -> void:
	_desk_states = desk_states
	_desk_by_slot_id = desk_by_slot_id
	_desk_system = desk_system
	_client_queue_state = client_queue_state
	_clients = clients
	_storage_state = storage_state
	_floor_resolver = floor_resolver
	_apply_patience_penalty = apply_patience_penalty
	if _reject_outcome_system != null:
		_reject_outcome_system.configure(_storage_state, _clients, _floor_resolver, _apply_patience_penalty)

func process_interaction_events(events: Array) -> Array:
	if _desk_states.is_empty():
		return []
	var collected: Array = []
	for event_data in events:
		var payload: Dictionary = event_data.get(EventSchema.EVENT_KEY_PAYLOAD, {})
		var slot_id: StringName = StringName(str(payload.get(EventSchema.PAYLOAD_SLOT_ID, "")))
		if slot_id == StringName():
			continue
		var desk_state: RefCounted = _desk_by_slot_id.get(slot_id, null)
		if desk_state == null:
			continue
		var desk_events: Array = _desk_system.process_interaction_event(
			desk_state,
			_client_queue_state,
			_clients,
			_storage_state,
			event_data
		)
		if not desk_events.is_empty():
			collected.append_array(desk_events)
	if _reject_outcome_system != null:
		var outcome_events: Array = _reject_outcome_system.process_desk_events(collected)
		if not outcome_events.is_empty():
			collected.append_array(outcome_events)
	return collected
