extends RefCounted
class_name WardrobeDragDropAdapter

const WardrobeInteractionCommandScript := preload("res://scripts/app/interaction/interaction_command.gd")
const PickPutSwapResolverScript := preload("res://scripts/app/interaction/pick_put_swap_resolver.gd")
const WardrobeInteractionEventAdapterScript := preload("res://scripts/wardrobe/interaction_event_adapter.gd")
const WardrobeInteractionEventsAdapterScript := preload("res://scripts/ui/wardrobe_interaction_events.gd")
const DeskEventDispatcherScript := preload("res://scripts/ui/desk_event_dispatcher.gd")
const ItemInstanceScript := preload("res://scripts/domain/storage/item_instance.gd")

const HOVER_DISTANCE_SQ := 64.0 * 64.0
const HOVER_TIE_EPSILON := 0.001
const HOVER_COLOR := Color(1.0, 0.92, 0.55, 1.0)

var _interaction_service: WardrobeInteractionService
var _storage_state: WardrobeStorageState
var _slots: Array[WardrobeSlot] = []
var _slot_lookup: Dictionary = {}
var _slots_array: Array[WardrobeSlot] = []
var _item_nodes: Dictionary = {}
var _spawned_items: Array = []
var _event_adapter: WardrobeInteractionEventAdapter
var _interaction_events: WardrobeInteractionEventsAdapter
var _desk_event_dispatcher: DeskEventDispatcher
var _item_visuals: WardrobeItemVisualsAdapter
var _interaction_logger
var _find_item_instance: Callable
var _desk_by_slot_id: Dictionary = {}
var _cursor_hand: CursorHand
var _validate_world: Callable
var _last_interaction_command: Dictionary = {}
var _event_connected := false
var _drag_active := false
var _hover_slot: WardrobeSlot
var _hover_slot_original_modulate := Color.WHITE

func configure(context: RefCounted, cursor_hand: CursorHand, validate_world: Callable = Callable()) -> void:
	var typed := context
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
	_desk_by_slot_id = typed.desk_by_slot_id
	_cursor_hand = cursor_hand
	_validate_world = validate_world
	_cache_slots()
	_setup_item_visuals(typed.item_scene)
	_setup_interaction_events(typed.desk_by_id)
	_setup_desk_dispatcher(
		typed.desk_states,
		typed.desk_by_slot_id,
		typed.desk_system,
		typed.client_queue_state,
		typed.clients
	)
	_connect_event_adapter()

func on_pointer_down(cursor_pos: Vector2) -> void:
	_drag_active = true
	_update_hover(cursor_pos)
	if _cursor_hand == null:
		return
	if _cursor_hand.get_active_hand_item() == null and _hover_slot and _hover_slot.has_item():
		_perform_slot_interaction(_hover_slot)

func on_pointer_move(cursor_pos: Vector2) -> void:
	_update_hover(cursor_pos)

func on_pointer_up(cursor_pos: Vector2) -> void:
	if not _drag_active:
		return
	_update_hover(cursor_pos)
	if _cursor_hand and _cursor_hand.get_active_hand_item() != null and _hover_slot:
		_perform_slot_interaction(_hover_slot)
	_drag_active = false

func update_drag_watchdog() -> void:
	if not _drag_active:
		return
	if not Input.is_mouse_button_pressed(MouseButton.MOUSE_BUTTON_LEFT):
		cancel_drag()

func cancel_drag() -> void:
	_drag_active = false
	_set_hover_slot(null)
	if _cursor_hand:
		_cursor_hand.set_preview_small(false)

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

func _perform_slot_interaction(slot: WardrobeSlot) -> void:
	var command := build_interaction_command(slot)
	var exec_result: InteractionResult = execute_interaction(command)
	apply_interaction_events(exec_result.events)
	log_interaction(exec_result, slot)
	_debug_validate_world()

func log_interaction(result: InteractionResult, slot: WardrobeSlot) -> void:
	var action: String = result.action
	if result.success:
		_last_interaction_command[WardrobeInteractionCommandScript.KEY_TYPE] = _resolve_command_type(action)
		var slot_label := slot.get_slot_identifier()
		var held := _cursor_hand.get_active_hand_item() if _cursor_hand else null
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
		PickPutSwapResolverScript.ACTION_SWAP:
			return WardrobeInteractionCommandScript.TYPE_SWAP
		_:
			return WardrobeInteractionCommandScript.TYPE_AUTO

func _update_hover(cursor_pos: Vector2) -> void:
	var best_slot: WardrobeSlot = null
	var best_d2 := INF
	var best_id := ""
	for slot in _slots_array:
		var d2 := cursor_pos.distance_squared_to(slot.global_position)
		if d2 < best_d2 - HOVER_TIE_EPSILON:
			best_slot = slot
			best_d2 = d2
			best_id = slot.get_slot_identifier()
			continue
		if abs(d2 - best_d2) <= HOVER_TIE_EPSILON:
			var slot_id := slot.get_slot_identifier()
			if String(slot_id) < String(best_id):
				best_slot = slot
				best_d2 = d2
				best_id = slot_id
	if best_slot != null and best_d2 > HOVER_DISTANCE_SQ:
		best_slot = null
	_set_hover_slot(best_slot)
	_update_preview()

func _set_hover_slot(slot: WardrobeSlot) -> void:
	if _hover_slot == slot:
		return
	_apply_hover(false)
	_hover_slot = slot
	_apply_hover(true)

func _apply_hover(enabled: bool) -> void:
	if _hover_slot == null:
		return
	var sprite := _get_slot_sprite(_hover_slot)
	if sprite == null:
		return
	if enabled:
		_hover_slot_original_modulate = sprite.modulate
		sprite.modulate = HOVER_COLOR
	else:
		sprite.modulate = _hover_slot_original_modulate

func _get_slot_sprite(slot: WardrobeSlot) -> Sprite2D:
	return slot.get_node_or_null("SlotSprite") as Sprite2D

func _update_preview() -> void:
	if _cursor_hand == null:
		return
	if _hover_slot == null:
		_cursor_hand.set_preview_small(false)
		return
	var slot_id := StringName(_hover_slot.get_slot_identifier())
	var is_storage := not _desk_by_slot_id.has(slot_id)
	_cursor_hand.set_preview_small(is_storage)

func _cache_slots() -> void:
	_slots_array.clear()
	for slot in _slot_lookup.values():
		if slot is WardrobeSlot:
			_slots_array.append(slot)

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
	clients: Dictionary
) -> void:
	if _desk_event_dispatcher == null:
		return
	_desk_event_dispatcher.configure(
		desk_states,
		desk_by_slot_id,
		desk_system,
		client_queue_state,
		clients,
		_storage_state
	)

func _connect_event_adapter() -> void:
	if _event_adapter == null or _event_connected:
		return
	_event_adapter.item_picked.connect(_on_event_item_picked)
	_event_adapter.item_placed.connect(_on_event_item_placed)
	_event_adapter.item_swapped.connect(_on_event_item_swapped)
	_event_adapter.action_rejected.connect(_on_event_action_rejected)
	_event_connected = true

func _detach_item_node(node: ItemNode) -> void:
	if node == null:
		return
	if _cursor_hand and _cursor_hand.get_active_hand_item() == node:
		_cursor_hand.take_item_from_hand()
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
	if node and _cursor_hand:
		_cursor_hand.hold_item(node)
	_interaction_service.set_hand_item(_instance_from_snapshot(item))

func _on_event_item_placed(slot_id: StringName, item: Dictionary, _tick: int) -> void:
	var slot: WardrobeSlot = _slot_lookup.get(slot_id, null)
	var node: ItemNode = _cursor_hand.take_item_from_hand() if _cursor_hand else null
	var item_id: StringName = item.get("id", StringName())
	if node == null:
		node = _item_nodes.get(item_id, null)
	if slot and node:
		slot.put_item(node)
	_interaction_service.clear_hand_item()

func _on_event_item_swapped(
	slot_id: StringName,
	_incoming_item: Dictionary,
	outgoing_item: Dictionary,
	_tick: int
) -> void:
	var slot: WardrobeSlot = _slot_lookup.get(slot_id, null)
	var slot_outgoing: ItemNode = slot.take_item() if slot else null
	var incoming_node: ItemNode = _cursor_hand.take_item_from_hand() if _cursor_hand else null
	if slot and incoming_node:
		slot.put_item(incoming_node)
	if slot_outgoing and _cursor_hand:
		_cursor_hand.hold_item(slot_outgoing)
	_interaction_service.set_hand_item(_instance_from_snapshot(outgoing_item))

func _on_event_action_rejected(_slot_id: StringName, _reason: StringName, _tick: int) -> void:
	pass

func _debug_validate_world() -> void:
	if _validate_world.is_valid():
		_validate_world.call()
