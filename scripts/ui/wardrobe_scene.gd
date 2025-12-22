extends Node2D

const ITEM_SCENE := preload("res://scenes/prefabs/item_node.tscn")
const WardrobeInteractionServiceScript := preload("res://scripts/app/interaction/interaction_service.gd")
const WardrobeInteractionEventAdapterScript := preload("res://scripts/wardrobe/interaction_event_adapter.gd")
const WardrobeWorldValidatorScript := preload("res://scripts/ui/wardrobe_world_validator.gd")
const WardrobeStep3SetupAdapterScript := preload("res://scripts/ui/wardrobe_step3_setup.gd")
const WardrobeInteractionEventsAdapterScript := preload("res://scripts/ui/wardrobe_interaction_events.gd")
const DeskEventDispatcherScript := preload("res://scripts/ui/desk_event_dispatcher.gd")
const WardrobeItemVisualsAdapterScript := preload("res://scripts/ui/wardrobe_item_visuals.gd")
const WardrobeInteractionAdapterScript := preload("res://scripts/ui/wardrobe_interaction_adapter.gd")
const WardrobeWorldSetupAdapterScript := preload("res://scripts/ui/wardrobe_world_setup_adapter.gd")
const WardrobeHudAdapterScript := preload("res://scripts/ui/wardrobe_hud_adapter.gd")

@export var step3_seed: int = 1337

@onready var _wave_label: Label = %WaveValue
@onready var _time_label: Label = %TimeValue
@onready var _money_label: Label = %MoneyValue
@onready var _magic_label: Label = %MagicValue
@onready var _debt_label: Label = %DebtValue
@onready var _end_shift_button: Button = %EndShiftButton
@onready var _player: WardrobePlayerController = %Player
@onready var _run_manager: RunManagerBase = get_node_or_null("/root/RunManager") as RunManagerBase

var _interaction_service := WardrobeInteractionServiceScript.new()
var _storage_state: WardrobeStorageState = _interaction_service.get_storage_state()
var _event_adapter: WardrobeInteractionEventAdapter = WardrobeInteractionEventAdapterScript.new()
var _step3_setup: WardrobeStep3SetupAdapter = WardrobeStep3SetupAdapterScript.new()
var _interaction_events: WardrobeInteractionEventsAdapter = WardrobeInteractionEventsAdapterScript.new()
var _desk_event_dispatcher := DeskEventDispatcherScript.new()
var _item_visuals: WardrobeItemVisualsAdapter = WardrobeItemVisualsAdapterScript.new()
var _world_validator := WardrobeWorldValidatorScript.new()
var _interaction_adapter := WardrobeInteractionAdapterScript.new()
var _world_adapter := WardrobeWorldSetupAdapterScript.new()
var _hud_adapter := WardrobeHudAdapterScript.new()

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
	if _player == null:
		push_warning("Player node missing; Step 2 sandbox disabled.")
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
	_interaction_adapter.configure(
		_player,
		_interaction_service,
		_storage_state,
		_world_adapter.get_slots(),
		_world_adapter.get_slot_lookup(),
		_world_adapter.get_item_nodes(),
		_world_adapter.get_spawned_items(),
		ITEM_SCENE,
		_item_visuals,
		_event_adapter,
		_interaction_events,
		_desk_event_dispatcher,
		_world_adapter.get_desk_states(),
		_world_adapter.get_desk_by_id(),
		_world_adapter.get_desk_by_slot_id(),
		_world_adapter.get_desk_system(),
		_world_adapter.get_client_queue_state(),
		_world_adapter.get_clients(),
		Callable(_world_adapter, "find_item_instance")
	)
	_world_adapter.initialize_world()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		_perform_interact()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("debug_reset"):
		_world_adapter.reset_world()
		get_viewport().set_input_as_handled()

func _process(_delta: float) -> void:
	pass

func _exit_tree() -> void:
	_hud_adapter.teardown_hud()

func _perform_interact() -> void:
	_interaction_adapter.perform_interact()
	_debug_validate_world()

func _debug_validate_world() -> void:
	if not OS.is_debug_build():
		return
	_world_validator.validate(_world_adapter.get_slots(), _player)
