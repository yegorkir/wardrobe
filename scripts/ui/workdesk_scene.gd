extends Node2D

const ITEM_SCENE := preload("res://scenes/prefabs/item_node.tscn")
const WardrobeInteractionServiceScript := preload("res://scripts/app/interaction/interaction_service.gd")
const WardrobeInteractionEventAdapterScript := preload("res://scripts/wardrobe/interaction_event_adapter.gd")
const WardrobeWorldValidatorScript := preload("res://scripts/ui/wardrobe_world_validator.gd")
const WardrobeStep3SetupAdapterScript := preload("res://scripts/ui/wardrobe_step3_setup.gd")
const WardrobeInteractionEventsAdapterScript := preload("res://scripts/ui/wardrobe_interaction_events.gd")
const WorkdeskDeskEventsBridgeScript := preload("res://scripts/ui/workdesk_desk_events_bridge.gd")
const DeskEventDispatcherScript := preload("res://scripts/ui/desk_event_dispatcher.gd")
const WardrobeItemVisualsAdapterScript := preload("res://scripts/ui/wardrobe_item_visuals.gd")
const WardrobeDragDropAdapterScript := preload("res://scripts/ui/wardrobe_dragdrop_adapter.gd")
const WardrobeInteractionContextScript := preload("res://scripts/ui/wardrobe_interaction_context.gd")
const WardrobeWorldSetupAdapterScript := preload("res://scripts/ui/wardrobe_world_setup_adapter.gd")
const WardrobeHudAdapterScript := preload("res://scripts/ui/wardrobe_hud_adapter.gd")
const WardrobeInteractionLoggerScript := preload("res://scripts/ui/wardrobe_interaction_logger.gd")
const WardrobeShiftLogScript := preload("res://scripts/app/logging/shift_log.gd")
const WorkdeskClientsUIAdapterScript := preload("res://scripts/ui/workdesk_clients_ui_adapter.gd")
const ShelfSurfaceAdapterScript := preload("res://scripts/ui/shelf_surface_adapter.gd")
const FloorZoneAdapterScript := preload("res://scripts/ui/floor_zone_adapter.gd")
const DebugFlags := preload("res://scripts/wardrobe/config/debug_flags.gd")
const FloorResolverScript := preload("res://scripts/app/wardrobe/floor_resolver.gd")
const SurfaceRegistryScript := preload("res://scripts/wardrobe/surface/surface_registry.gd")

@export var step3_seed: int = 1337
@export var desk_event_unhandled_policy: StringName = WardrobeInteractionEventsAdapter.UNHANDLED_WARN
@export var debug_no_fail_wave: bool = false
@export var debug_logs_enabled: bool = false

@onready var _wave_label: Label = %WaveValue
@onready var _time_label: Label = %TimeValue
@onready var _money_label: Label = %MoneyValue
@onready var _magic_label: Label = %MagicValue
@onready var _debt_label: Label = %DebtValue
@onready var _strikes_label: Label = %StrikesValue
@onready var _end_shift_button: Button = %EndShiftButton
@onready var _cursor_hand: CursorHand = %CursorHand
@onready var _physics_tick: Node = %WardrobePhysicsTick
@onready var _run_manager: RunManagerBase = get_node_or_null("/root/RunManager") as RunManagerBase

var _interaction_service := WardrobeInteractionServiceScript.new()
var _storage_state: WardrobeStorageState = _interaction_service.get_storage_state()
var _event_adapter: WardrobeInteractionEventAdapter = WardrobeInteractionEventAdapterScript.new()
var _step3_setup: WardrobeStep3SetupAdapter = WardrobeStep3SetupAdapterScript.new()
var _interaction_events_bridge: WorkdeskDeskEventsBridge = WorkdeskDeskEventsBridgeScript.new()
var _interaction_events: WardrobeInteractionEventsAdapter = _interaction_events_bridge
var _desk_event_dispatcher := DeskEventDispatcherScript.new()
var _item_visuals: WardrobeItemVisualsAdapter = WardrobeItemVisualsAdapterScript.new()
var _world_validator := WardrobeWorldValidatorScript.new()
var _dragdrop_adapter := WardrobeDragDropAdapterScript.new()
var _world_adapter := WardrobeWorldSetupAdapterScript.new()
var _hud_adapter := WardrobeHudAdapterScript.new()
var _interaction_logger := WardrobeInteractionLoggerScript.new()
var _shift_log: WardrobeShiftLog = WardrobeShiftLogScript.new()
var _clients_ui: WorkdeskClientsUIAdapter = WorkdeskClientsUIAdapterScript.new()
var _floor_resolver = FloorResolverScript.new()
var _shelf_surfaces: Array = []
var _floor_zone: FloorZoneAdapter
var _floor_zones: Array = []

var _wave_time_left := 60.0
var _wave_failed := false
var _shift_finished := false
var _served_clients := 0
var _total_clients := 0
var _patience_by_client_id: Dictionary = {}
var _patience_max_by_client_id: Dictionary = {}
var _desk_states_by_id: Dictionary = {}
var _clients_ready := false

func _ready() -> void:
	DebugFlags.set_enabled(debug_logs_enabled)
	if debug_no_fail_wave:
		push_warning("debug_no_fail_wave is enabled; wave failures will be suppressed.")
	_hud_adapter.configure(
		_run_manager,
		_wave_label,
		_time_label,
		_money_label,
		_magic_label,
		_debt_label,
		_strikes_label,
		_end_shift_button,
		Callable(self, "_on_end_shift_pressed")
	)
	_hud_adapter.setup_hud()
	if _cursor_hand == null:
		push_warning("CursorHand node missing; drag-and-drop disabled.")
		return
	call_deferred("_finish_ready_setup")

func _finish_ready_setup() -> void:
	_interaction_events_bridge.configure_bridge(
		Callable(self, "_on_client_completed"),
		Callable(self, "_on_client_checkin")
	)
	_world_adapter.configure(
		self,
		_interaction_service,
		_storage_state,
		_step3_setup,
		_item_visuals,
		Callable(_interaction_events, "apply_desk_events")
	)
	if _run_manager:
		_world_adapter.get_desk_system().configure_queue_mix_provider(
			Callable(_run_manager, "get_queue_mix_snapshot")
		)
	_world_adapter.collect_slots()
	_world_adapter.collect_desks()
	if _world_adapter.get_slots().is_empty():
		await get_tree().process_frame
		_world_adapter.collect_slots()
		_world_adapter.collect_desks()
	_world_adapter.reset_storage_state()
	_configure_floor_resolver()
	var interaction_context := WardrobeInteractionContextScript.new()
	interaction_context.player = null
	interaction_context.interaction_service = _interaction_service
	interaction_context.storage_state = _storage_state
	interaction_context.slots = _world_adapter.get_slots()
	interaction_context.slot_lookup = _world_adapter.get_slot_lookup()
	interaction_context.item_nodes = _world_adapter.get_item_nodes()
	interaction_context.spawned_items = _world_adapter.get_spawned_items()
	interaction_context.item_scene = ITEM_SCENE
	interaction_context.item_visuals = _item_visuals
	interaction_context.physics_tick = _physics_tick
	interaction_context.event_adapter = _event_adapter
	interaction_context.interaction_events = _interaction_events
	interaction_context.desk_event_dispatcher = _desk_event_dispatcher
	interaction_context.desk_states = _world_adapter.get_desk_states()
	interaction_context.desk_by_id = _world_adapter.get_desk_by_id()
	interaction_context.desk_by_slot_id = _world_adapter.get_desk_by_slot_id()
	interaction_context.desk_system = _world_adapter.get_desk_system()
	interaction_context.client_queue_state = _world_adapter.get_client_queue_state()
	interaction_context.clients = _world_adapter.get_clients()
	interaction_context.find_item_instance = Callable(_world_adapter, "find_item_instance")
	interaction_context.floor_resolver = _floor_resolver
	if _run_manager != null:
		interaction_context.apply_patience_penalty = Callable(_run_manager, "apply_patience_penalty")
	_interaction_logger.configure(Callable(_shift_log, "record"))
	interaction_context.interaction_logger = _interaction_logger
	_interaction_events.set_unhandled_policy(desk_event_unhandled_policy)
	_dragdrop_adapter.configure(interaction_context, _cursor_hand, Callable(self, "_debug_validate_world"))
	_collect_surface_targets()
	_dragdrop_adapter.configure_surface_targets(_shelf_surfaces, _floor_zone)
	_world_adapter.initialize_world()
	_setup_clients_ui()

func _configure_floor_resolver() -> void:
	var registry := SurfaceRegistryScript.get_autoload()
	if registry == null:
		return
	var floor_ids: Array = []
	for floor_node in registry.get_floors():
		if floor_node == null:
			continue
		floor_ids.append(StringName(String(floor_node.name)))
	var default_floor_id := StringName()
	if not floor_ids.is_empty():
		default_floor_id = StringName(String(floor_ids[0]))
	_floor_resolver.configure(floor_ids, default_floor_id)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_reset"):
		_world_adapter.reset_world()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT:
			if mouse_event.pressed:
				_dragdrop_adapter.on_pointer_down(mouse_event.position)
			else:
				_dragdrop_adapter.on_pointer_up(mouse_event.position)
			get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseMotion:
		var motion := event as InputEventMouseMotion
		_dragdrop_adapter.on_pointer_move(motion.position)
		return
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			_dragdrop_adapter.on_pointer_down(touch.position)
		else:
			_dragdrop_adapter.on_pointer_up(touch.position)
		get_viewport().set_input_as_handled()
		return
	if event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		_dragdrop_adapter.on_pointer_move(drag.position)
		return

func _process(_delta: float) -> void:
	_dragdrop_adapter.update_drag_watchdog()
	_tick_wave_and_patience(_delta)

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		_dragdrop_adapter.cancel_drag()

func _exit_tree() -> void:
	_hud_adapter.teardown_hud()

func _debug_validate_world() -> void:
	if not OS.is_debug_build():
		return
	_world_validator.validate(_world_adapter.get_slots(), null)

func _setup_clients_ui() -> void:
	_clients_ready = false
	_wave_time_left = 60.0
	_wave_failed = false
	_shift_finished = false
	_served_clients = 0
	_patience_by_client_id.clear()
	_patience_max_by_client_id.clear()
	_desk_states_by_id.clear()
	var clients_by_id: Dictionary = _world_adapter.get_clients()
	var desk_states: Array = _world_adapter.get_desk_states()
	for desk_state in desk_states:
		if desk_state == null:
			continue
		_desk_states_by_id[desk_state.desk_id] = desk_state
	if _run_manager:
		var patience_snapshot := _run_manager.configure_patience_clients(clients_by_id.keys())
		_apply_patience_snapshot(patience_snapshot)
	_total_clients = clients_by_id.size()
	if _run_manager:
		_run_manager.configure_shift_targets(_total_clients, _total_clients)
	var desks_by_id: Dictionary = {}
	for desk_node in _world_adapter.get_desk_nodes():
		if desk_node == null:
			continue
		var desk_id: StringName = desk_node.desk_id
		var client_visual := desk_node.get_node_or_null("ClientVisual") as CanvasItem
		var patience_bg := desk_node.get_node_or_null("PatienceBarBg") as Control
		var patience_fill := desk_node.get_node_or_null("PatienceBarBg/PatienceBarFill") as Control
		if client_visual == null or patience_bg == null or patience_fill == null:
			push_warning("Desk %s missing client UI nodes; clients UI disabled for this desk." % desk_id)
			continue
		var desk_view := WorkdeskClientsUIAdapterScript.DeskClientView.new()
		desk_view.configure(client_visual, patience_bg, patience_fill)
		desks_by_id[desk_id] = desk_view
	_clients_ui.configure(
		desks_by_id,
		_desk_states_by_id,
		_patience_by_client_id,
		_patience_max_by_client_id,
		clients_by_id
	)
	_clients_ui.refresh()
	_clients_ready = true

func _apply_patience_snapshot(snapshot: Dictionary) -> void:
	_patience_by_client_id.clear()
	_patience_max_by_client_id.clear()
	var patience_by: Dictionary = snapshot.get("patience_by_client_id", {})
	var patience_max: Dictionary = snapshot.get("patience_max_by_client_id", {})
	_patience_by_client_id.merge(patience_by, true)
	_patience_max_by_client_id.merge(patience_max, true)

func _collect_surface_targets() -> void:
	_shelf_surfaces.clear()
	for node in get_tree().get_nodes_in_group(ShelfSurfaceAdapter.SHELF_GROUP):
		if node is ShelfSurfaceAdapter:
			_shelf_surfaces.append(node)
	if _shelf_surfaces.is_empty():
		for node in find_children("*", "ShelfSurfaceAdapter", true, true):
			if node is ShelfSurfaceAdapter:
				_shelf_surfaces.append(node)
	_floor_zones.clear()
	_floor_zone = null
	for node in get_tree().get_nodes_in_group(FloorZoneAdapter.FLOOR_GROUP):
		if node is FloorZoneAdapter:
			_floor_zones.append(node)
			if _floor_zone == null:
				_floor_zone = node
	if _floor_zone == null:
		for node in find_children("*", "FloorZoneAdapter", true, true):
			if node is FloorZoneAdapter:
				_floor_zones.append(node)
				if _floor_zone == null:
					_floor_zone = node
	if _floor_zone == null:
		push_warning("FloorZone adapter missing; surface drops will be ignored.")

func _tick_wave_and_patience(delta: float) -> void:
	if not _clients_ready or _shift_finished:
		return
	if _wave_failed:
		return
	_wave_time_left -= delta
	if _wave_time_left <= 0.0 and _served_clients < _total_clients:
		_fail_wave()
		return
	if _run_manager:
		var active_clients: Array = []
		for desk_state in _desk_states_by_id.values():
			if desk_state == null:
				continue
			var client_id: StringName = desk_state.current_client_id
			if client_id == StringName():
				continue
			active_clients.append(client_id)
		_run_manager.tick_patience(active_clients, delta)
		_apply_patience_snapshot(_run_manager.get_patience_snapshot())
		_run_manager.update_active_client_count(active_clients.size())
	_clients_ui.refresh()

func _fail_wave() -> void:
	if _shift_finished:
		return
	if debug_no_fail_wave:
		push_warning("Wave failure suppressed by debug_no_fail_wave; ending shift without fail.")
		_finish_shift_safe()
		return
	_wave_failed = true
	_finish_shift_safe()

func _on_client_completed() -> void:
	_served_clients += 1
	if _run_manager:
		_run_manager.register_checkout_completed()

func _on_client_checkin() -> void:
	if _run_manager:
		_run_manager.register_checkin_completed()

func _on_end_shift_pressed() -> void:
	if _shift_finished:
		return
	var was_dragging := _dragdrop_adapter.has_active_drag()
	_cancel_drag_for_shift_end()
	if was_dragging:
		return
	_finish_shift_safe()

func _finish_shift_safe() -> void:
	if _shift_finished:
		return
	_shift_finished = true
	_cancel_drag_for_shift_end()
	if _run_manager:
		_run_manager.end_shift()

func _cancel_drag_for_shift_end() -> void:
	if _dragdrop_adapter:
		_dragdrop_adapter.force_cancel_drag()
