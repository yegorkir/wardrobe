extends Node2D

const ITEM_SCENE := preload("res://scenes/prefabs/item_node.tscn")
const WardrobeInteractionCommandScript := preload("res://scripts/app/interaction/interaction_command.gd")
const WardrobeInteractionServiceScript := preload("res://scripts/app/interaction/interaction_service.gd")
const InteractionEventSchema := preload("res://scripts/domain/events/event_schema.gd")
const InteractionResult := preload("res://scripts/domain/interaction/interaction_result.gd")
const PickPutSwapResolverScript := preload("res://scripts/app/interaction/pick_put_swap_resolver.gd")
const WardrobeInteractionEventAdapterScript := preload("res://scripts/wardrobe/interaction_event_adapter.gd")
const WardrobeStep3SetupAdapterScript := preload("res://scripts/ui/wardrobe_step3_setup.gd")
const WardrobeStep3SetupContextScript := preload("res://scripts/ui/wardrobe_step3_setup_context.gd")
const WardrobeInteractionEventsAdapterScript := preload("res://scripts/ui/wardrobe_interaction_events.gd")
const DeskEventDispatcherScript := preload("res://scripts/ui/desk_event_dispatcher.gd")
const WardrobeItemVisualsAdapterScript := preload("res://scripts/ui/wardrobe_item_visuals.gd")
const WardrobeWorldValidatorScript := preload("res://scripts/ui/wardrobe_world_validator.gd")
const WardrobeStorageStateScript := preload("res://scripts/domain/storage/wardrobe_storage_state.gd")
const ItemInstanceScript := preload("res://scripts/domain/storage/item_instance.gd")
const DeskServicePointSystemScript := preload("res://scripts/app/desk/desk_service_point_system.gd")
const ClientQueueStateScript := preload("res://scripts/domain/clients/client_queue_state.gd")
const ClientQueueSystemScript := preload("res://scripts/app/queue/client_queue_system.gd")
const DeskServicePointScript := preload("res://scripts/wardrobe/desk_service_point.gd")

@export var step3_seed: int = 1337

@onready var _wave_label: Label = %WaveValue
@onready var _time_label: Label = %TimeValue
@onready var _money_label: Label = %MoneyValue
@onready var _magic_label: Label = %MagicValue
@onready var _debt_label: Label = %DebtValue
@onready var _end_shift_button: Button = %EndShiftButton
@onready var _run_manager: RunManagerBase = get_node_or_null("/root/RunManager") as RunManagerBase
@onready var _player: WardrobePlayerController = %Player

var _hud_connected := false
var _interaction_service := WardrobeInteractionServiceScript.new()
var _storage_state: WardrobeStorageState = _interaction_service.get_storage_state()
var _slots: Array[WardrobeSlot] = []
var _slot_lookup: Dictionary = {}
var _spawned_items: Array[ItemNode] = []
var _item_nodes: Dictionary = {}
var _event_adapter: WardrobeInteractionEventAdapter = WardrobeInteractionEventAdapterScript.new()
var _step3_setup: WardrobeStep3SetupAdapter = WardrobeStep3SetupAdapterScript.new()
var _interaction_events: WardrobeInteractionEventsAdapter = WardrobeInteractionEventsAdapterScript.new()
var _desk_event_dispatcher := DeskEventDispatcherScript.new()
var _item_visuals: WardrobeItemVisualsAdapter = WardrobeItemVisualsAdapterScript.new()
var _world_validator := WardrobeWorldValidatorScript.new()
var _desk_system: DeskServicePointSystem = DeskServicePointSystemScript.new()
var _desk_nodes: Array = []
var _desk_states: Array = []
var _desk_by_id: Dictionary = {}
var _desk_by_slot_id: Dictionary = {}
var _clients: Dictionary = {}
var _client_queue_state: ClientQueueState = ClientQueueStateScript.new()
var _queue_system: ClientQueueSystem = ClientQueueSystemScript.new()
var _last_interaction_command: Dictionary = {}

const DISTANCE_TIE_THRESHOLD := 6.0

func _ready() -> void:
	_setup_hud()
	if _player == null:
		push_warning("Player node missing; Step 2 sandbox disabled.")
		return
	call_deferred("_finish_ready_setup")

func _finish_ready_setup() -> void:
	_collect_slots()
	_collect_desks()
	if _slots.is_empty():
		await get_tree().process_frame
		_collect_slots()
		_collect_desks()
	_reset_storage_state()
	_connect_event_adapter()
	_setup_adapters()
	_step3_setup.initialize_step3()
	_end_shift_button.pressed.connect(_on_end_shift_pressed)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		_perform_interact()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("debug_reset"):
		_reset_world()
		get_viewport().set_input_as_handled()

func _process(_delta: float) -> void:
	pass

func _exit_tree() -> void:
	if _hud_connected and _run_manager:
		_run_manager.hud_updated.disconnect(_on_hud_updated)
		_hud_connected = false

func _setup_hud() -> void:
	if _run_manager:
		_run_manager.hud_updated.connect(_on_hud_updated)
		_hud_connected = true
		_on_hud_updated(_run_manager.get_hud_snapshot())
	else:
		push_warning("RunManager singleton not found; HUD will not update.")

func _collect_slots() -> void:
	_slots.clear()
	_slot_lookup.clear()
	for node in get_tree().get_nodes_in_group(WardrobeSlot.SLOT_GROUP):
		if node is WardrobeSlot:
			var slot := node as WardrobeSlot
			_slots.append(slot)
			var slot_id := StringName(slot.get_slot_identifier())
			_slot_lookup[slot_id] = slot
	if _slots.is_empty():
		for node in find_children("*", "WardrobeSlot", true, true):
			if node is WardrobeSlot:
				var slot := node as WardrobeSlot
				_slots.append(slot)
				var slot_id := StringName(slot.get_slot_identifier())
				_slot_lookup[slot_id] = slot

func _collect_desks() -> void:
	_desk_nodes.clear()
	for node in get_tree().get_nodes_in_group(DeskServicePointScript.DESK_GROUP):
		if node is Node2D and node.has_method("get_slot_id"):
			_desk_nodes.append(node)

func _reset_storage_state() -> void:
	_interaction_service.reset_state()
	_register_storage_slots()

func _register_storage_slots() -> void:
	for slot in _slots:
		_interaction_service.register_slot(StringName(slot.get_slot_identifier()))

func _get_ticket_slots() -> Array[WardrobeSlot]:
	var ticket_slots: Array[WardrobeSlot] = []
	for slot in _slots:
		var slot_id := slot.get_slot_identifier()
		if slot_id.ends_with("_SlotA"):
			ticket_slots.append(slot)
	return ticket_slots

func _place_item_instance_in_slot(slot_id: StringName, instance: ItemInstance) -> void:
	if instance == null:
		return
	if not _storage_state.has_slot(slot_id):
		_interaction_service.register_slot(slot_id)
	if _storage_state.get_slot_item(slot_id) != null:
		return
	var put_result := _storage_state.put(slot_id, instance)
	if not put_result.get(WardrobeStorageStateScript.RESULT_KEY_SUCCESS, false):
		push_warning("Step 3 failed to place item %s in slot %s: %s" % [
			instance.id,
			slot_id,
			put_result.get(WardrobeStorageStateScript.RESULT_KEY_REASON, "unknown"),
		])
		return
	_item_visuals.spawn_or_move_item_node(slot_id, instance)

func _connect_event_adapter() -> void:
	if _event_adapter == null:
		_event_adapter = WardrobeInteractionEventAdapterScript.new()
	_event_adapter.item_picked.connect(_on_event_item_picked)
	_event_adapter.item_placed.connect(_on_event_item_placed)
	_event_adapter.item_swapped.connect(_on_event_item_swapped)
	_event_adapter.action_rejected.connect(_on_event_action_rejected)

func _setup_adapters() -> void:
	if _item_visuals == null:
		_item_visuals = WardrobeItemVisualsAdapterScript.new()
	_item_visuals.configure(
		ITEM_SCENE,
		_slot_lookup,
		_item_nodes,
		_spawned_items,
		Callable(self, "_detach_item_node")
	)
	if _interaction_events == null:
		_interaction_events = WardrobeInteractionEventsAdapterScript.new()
	_interaction_events.configure(
		_desk_by_id,
		_item_nodes,
		Callable(self, "_detach_item_node"),
		Callable(_item_visuals, "spawn_or_move_item_node"),
		Callable(self, "_find_item_instance")
	)
	if _desk_event_dispatcher == null:
		_desk_event_dispatcher = DeskEventDispatcherScript.new()
	_desk_event_dispatcher.configure(
		_desk_states,
		_desk_by_slot_id,
		_desk_system,
		_client_queue_state,
		_clients,
		_storage_state
	)
	if _step3_setup == null:
		_step3_setup = WardrobeStep3SetupAdapterScript.new()
	var step3_context := WardrobeStep3SetupContextScript.new()
	step3_context.root = self
	step3_context.clear_spawned_items = Callable(self, "_clear_spawned_items")
	step3_context.collect_desks = Callable(self, "_collect_desks")
	step3_context.desk_nodes = _desk_nodes
	step3_context.desk_states = _desk_states
	step3_context.desk_by_id = _desk_by_id
	step3_context.desk_by_slot_id = _desk_by_slot_id
	step3_context.clients = _clients
	step3_context.client_queue_state = _client_queue_state
	step3_context.desk_system = _desk_system
	step3_context.queue_system = _queue_system
	step3_context.storage_state = _storage_state
	step3_context.get_ticket_slots = Callable(self, "_get_ticket_slots")
	step3_context.place_item_instance_in_slot = Callable(self, "_place_item_instance_in_slot")
	step3_context.apply_desk_events = Callable(_interaction_events, "apply_desk_events")
	_step3_setup.configure(step3_context)

func _clear_spawned_items() -> void:
	for slot in _slots:
		slot.clear_item(false)
	for item in _spawned_items:
		if is_instance_valid(item):
			item.queue_free()
	_spawned_items.clear()
	_item_nodes.clear()
	_interaction_service.reset_state()
	_register_storage_slots()
func _reset_world() -> void:
	_step3_setup.initialize_step3()

func _perform_interact() -> void:
	if _player == null:
		return
	var slot := _find_best_slot()
	if slot == null:
		print("NO ACTION reason=no_slot slot=none")
		_debug_validate_world()
		return
	var command := build_interaction_command(slot)
	var exec_result: InteractionResult = execute_interaction(command)
	var events: Array = exec_result.events
	apply_interaction_events(events)
	log_interaction(exec_result, slot)
	_debug_validate_world()

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
		print("%s item=%s slot=%s" % [action, item_name, slot_label])
		_record_interaction_event(_last_interaction_command, true, StringName(slot_label))
	else:
		print(
			"NO ACTION reason=%s slot=%s" % [
				result.reason,
				slot.get_slot_identifier(),
			]
		)
		_record_interaction_event(
			_last_interaction_command,
			false,
			StringName(slot.get_slot_identifier())
		)

func _record_interaction_event(_command: Dictionary, _success: bool, _slot_id: StringName) -> void:
	pass

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
		var score := score_slot(slot, origin, move_dir)
		var distance: float = score.get("distance", INF)
		var slot_name: String = score.get("name", "")
		if distance > radius:
			continue
		var slot_dot: float = score.get("dot", -INF)
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

func score_slot(slot: WardrobeSlot, origin: Vector2, move_dir: Vector2) -> Dictionary:
	var distance := origin.distance_to(slot.global_position)
	var direction := (slot.global_position - origin).normalized()
	var slot_dot := direction.dot(move_dir)
	return {
		"distance": distance,
		"dot": slot_dot,
		"name": str(slot.name),
	}

func _debug_validate_world() -> void:
	if not OS.is_debug_build():
		return
	_world_validator.validate(_slots, _player)

func _on_hud_updated(snapshot: Dictionary) -> void:
	_wave_label.text = "Wave: %s" % snapshot.get("wave", "-")
	_time_label.text = "Time: %s" % snapshot.get("time", "-")
	_money_label.text = "Money: %s" % snapshot.get("money", "-")
	_magic_label.text = "Magic: %s" % snapshot.get("magic", "-")
	_debt_label.text = "Debt: %s" % snapshot.get("debt", "-")

func _on_end_shift_pressed() -> void:
	if _run_manager:
		_run_manager.end_shift()
	else:
		push_warning("Cannot end shift: RunManager singleton missing.")

func _detach_item_node(node: ItemNode) -> void:
	if node == null:
		return
	if _player and _player.get_active_hand_item() == node:
		_player.take_item_from_hand()
	for slot in _slots:
		if slot.get_item() == node:
			var _unused := slot.take_item()
			break

func _find_item_instance(item_id: StringName) -> ItemInstance:
	if item_id == StringName():
		return null
	for client in _clients.values():
		var client_state: RefCounted = client
		if client_state == null:
			continue
		if client_state.get_coat_id() == item_id:
			return client_state.get_coat_item()
		if client_state.get_ticket_id() == item_id:
			return client_state.get_ticket_item()
	return null

func _resolve_item_type(type_name: Variant) -> ItemNode.ItemType:
	var text := str(type_name).to_upper()
	match text:
		"TICKET":
			return ItemNode.ItemType.TICKET
		"ANCHOR_TICKET":
			return ItemNode.ItemType.ANCHOR_TICKET
		_:
			return ItemNode.ItemType.COAT

func _make_item_instance(item: ItemNode) -> ItemInstance:
	var color := _item_visuals.get_item_color(item)
	return ItemInstanceScript.new(
		StringName(item.item_id),
		_item_visuals.resolve_kind_from_item_type(item.item_type),
		color
	)

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
	var node: ItemNode = _player.take_item_from_hand() if _player else null
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
	var incoming_node: ItemNode = _player.take_item_from_hand() if _player else null
	if slot and incoming_node:
		slot.put_item(incoming_node)
	if slot_outgoing and _player:
		_player.hold_item(slot_outgoing)
	_interaction_service.set_hand_item(_instance_from_snapshot(outgoing_item))

func _on_event_action_rejected(_slot_id: StringName, _reason: StringName, _tick: int) -> void:
	pass
