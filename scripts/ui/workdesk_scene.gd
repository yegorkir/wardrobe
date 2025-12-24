extends Node2D

const ITEM_SCENE := preload("res://scenes/prefabs/item_node.tscn")
const WardrobeInteractionServiceScript := preload("res://scripts/app/interaction/interaction_service.gd")
const WardrobeInteractionEventAdapterScript := preload("res://scripts/wardrobe/interaction_event_adapter.gd")
const WardrobeWorldValidatorScript := preload("res://scripts/ui/wardrobe_world_validator.gd")
const WardrobeStep3SetupAdapterScript := preload("res://scripts/ui/wardrobe_step3_setup.gd")
const WardrobeInteractionEventsAdapterScript := preload("res://scripts/ui/wardrobe_interaction_events.gd")
const DeskEventDispatcherScript := preload("res://scripts/ui/desk_event_dispatcher.gd")
const WardrobeItemVisualsAdapterScript := preload("res://scripts/ui/wardrobe_item_visuals.gd")
const WardrobeDragDropAdapterScript := preload("res://scripts/ui/wardrobe_dragdrop_adapter.gd")
const WardrobeInteractionContextScript := preload("res://scripts/ui/wardrobe_interaction_context.gd")
const WardrobeWorldSetupAdapterScript := preload("res://scripts/ui/wardrobe_world_setup_adapter.gd")
const WardrobeHudAdapterScript := preload("res://scripts/ui/wardrobe_hud_adapter.gd")
const WardrobeInteractionLoggerScript := preload("res://scripts/ui/wardrobe_interaction_logger.gd")
const WardrobeShiftLogScript := preload("res://scripts/app/logging/shift_log.gd")

@export var step3_seed: int = 1337
@export var desk_event_unhandled_policy: StringName = WardrobeInteractionEventsAdapter.UNHANDLED_WARN

@onready var _wave_label: Label = %WaveValue
@onready var _time_label: Label = %TimeValue
@onready var _money_label: Label = %MoneyValue
@onready var _magic_label: Label = %MagicValue
@onready var _debt_label: Label = %DebtValue
@onready var _end_shift_button: Button = %EndShiftButton
@onready var _cursor_hand: CursorHand = %CursorHand
@onready var _run_manager: RunManagerBase = get_node_or_null("/root/RunManager") as RunManagerBase

var _interaction_service := WardrobeInteractionServiceScript.new()
var _storage_state: WardrobeStorageState = _interaction_service.get_storage_state()
var _event_adapter: WardrobeInteractionEventAdapter = WardrobeInteractionEventAdapterScript.new()
var _step3_setup: WardrobeStep3SetupAdapter = WardrobeStep3SetupAdapterScript.new()
var _interaction_events: WardrobeInteractionEventsAdapter = WardrobeInteractionEventsAdapterScript.new()
var _desk_event_dispatcher := DeskEventDispatcherScript.new()
var _item_visuals: WardrobeItemVisualsAdapter = WardrobeItemVisualsAdapterScript.new()
var _world_validator := WardrobeWorldValidatorScript.new()
var _dragdrop_adapter := WardrobeDragDropAdapterScript.new()
var _world_adapter := WardrobeWorldSetupAdapterScript.new()
var _hud_adapter := WardrobeHudAdapterScript.new()
var _interaction_logger := WardrobeInteractionLoggerScript.new()
var _shift_log: WardrobeShiftLog = WardrobeShiftLogScript.new()

func _ready() -> void:
	_hud_adapter.configure(
		_run_manager,
		_wave_label,
		_time_label,
		_money_label,
		_magic_label,
		_debt_label,
		_end_shift_button
	)
	_hud_adapter.setup_hud()
	if _cursor_hand == null:
		push_warning("CursorHand node missing; drag-and-drop disabled.")
		return
	call_deferred("_finish_ready_setup")

func _finish_ready_setup() -> void:
	_world_adapter.configure(
		self,
		_interaction_service,
		_storage_state,
		_step3_setup,
		_item_visuals,
		Callable(_interaction_events, "apply_desk_events")
	)
	_world_adapter.collect_slots()
	_world_adapter.collect_desks()
	if _world_adapter.get_slots().is_empty():
		await get_tree().process_frame
		_world_adapter.collect_slots()
		_world_adapter.collect_desks()
	_world_adapter.reset_storage_state()
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
	_interaction_logger.configure(Callable(_shift_log, "record"))
	interaction_context.interaction_logger = _interaction_logger
	_interaction_events.set_unhandled_policy(desk_event_unhandled_policy)
	_dragdrop_adapter.configure(interaction_context, _cursor_hand, Callable(self, "_debug_validate_world"))
	_world_adapter.initialize_world()

func _unhandled_input(event: InputEvent) -> void:
	print(event)
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

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		_dragdrop_adapter.cancel_drag()

func _exit_tree() -> void:
	_hud_adapter.teardown_hud()

func _debug_validate_world() -> void:
	if not OS.is_debug_build():
		return
	_world_validator.validate(_world_adapter.get_slots(), null)
