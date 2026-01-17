extends RefCounted

class_name DeskEventDispatcher

const DeskServicePointSystemScript := preload("res://scripts/app/desk/desk_service_point_system.gd")
const DeskRejectOutcomeSystemScript := preload("res://scripts/app/desk/desk_reject_outcome_system.gd")
const ClientQueueStateScript := preload("res://scripts/domain/clients/client_queue_state.gd")
const WardrobeStorageStateScript := preload("res://scripts/domain/storage/wardrobe_storage_state.gd")

var _desk_by_id: Dictionary = {}
var _desk_system: DeskServicePointSystem
var _client_queue_state: ClientQueueState
var _clients: Dictionary = {}
var _storage_state: WardrobeStorageState
var _reject_outcome_system = DeskRejectOutcomeSystemScript.new()
var _apply_patience_penalty: Callable

func configure(
	desk_by_id: Dictionary,
	desk_system: DeskServicePointSystem,
	client_queue_state: ClientQueueState,
	clients: Dictionary,
	storage_state: WardrobeStorageState,
	apply_patience_penalty: Callable
) -> void:
	_desk_by_id = desk_by_id
	_desk_system = desk_system
	_client_queue_state = client_queue_state
	_clients = clients
	_storage_state = storage_state
	_apply_patience_penalty = apply_patience_penalty
	if _reject_outcome_system != null:
		_reject_outcome_system.configure(_apply_patience_penalty)

func process_interaction_events(_events: Array) -> Array:
	return []

func process_deliver_attempt(service_point_id: StringName, item_instance: ItemInstance) -> Array:
	if service_point_id == StringName():
		return []
	if item_instance == null:
		return []
	var desk_state: RefCounted = _desk_by_id.get(service_point_id, null)
	if desk_state == null:
		return []
	var desk_events: Array = _desk_system.process_deliver_attempt(
		desk_state,
		_client_queue_state,
		_clients,
		_storage_state,
		item_instance
	)
	if _reject_outcome_system != null:
		_reject_outcome_system.process_desk_events(desk_events)
	return desk_events

func assign_next_client(service_point_id: StringName) -> Array:
	if service_point_id == StringName():
		return []
	var desk_state: RefCounted = _desk_by_id.get(service_point_id, null)
	if desk_state == null:
		return []
	return _desk_system.assign_next_client_to_desk(
		desk_state,
		_client_queue_state,
		_clients,
		_storage_state
	)
