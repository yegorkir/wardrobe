extends RefCounted

class_name WardrobeInteractionService

const CommandScript := preload("res://scripts/app/interaction/interaction_command.gd")
const EngineScript := preload("res://scripts/domain/interaction/interaction_engine.gd")
const InteractionCommandScript := preload("res://scripts/domain/interaction/interaction_command.gd")
const InteractionResultScript := preload("res://scripts/domain/interaction/interaction_result.gd")
const StorageStateScript := preload("res://scripts/domain/storage/wardrobe_storage_state.gd")
const ItemInstanceScript := preload("res://scripts/domain/storage/item_instance.gd")
var _engine: WardrobeInteractionDomainEngine = EngineScript.new()
var _storage_state: WardrobeStorageState = StorageStateScript.new()
var _hand_item: ItemInstance
var _interaction_tick := 0
var _last_command: InteractionCommandScript

func get_storage_state() -> WardrobeStorageState:
	return _storage_state

func get_hand_item() -> ItemInstance:
	return _hand_item

func set_hand_item(item: ItemInstance) -> void:
	_hand_item = item

func clear_hand_item() -> void:
	_hand_item = null

func reset_state() -> void:
	_storage_state.clear()
	_hand_item = null
	_interaction_tick = 0
	_last_command = null

func register_slot(slot_id: StringName) -> void:
	_storage_state.register_slot(slot_id)

func build_auto_command(slot_id: StringName, slot_item: ItemInstance) -> InteractionCommandScript:
	var hand_id := str(_hand_item.id) if _hand_item else ""
	var slot_item_id := str(slot_item.id) if slot_item else ""
	var command := CommandScript.build(
		CommandScript.TYPE_AUTO,
		_interaction_tick,
		slot_id,
		hand_id,
		slot_item_id
	)
	_last_command = command
	_interaction_tick += 1
	return command

func execute_command(command: InteractionCommandScript) -> InteractionResultScript:
	var result := _engine.process_command(command, _storage_state, _hand_item)
	_hand_item = result.hand_item
	return result

func get_last_command() -> InteractionCommandScript:
	return _last_command.duplicate_command() if _last_command else null
