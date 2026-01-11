extends RefCounted
class_name WardrobeInteractionAdapter

const WardrobeInteractionCommandScript := preload("res://scripts/app/interaction/interaction_command.gd")
const PickPutSwapResolverScript := preload("res://scripts/app/interaction/pick_put_swap_resolver.gd")
const WardrobeInteractionEventAdapterScript := preload("res://scripts/wardrobe/interaction_event_adapter.gd")
const WardrobeInteractionEventsAdapterScript := preload("res://scripts/ui/wardrobe_interaction_events.gd")
const DeskEventDispatcherScript := preload("res://scripts/ui/desk_event_dispatcher.gd")
const ItemInstanceScript := preload("res://scripts/domain/storage/item_instance.gd")
const DebugLog := preload("res://scripts/wardrobe/debug/debug_log.gd")
const FloorResolverScript := preload("res://scripts/app/wardrobe/floor_resolver.gd")

const DISTANCE_TIE_THRESHOLD := 6.0

var _player: WardrobePlayerController
var _interaction_service: WardrobeInteractionService
var _storage_state: WardrobeStorageState
var _slots: Array[WardrobeSlot] = []
var _slot_lookup: Dictionary = {}
var _item_nodes: Dictionary = {}
var _spawned_items: Array = []
var _event_adapter: WardrobeInteractionEventAdapter
var _interaction_events: WardrobeInteractionEventsAdapter
var _desk_event_dispatcher: DeskEventDispatcher
var _item_visuals: WardrobeItemVisualsAdapter
var _interaction_logger
var _last_interaction_command: Dictionary = {}
var _event_connected := false
var _find_item_instance: Callable

func configure(context: RefCounted) -> void:
	var typed := context
	_player = typed.player
	_interaction_service = typed.interaction_service
	_storage_state = typed.storage_state
	_slots = typed.slots
	_slot_lookup = typed.slot_lookup
	_item_nodes = typed.item_nodes
	_spawned_items = typed.spawned_items
	_item_visuals = typed.item_visuals
	_event_adapter = typed.event_adapter
	_interaction_events = typed.interaction_events
	_desk_event_dispatcher = typed.desk_event_dispatcher
	_find_item_instance = typed.find_item_instance
	_interaction_logger = typed.interaction_logger
	_setup_item_visuals(typed.item_scene)
	_setup_interaction_events(typed.desk_by_id)
	_setup_desk_dispatcher(
		typed.desk_states,
		typed.desk_by_slot_id,
		typed.desk_system,
		typed.client_queue_state,
		typed.clients,
		typed.floor_resolver,
		typed.apply_patience_penalty
	)
	_connect_event_adapter()

func perform_interact() -> void:
	if _player == null:
		return
	var slot := _find_best_slot()
	if slot == null:
		print("NO ACTION reason=no_slot slot=none")
		return
	var command := build_interaction_command(slot)
	var exec_result: InteractionResult = execute_interaction(command)
	apply_interaction_events(exec_result.events)
	log_interaction(exec_result, slot)

func build_interaction_command(slot: WardrobeSlot) -> Dictionary:
	var slot_id := StringName(slot.get_slot_identifier())
	var slot_item_instance := _storage_state.get_slot_item(slot_id)
	var command: Dictionary = _interaction_service.build_auto_command(slot_id, slot_item_instance)
	_last_interaction_command = command
	return command

func execute_interaction(command: Dictionary) -> InteractionResult:
	return _interaction_service.execute_command(command)

func apply_interaction_events(events: Array) -> void:
	_event_adapter.emit_events(events)
	var desk_events: Array = _desk_event_dispatcher.process_interaction_events(events)
	_interaction_events.apply_desk_events(desk_events)

func log_interaction(result: InteractionResult, slot: WardrobeSlot) -> void:
	var action: String = result.action
	if result.success:
		_last_interaction_command[WardrobeInteractionCommandScript.KEY_TYPE] = _resolve_command_type(action)
		var slot_label := slot.get_slot_identifier()
		var held := _player.get_active_hand_item()
		var item_name := held.item_id if held else (slot.get_item().item_id if slot.get_item() else "none")
		if _interaction_logger:
			_interaction_logger.record_success(action, StringName(slot_label), item_name, _last_interaction_command)
		else:
			print("%s item=%s slot=%s" % [action, item_name, slot_label])
	else:
		var slot_id := StringName(slot.get_slot_identifier())
		if _interaction_logger:
			_interaction_logger.record_reject(result.reason, slot_id, _last_interaction_command)
		else:
			print("NO ACTION reason=%s slot=%s" % [result.reason, slot_id])

func _resolve_command_type(action: String) -> StringName:
	match action:
		PickPutSwapResolverScript.ACTION_PICK:
			return WardrobeInteractionCommandScript.TYPE_PICK
		PickPutSwapResolverScript.ACTION_PUT:
			return WardrobeInteractionCommandScript.TYPE_PUT
		_:
			return WardrobeInteractionCommandScript.TYPE_AUTO

func _find_best_slot() -> WardrobeSlot:
	if _player == null:
		return null
	var radius := _player.get_interact_radius()
	if radius <= 0.0:
		return null
	var origin := _player.global_position
	var move_dir := _player.get_last_move_dir()
	var best_slot: WardrobeSlot = null
	var best_distance := INF
	var best_dot := -INF
	var best_name := ""
	for slot in _slots:
		var distance := origin.distance_to(slot.global_position)
		var direction := (slot.global_position - origin).normalized()
		var slot_dot := direction.dot(move_dir)
		var slot_name := str(slot.name)
		if distance > radius:
			continue
		if best_slot == null or distance < best_distance - 0.001:
			best_slot = slot
			best_distance = distance
			best_dot = slot_dot
			best_name = slot_name
			continue
		if abs(distance - best_distance) <= DISTANCE_TIE_THRESHOLD:
			if slot_dot > best_dot + 0.001 or (is_equal_approx(slot_dot, best_dot) and slot_name < best_name):
				best_slot = slot
				best_distance = distance
				best_dot = slot_dot
				best_name = slot_name
	return best_slot

func _setup_item_visuals(item_scene: PackedScene) -> void:
	if _item_visuals == null:
		return
	_item_visuals.configure(
		item_scene,
		_slot_lookup,
		_item_nodes,
		_spawned_items,
		Callable(self, "_detach_item_node")
	)

func _setup_interaction_events(desk_by_id: Dictionary) -> void:
	if _interaction_events == null:
		return
	_interaction_events.configure(
		desk_by_id,
		_item_nodes,
		Callable(self, "_detach_item_node"),
		Callable(_item_visuals, "spawn_or_move_item_node"),
		_find_item_instance
	)

func _setup_desk_dispatcher(
	desk_states: Array,
	desk_by_slot_id: Dictionary,
	desk_system: DeskServicePointSystem,
	client_queue_state: ClientQueueState,
	clients: Dictionary,
	floor_resolver,
	apply_patience_penalty: Callable
) -> void:
	if _desk_event_dispatcher == null:
		return
	_desk_event_dispatcher.configure(
		desk_states,
		desk_by_slot_id,
		desk_system,
		client_queue_state,
		clients,
		_storage_state,
		floor_resolver,
		apply_patience_penalty
	)

func _connect_event_adapter() -> void:
	if _event_adapter == null or _event_connected:
		return
	_event_adapter.item_picked.connect(_on_event_item_picked)
	_event_adapter.item_placed.connect(_on_event_item_placed)
	_event_adapter.action_rejected.connect(_on_event_action_rejected)
	_event_connected = true

func _detach_item_node(node: ItemNode) -> void:
	if node == null:
		return
	if _player and _player.get_active_hand_item() == node:
		_player.take_item_from_hand()
	for slot in _slots:
		if slot.get_item() == node:
			var _unused := slot.take_item()
			break

func _instance_from_snapshot(snapshot: Dictionary) -> ItemInstance:
	var id: StringName = snapshot.get("id", StringName())
	var kind: StringName = snapshot.get("kind", ItemInstanceScript.KIND_COAT)
	var color_variant: Variant = snapshot.get("color", Color.WHITE)
	var color := _item_visuals.parse_color(color_variant)
	return ItemInstanceScript.new(id, kind, color)

func _on_event_item_picked(slot_id: StringName, item: Dictionary, _tick: int) -> void:
	var slot: WardrobeSlot = _slot_lookup.get(slot_id, null)
	var node: ItemNode = slot.take_item() if slot else null
	var item_id: StringName = item.get("id", StringName())
	if node == null:
		node = _item_nodes.get(item_id, null)
	if node and _player:
		_player.hold_item(node)
	_interaction_service.set_hand_item(_instance_from_snapshot(item))

func _on_event_item_placed(slot_id: StringName, item: Dictionary, _tick: int) -> void:
	var slot: WardrobeSlot = _slot_lookup.get(slot_id, null)
	var hand_before := _player.get_active_hand_item() if _player else null
	var node: ItemNode = _player.take_item_from_hand() if _player else null
	var item_id: StringName = item.get("id", StringName())
	if node == null:
		node = _item_nodes.get(item_id, null)
	if slot and node:
		slot.put_item(node)
	_interaction_service.clear_hand_item()
	if not slot or node == null:
		_log_put_missing("placed", slot_id, item_id, slot, hand_before, node)

func _on_event_action_rejected(_slot_id: StringName, _reason: StringName, _tick: int) -> void:
	pass

func _log_put_missing(
	context: String,
	slot_id: StringName,
	item_id: StringName,
	slot: WardrobeSlot,
	hand_before: ItemNode,
	node: ItemNode
) -> void:
	if not DebugLog.enabled():
		return
	var reasons: Array[String] = []
	if slot == null:
		reasons.append("missing_slot")
	if node == null:
		reasons.append("missing_node")
	var hand_id := hand_before.item_id if hand_before else "none"
	var node_id := node.item_id if node else "none"
	var slot_has_item := slot.has_item() if slot else false
	DebugLog.logf("PutMissing ctx=%s slot=%s item=%s reasons=%s hand_before=%s node=%s slot_has_item=%s", [
		context,
		String(slot_id),
		String(item_id),
		"|".join(reasons),
		hand_id,
		node_id,
		str(slot_has_item),
	])
