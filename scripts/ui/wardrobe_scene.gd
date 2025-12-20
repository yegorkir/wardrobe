extends Node2D

const ITEM_SCENE := preload("res://scenes/prefabs/item_node.tscn")
const WardrobeChallengeProviderScript := preload("res://scripts/wardrobe/wardrobe_challenge_provider.gd")
const WardrobeInteractionCommandScript := preload("res://scripts/app/interaction/interaction_command.gd")
const WardrobeInteractionEngineScript := preload("res://scripts/app/interaction/interaction_engine.gd")
const PickPutSwapResolverScript := preload("res://scripts/app/interaction/pick_put_swap_resolver.gd")
const WardrobeInteractionEventAdapterScript := preload("res://scripts/wardrobe/interaction_event_adapter.gd")
const WardrobeStorageStateScript := preload("res://scripts/domain/storage/wardrobe_storage_state.gd")
const ItemInstanceScript := preload("res://scripts/domain/storage/item_instance.gd")
const DeskServicePointSystemScript := preload("res://scripts/app/desk/desk_service_point_system.gd")
const DeskStateScript := preload("res://scripts/domain/desk/desk_state.gd")
const ClientStateScript := preload("res://scripts/domain/clients/client_state.gd")
const DeskServicePointScript := preload("res://scripts/wardrobe/desk_service_point.gd")
const ITEM_TEXTURE_PATHS := {
	ItemNode.ItemType.COAT: [
		"res://assets/sprites/item_coat.png",
		"res://assets/sprites/placeholder/item_coat.png",
	],
	ItemNode.ItemType.TICKET: [
		"res://assets/sprites/item_ticket.png",
		"res://assets/sprites/placeholder/item_ticket.png",
	],
	ItemNode.ItemType.ANCHOR_TICKET: [
		"res://assets/sprites/item_anchor_ticket.png",
		"res://assets/sprites/placeholder/item_anchor_ticket.png",
	],
}

@export var challenge_provider: Resource
@export var step3_enabled := true
@export var step3_seed: int = 1337

@onready var _wave_label: Label = %WaveValue
@onready var _time_label: Label = %TimeValue
@onready var _money_label: Label = %MoneyValue
@onready var _magic_label: Label = %MagicValue
@onready var _debt_label: Label = %DebtValue
@onready var _end_shift_button: Button = %EndShiftButton
@onready var _run_manager: RunManagerBase = get_node_or_null("/root/RunManager") as RunManagerBase
@onready var _content_db: ContentDBBase = get_node_or_null("/root/ContentDB") as ContentDBBase
@onready var _player: WardrobePlayerController = %Player
@onready var _challenge_overlay_label: Label = %ChallengeOverlayLabel
@onready var _challenge_summary_panel: Control = %ChallengeSummary
@onready var _summary_time_label: Label = %SummaryTimeValue
@onready var _summary_actions_label: Label = %SummaryActionsValue
@onready var _summary_picks_label: Label = %SummaryPicksValue
@onready var _summary_puts_label: Label = %SummaryPutsValue
@onready var _summary_swaps_label: Label = %SummarySwapsValue
@onready var _summary_move_label: Label = %SummaryMoveValue
@onready var _summary_attempts_label: Label = %SummaryAttemptsValue
@onready var _summary_best_label: Label = %SummaryBestValue
var _desk_slot: WardrobeSlot

var _hud_connected := false
var _interaction_engine: WardrobeInteractionEngine = WardrobeInteractionEngineScript.new()
var _slots: Array[WardrobeSlot] = []
var _slot_lookup: Dictionary = {}
var _spawned_items: Array[ItemNode] = []
var _item_nodes: Dictionary = {}
var _seed_entries: Array = []
var _challenge_controller: WardrobeChallengeController = WardrobeChallengeController.new()
var _last_player_position := Vector2.ZERO
var _active_ticket_item: ItemNode
var _interaction_tick := 0
var _storage_state: WardrobeStorageState = WardrobeStorageStateScript.new()
var _event_adapter: WardrobeInteractionEventAdapter = WardrobeInteractionEventAdapterScript.new()
var _hand_item_instance: ItemInstance
var _desk_system: RefCounted = DeskServicePointSystemScript.new()
var _desk_nodes: Array = []
var _desk_states: Array = []
var _desk_by_id: Dictionary = {}
var _desk_by_slot_id: Dictionary = {}
var _clients: Dictionary = {}
var _step3_rng := RandomNumberGenerator.new()

const DISTANCE_TIE_THRESHOLD := 6.0

func _ready() -> void:
	_ensure_challenge_provider()
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
	if step3_enabled:
		_initialize_step3()
	else:
		_initialize_challenge_controller()
		_desk_slot = _resolve_default_desk_slot()
		if _challenge_controller.is_enabled():
			_start_challenge_session(false)
		elif challenge_provider:
			_seed_entries = challenge_provider.load_seed_entries()
			_apply_seed(_seed_entries)
	if _challenge_summary_panel:
		_challenge_summary_panel.visible = false
	_update_overlay_label()
	_end_shift_button.pressed.connect(_on_end_shift_pressed)
	if not step3_enabled:
		_materialize_missing_seed_items()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		if _challenge_controller.is_active():
			_challenge_controller.register_manual_action()
		_perform_interact()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("debug_reset"):
		_reset_world()
		get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	if _challenge_controller.is_active():
		_challenge_controller.update_elapsed(delta)
		_update_move_distance()
	if _challenge_controller.is_enabled():
		_update_overlay_label()

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
			_slot_lookup[slot.get_slot_identifier()] = slot
	if _slots.is_empty():
		for node in find_children("*", "WardrobeSlot", true, true):
			if node is WardrobeSlot:
				var slot := node as WardrobeSlot
				_slots.append(slot)
				_slot_lookup[slot.get_slot_identifier()] = slot
	if _desk_slot and not _slot_lookup.has(_desk_slot.get_slot_identifier()):
		_slots.append(_desk_slot)
		_slot_lookup[_desk_slot.get_slot_identifier()] = _desk_slot

func _collect_desks() -> void:
	_desk_nodes.clear()
	for node in get_tree().get_nodes_in_group(DeskServicePointScript.DESK_GROUP):
		if node is Node2D and node.has_method("get_slot_id"):
			_desk_nodes.append(node)

func _resolve_default_desk_slot() -> WardrobeSlot:
	var desk_node := get_node_or_null("GameRoot/Desk")
	if desk_node and desk_node.has_method("get_slot_node"):
		return desk_node.get_slot_node()
	return null

func _initialize_challenge_controller() -> void:
	if challenge_provider == null:
		push_warning("Challenge provider unavailable; challenge disabled.")
		return
	var challenge_id: String = challenge_provider.get_default_challenge_id()
	var challenge_definition: Dictionary = challenge_provider.load_challenge_definition(challenge_id)
	var best_results: Dictionary = challenge_provider.load_best_results()
	if _challenge_controller == null:
		_challenge_controller = WardrobeChallengeController.new()
	_challenge_controller.configure(challenge_definition, best_results, challenge_id)

func _reset_storage_state() -> void:
	if _storage_state == null:
		_storage_state = WardrobeStorageStateScript.new()
	_storage_state.clear()
	_register_storage_slots()
	_hand_item_instance = null

func _initialize_step3() -> void:
	_clear_spawned_items()
	_collect_desks()
	_setup_step3_rng()
	_setup_step3_desks_and_clients()
	_seed_step3_hook_tickets()
	_sync_hook_anchor_tickets_once()
	_spawn_step3_desk_coats()

func _setup_step3_rng() -> void:
	_step3_rng.seed = step3_seed

func _setup_step3_desks_and_clients() -> void:
	_desk_states.clear()
	_desk_by_id.clear()
	_desk_by_slot_id.clear()
	_clients.clear()
	if _desk_nodes.is_empty():
		push_warning("Step 3 desks missing; no service points initialized.")
		return
	var desk_ids: Array[StringName] = []
	for index in _desk_nodes.size():
		var desk_node: Node = _desk_nodes[index]
		if desk_node == null:
			continue
		var desk_id: StringName = desk_node.desk_id
		var slot_id: StringName = desk_node.get_slot_id()
		var desk_state := DeskStateScript.new(desk_id, slot_id)
		_desk_states.append(desk_state)
		_desk_by_id[desk_state.desk_id] = desk_state
		_desk_by_slot_id[desk_state.desk_slot_id] = desk_state
		desk_ids.append(desk_state.desk_id)
	var per_desk_queue: Dictionary = {}
	for desk_id in desk_ids:
		per_desk_queue[desk_id] = []
	var colors: Array[Color] = [
		Color(0.85, 0.35, 0.35),
		Color(0.35, 0.7, 0.45),
		Color(0.35, 0.45, 0.9),
		Color(0.9, 0.75, 0.35),
	]
	for i in range(4):
		var client_id := StringName("Client_%d" % i)
		var color: Color = colors[i % colors.size()]
		var coat := ItemInstanceScript.new(
			StringName("coat_%02d" % i),
			ItemInstanceScript.KIND_COAT,
			color
		)
		var ticket := ItemInstanceScript.new(
			StringName("ticket_%02d" % i),
			ItemInstanceScript.KIND_TICKET,
			color
		)
		var desk_index := _step3_rng.randi_range(0, desk_ids.size() - 1)
		var desk_id := desk_ids[desk_index]
		var client := ClientStateScript.new(client_id, coat, ticket, desk_id, StringName("color_%d" % i))
		_clients[client_id] = client
		var queue: Array = per_desk_queue.get(desk_id, [])
		queue.append(client_id)
		per_desk_queue[desk_id] = queue
	for desk_state in _desk_states:
		var assigned: Array = per_desk_queue.get(desk_state.desk_id, [])
		desk_state.set_dropoff_queue(assigned)
		desk_state.set_phase(DeskStateScript.PHASE_DROP_OFF)
		desk_state.current_client_id = desk_state.pop_next_dropoff()

func _seed_step3_hook_tickets() -> void:
	var ticket_slots: Array[WardrobeSlot] = _get_ticket_slots()
	if ticket_slots.is_empty():
		push_warning("Step 3 hooks missing; no ticket slots found.")
		return
	var client_ids: Array = _clients.keys()
	var slot_count: int = min(ticket_slots.size(), client_ids.size())
	for index in range(slot_count):
		var client_id: StringName = StringName(str(client_ids[index]))
		var client: RefCounted = _clients.get(client_id, null)
		if client == null:
			continue
		_place_item_instance_in_slot(
			StringName(ticket_slots[index].get_slot_identifier()),
			client.get_ticket_item()
			)

func _sync_hook_anchor_tickets_once() -> void:
	for node in find_children("*", "HookItem", true, true):
		if node.has_method("sync_anchor_ticket_color"):
			node.sync_anchor_ticket_color()

func _spawn_step3_desk_coats() -> void:
	for desk_state in _desk_states:
		if desk_state.current_client_id.is_empty():
			continue
		var client: RefCounted = _clients.get(desk_state.current_client_id, null)
		if client == null:
			continue
		_place_item_instance_in_slot(desk_state.desk_slot_id, client.get_coat_item())

func _register_storage_slots() -> void:
	for slot in _slots:
		_storage_state.register_slot(StringName(slot.get_slot_identifier()))

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
		_storage_state.register_slot(slot_id)
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
	_spawn_or_move_item_node(slot_id, instance)

func _connect_event_adapter() -> void:
	if _event_adapter == null:
		_event_adapter = WardrobeInteractionEventAdapterScript.new()
	_event_adapter.item_picked.connect(_on_event_item_picked)
	_event_adapter.item_placed.connect(_on_event_item_placed)
	_event_adapter.item_swapped.connect(_on_event_item_swapped)
	_event_adapter.action_rejected.connect(_on_event_action_rejected)

func _start_challenge_session(is_restart: bool) -> void:
	if not _challenge_controller.is_enabled():
		return
	if is_restart:
		_challenge_controller.restart_session()
	else:
		_challenge_controller.start_session()
	_apply_seed(_challenge_controller.get_seed_entries())
	_last_player_position = _player.global_position if _player else Vector2.ZERO
	if _challenge_summary_panel:
		_challenge_summary_panel.visible = false
	var advance_state: Dictionary = _challenge_controller.advance_to_next_order()
	_update_ticket_indicator(advance_state.get("next_order", null))
	if advance_state.get("completed", false):
		_handle_challenge_completion(advance_state.get("best_results_dirty", false))
	_update_overlay_label()

func _seed_items() -> void:
	_clear_spawned_items()
	for entry in _seed_entries:
		var slot: WardrobeSlot = _slot_lookup.get(entry.get("slot_id", ""), null)
		if slot == null:
			push_warning("Seed slot missing: %s" % entry.get("slot_id", ""))
			continue
		var item := ITEM_SCENE.instantiate() as ItemNode
		item.item_id = entry.get("item_id", "")
		item.item_type = _resolve_item_type(entry.get("item_type", "COAT"))
		_apply_item_visuals(item, entry.get("color", null))
		var instance := _make_item_instance(item)
		var slot_name := StringName(slot.get_slot_identifier())
		if not _storage_state.has_slot(slot_name):
			_storage_state.register_slot(slot_name)
		var put_result := _storage_state.put(slot_name, instance)
		if not put_result.get(WardrobeStorageStateScript.RESULT_KEY_SUCCESS, false):
			if put_result.get(WardrobeStorageStateScript.RESULT_KEY_REASON) == WardrobeStorageStateScript.REASON_SLOT_MISSING:
				_storage_state.register_slot(slot_name)
				put_result = _storage_state.put(slot_name, instance)
		if not put_result.get(WardrobeStorageStateScript.RESULT_KEY_SUCCESS, false):
			push_warning("Failed to register seed item %s in slot %s: %s" % [
				item.item_id,
				slot.get_slot_identifier(),
				put_result.get(WardrobeStorageStateScript.RESULT_KEY_REASON, "unknown"),
			])
			item.queue_free()
			continue
		if slot.put_item(item):
			_spawned_items.append(item)
			_item_nodes[instance.id] = item

func _clear_spawned_items() -> void:
	for slot in _slots:
		slot.clear_item(false)
	for item in _spawned_items:
		if is_instance_valid(item):
			item.queue_free()
	_spawned_items.clear()
	_item_nodes.clear()
	_hand_item_instance = null
	if _storage_state == null:
		_storage_state = WardrobeStorageStateScript.new()
	else:
		_storage_state.clear()
	_register_storage_slots()
	_active_ticket_item = null

func _apply_seed(entries: Array) -> void:
	_seed_entries = entries.duplicate(true)
	if _player:
		_player.reset_state()
	_reset_storage_state()
	_seed_items()
	_validate_world()
	_interaction_tick = 0
	if _challenge_controller:
		_challenge_controller.clear_shift_log()

func _handle_challenge_completion(best_results_dirty: bool) -> void:
	_show_summary_panel()
	var summary: Dictionary = _challenge_controller.get_summary_snapshot()
	var challenge_id: String = _challenge_controller.get_challenge_id()
	print(
		"CHALLENGE COMPLETED id=%s time=%s actions=%d picks=%d puts=%d swaps=%d distance=%.2f attempts=%d"
		% [
			challenge_id,
			_format_time(float(summary.get("elapsed", 0.0))),
			int(summary.get("actions", 0)),
			int(summary.get("picks", 0)),
			int(summary.get("puts", 0)),
			int(summary.get("swaps", 0)),
			float(summary.get("distance", 0.0)),
			int(summary.get("attempts", 0)),
		]
	)
	if best_results_dirty:
		if challenge_provider:
			challenge_provider.save_best_results(_challenge_controller.get_best_results())
		_challenge_controller.mark_best_results_saved()

func _update_ticket_indicator(order: Variant) -> void:
	if _desk_slot == null:
		return
	if typeof(order) != TYPE_DICTIONARY:
		return
	_clear_slot_item(_desk_slot)
	var order_dict: Dictionary = order as Dictionary
	var ticket_item := ITEM_SCENE.instantiate() as ItemNode
	var order_index: int = max(_challenge_controller.get_current_order_index(), 0)
	ticket_item.item_id = order_dict.get("ticket_id", "order_ticket_%02d" % order_index)
	ticket_item.item_type = ItemNode.ItemType.TICKET
	_apply_item_visuals(ticket_item, order_dict.get("color", Color.WHITE))
	var instance := _make_item_instance(ticket_item)
	var slot_name := StringName(_desk_slot.get_slot_identifier())
	if not _storage_state.has_slot(slot_name):
		_storage_state.register_slot(slot_name)
	var put_result := _storage_state.put(slot_name, instance)
	if not put_result.get(WardrobeStorageStateScript.RESULT_KEY_SUCCESS, false):
		if put_result.get(WardrobeStorageStateScript.RESULT_KEY_REASON) == WardrobeStorageStateScript.REASON_SLOT_MISSING:
			_storage_state.register_slot(slot_name)
			put_result = _storage_state.put(slot_name, instance)
	if not put_result.get(WardrobeStorageStateScript.RESULT_KEY_SUCCESS, false):
		push_warning("Failed to place ticket in storage: %s" % put_result.get(
			WardrobeStorageStateScript.RESULT_KEY_REASON,
			"unknown"
		))
		ticket_item.queue_free()
		return
	if _desk_slot.put_item(ticket_item):
		_active_ticket_item = ticket_item
		_item_nodes[instance.id] = ticket_item
	else:
		ticket_item.queue_free()
		_storage_state.pick(StringName(_desk_slot.get_slot_identifier()))

func _handle_challenge_post_interact(slot: WardrobeSlot) -> void:
	if slot == null:
		return
	if not _challenge_controller.is_active():
		return
	_handle_challenge_delivery(slot)

func _handle_challenge_delivery(slot: WardrobeSlot) -> void:
	var slot_id := slot.get_slot_identifier()
	if not _challenge_controller.is_current_target_slot(slot_id):
		return
	var slot_item := slot.get_item()
	if slot_item == null:
		return
	var current_order: Dictionary = _challenge_controller.get_current_order()
	if current_order.is_empty():
		return
	if not _does_item_match_order(slot_item, current_order):
		return
	var delivered := slot.take_item()
	if delivered:
		_spawned_items.erase(delivered)
		if is_instance_valid(delivered):
			delivered.queue_free()
		_item_nodes.erase(StringName(delivered.item_id))
		_storage_state.pick(slot_id)
	var order_index: int = _challenge_controller.get_current_order_index()
	print(
		"DELIVER item=%s target=%s order_index=%d"
		% [slot_item.item_id, slot_id, order_index]
	)
	var advance_state: Dictionary = _challenge_controller.advance_to_next_order()
	if advance_state.get("completed", false):
		_clear_ticket_indicator()
		_handle_challenge_completion(advance_state.get("best_results_dirty", false))
	else:
		_update_ticket_indicator(advance_state.get("next_order", null))
	_update_overlay_label()

func _clear_ticket_indicator() -> void:
	if _active_ticket_item == null:
		return
	if not is_instance_valid(_active_ticket_item):
		_active_ticket_item = null
		return
	var cleared_slot_id: StringName
	for slot in _slots:
		if slot.get_item() == _active_ticket_item:
			var _unused := slot.take_item()
			cleared_slot_id = StringName(slot.get_slot_identifier())
			break
	if _player and _player.get_active_hand_item() == _active_ticket_item:
		var held := _player.take_item_from_hand()
		if held and held != _active_ticket_item:
			_player.hold_item(held)
		else:
			_hand_item_instance = null
	_active_ticket_item.queue_free()
	_item_nodes.erase(StringName(_active_ticket_item.item_id))
	if cleared_slot_id != StringName():
		_storage_state.pick(cleared_slot_id)
	_active_ticket_item = null

func _clear_slot_item(slot: WardrobeSlot) -> void:
	if slot == null:
		return
	var slot_item := slot.get_item()
	if slot_item == null:
		return
	var slot_id := StringName(slot.get_slot_identifier())
	var removed := slot.take_item()
	if removed and is_instance_valid(removed):
		_item_nodes.erase(StringName(removed.item_id))
		removed.queue_free()
	if _storage_state and _storage_state.has_slot(slot_id):
		_storage_state.pick(slot_id)

func _materialize_missing_seed_items() -> void:
	if _seed_entries.is_empty():
		return
	for entry in _seed_entries:
		var slot_id_text: String = str(entry.get("slot_id", ""))
		if slot_id_text.is_empty():
			continue
		var slot: WardrobeSlot = _slot_lookup.get(slot_id_text, null)
		if slot == null:
			continue
		if slot.has_item():
			continue
		var item := ITEM_SCENE.instantiate() as ItemNode
		item.item_id = entry.get("item_id", "")
		item.item_type = _resolve_item_type(entry.get("item_type", "COAT"))
		_apply_item_visuals(item, entry.get("color", null))
		var instance := _make_item_instance(item)
		var slot_name := StringName(slot.get_slot_identifier())
		if not _storage_state.has_slot(slot_name):
			_storage_state.register_slot(slot_name)
		var put_result := _storage_state.put(slot_name, instance)
		if put_result.get(WardrobeStorageStateScript.RESULT_KEY_SUCCESS, false) and slot.put_item(item):
			_item_nodes[instance.id] = item
		else:
			item.queue_free()
	if _desk_slot and not _desk_slot.has_item():
		var ticket_item := ITEM_SCENE.instantiate() as ItemNode
		ticket_item.item_id = "seed_ticket"
		ticket_item.item_type = ItemNode.ItemType.TICKET
		_apply_item_visuals(ticket_item, Color.WHITE)
		var slot_name := StringName(_desk_slot.get_slot_identifier())
		if not _storage_state.has_slot(slot_name):
			_storage_state.register_slot(slot_name)
		_storage_state.put(slot_name, _make_item_instance(ticket_item))
		_desk_slot.put_item(ticket_item)

func _does_item_match_order(item: ItemNode, order: Dictionary) -> bool:
	if item == null:
		return false
	var target_item_id := str(order.get("item_id", ""))
	if not target_item_id.is_empty() and item.item_id == target_item_id:
		return true
	var expected_type := _resolve_item_type(order.get("item_type", ItemNode.ItemType.COAT))
	if item.item_type != expected_type:
		return false
	var order_color: Variant = order.get("color", null)
	if order_color == null:
		return true
	var sprite := item.get_node_or_null("Sprite") as Sprite2D
	if sprite == null:
		return false
	var current_color := sprite.modulate
	var expected_color := _parse_color(order_color)
	return (
		is_equal_approx(current_color.r, expected_color.r)
		and is_equal_approx(current_color.g, expected_color.g)
		and is_equal_approx(current_color.b, expected_color.b)
	)

func _update_move_distance() -> void:
	if _player == null:
		return
	var current_pos := _player.global_position
	if _last_player_position == Vector2.ZERO:
		_last_player_position = current_pos
		return
	_challenge_controller.add_move_distance(_last_player_position.distance_to(current_pos))
	_last_player_position = current_pos

func _update_overlay_label() -> void:
	if _challenge_overlay_label == null:
		return
	var overlay: Dictionary = _challenge_controller.get_overlay_snapshot()
	if not overlay.get("visible", false):
		_challenge_overlay_label.visible = false
		return
	_challenge_overlay_label.visible = true
	var time_text: String = _format_time(float(overlay.get("elapsed", 0.0)))
	var actions: int = int(overlay.get("actions", 0))
	var state := str(overlay.get("state", "ready"))
	if state == "completed":
		_challenge_overlay_label.text = "Solved %s | Actions %d" % [
			time_text,
			actions,
		]
	elif state == "active":
		_challenge_overlay_label.text = "%s | Actions %d" % [
			time_text,
			actions,
		]
	else:
		_challenge_overlay_label.text = "Ready | Actions %d" % actions

func _show_summary_panel() -> void:
	if _challenge_summary_panel == null:
		return
	_challenge_summary_panel.visible = true
	var summary: Dictionary = _challenge_controller.get_summary_snapshot()
	if _summary_time_label:
		_summary_time_label.text = _format_time(float(summary.get("elapsed", 0.0)))
	if _summary_actions_label:
		_summary_actions_label.text = str(summary.get("actions", 0))
	if _summary_picks_label:
		_summary_picks_label.text = str(summary.get("picks", 0))
	if _summary_puts_label:
		_summary_puts_label.text = str(summary.get("puts", 0))
	if _summary_swaps_label:
		_summary_swaps_label.text = str(summary.get("swaps", 0))
	if _summary_move_label:
		_summary_move_label.text = "%.0f px" % float(summary.get("distance", 0.0))
	if _summary_attempts_label:
		_summary_attempts_label.text = str(summary.get("attempts", 0))
	var best_summary: Array = []
	var best_data_variant: Variant = summary.get("best_data", {})
	var best_data: Dictionary = best_data_variant if best_data_variant is Dictionary else {}
	if best_data.has("best_time"):
		best_summary.append("Best Time %s" % _format_time(float(best_data["best_time"])))
	if best_data.has("best_actions"):
		best_summary.append("Best Actions %d" % int(best_data["best_actions"]))
	if _summary_best_label:
		if best_summary.is_empty():
			_summary_best_label.text = "Best: -"
		else:
			_summary_best_label.text = "Best: %s" % ", ".join(best_summary)

func _format_time(seconds: float) -> String:
	var total_seconds := int(round(seconds))
	var mins := int(floor(float(total_seconds) / 60.0))
	var secs := total_seconds - mins * 60
	return "%02d:%02d" % [mins, secs]

func _reset_world() -> void:
	if step3_enabled:
		_initialize_step3()
		return
	if _challenge_controller.is_enabled():
		_start_challenge_session(true)
		return
	if _player:
		_player.reset_state()
	if challenge_provider == null:
		return
	_seed_entries = challenge_provider.load_seed_entries()
	_apply_seed(_seed_entries)
	_last_player_position = _player.global_position if _player else Vector2.ZERO

func _perform_interact() -> void:
	if _player == null:
		return
	var slot := _find_best_slot()
	if slot == null:
		print("NO ACTION reason=no_slot slot=none")
		if _challenge_controller:
			_challenge_controller.record_interaction_event({}, false, "no_slot", "none")
		_validate_world()
		return
	var slot_id := StringName(slot.get_slot_identifier())
	var hand_item_instance := _hand_item_instance
	var slot_item_instance := _storage_state.get_slot_item(slot_id)
	var command := WardrobeInteractionCommandScript.build(
		WardrobeInteractionCommandScript.TYPE_AUTO,
		_interaction_tick,
		slot_id,
		str(hand_item_instance.id) if hand_item_instance else "",
		str(slot_item_instance.id) if slot_item_instance else ""
	)
	_interaction_tick += 1
	var exec_result: Dictionary = _interaction_engine.process_command(command, _storage_state, hand_item_instance)
	var events: Array = exec_result.get(WardrobeInteractionEngine.RESULT_KEY_EVENTS, [])
	_event_adapter.emit_events(events)
	_hand_item_instance = exec_result.get(WardrobeInteractionEngine.RESULT_KEY_HAND_ITEM)
	if step3_enabled:
		_process_desk_events(events)
	var action: String = str(exec_result.get(WardrobeInteractionEngine.RESULT_KEY_ACTION, PickPutSwapResolverScript.ACTION_NONE))
	if exec_result.get(WardrobeInteractionEngine.RESULT_KEY_SUCCESS, false):
		command[WardrobeInteractionCommandScript.KEY_TYPE] = _resolve_command_type(action)
		if _challenge_controller.is_active():
			_challenge_controller.register_action_result(action)
		var slot_label := slot.get_slot_identifier()
		var held := _player.get_active_hand_item()
		var item_name := held.item_id if held else (slot.get_item().item_id if slot.get_item() else "none")
		print("%s item=%s slot=%s" % [action, item_name, slot_label])
		_handle_challenge_post_interact(slot)
		_record_interaction_event(
			command,
			true,
			str(exec_result.get(WardrobeInteractionEngine.RESULT_KEY_REASON, "")),
			slot_label
		)
	else:
		print(
			"NO ACTION reason=%s slot=%s" % [
				exec_result.get(WardrobeInteractionEngine.RESULT_KEY_REASON, "unknown"),
				slot.get_slot_identifier(),
			]
		)
		_record_interaction_event(
			command,
			false,
			str(exec_result.get(WardrobeInteractionEngine.RESULT_KEY_REASON, "unknown")),
			slot.get_slot_identifier()
		)
	_validate_world()

func _record_interaction_event(command: Dictionary, success: bool, reason: String, slot_id: String) -> void:
	if _challenge_controller == null:
		return
	_challenge_controller.record_interaction_event(command, success, reason, slot_id)

func _process_desk_events(events: Array) -> void:
	if _desk_states.is_empty():
		return
	for event_data in events:
		var payload: Dictionary = event_data.get(WardrobeInteractionEngine.EVENT_KEY_PAYLOAD, {})
		var slot_id: StringName = StringName(str(payload.get(WardrobeInteractionEngine.PAYLOAD_SLOT_ID, "")))
		if slot_id == StringName():
			continue
		var desk_state: RefCounted = _desk_by_slot_id.get(slot_id, null)
		if desk_state == null:
			continue
		var desk_events: Array = _desk_system.process_interaction_event(
			desk_state,
			_clients,
			_storage_state,
			event_data
		)
		_apply_desk_events(desk_events)

func _apply_desk_events(events: Array) -> void:
	for event_data in events:
		var event_type: StringName = event_data.get(DeskServicePointSystemScript.EVENT_KEY_TYPE, StringName())
		var payload: Dictionary = event_data.get(DeskServicePointSystemScript.EVENT_KEY_PAYLOAD, {})
		match event_type:
			DeskServicePointSystemScript.EVENT_DESK_CONSUMED_ITEM:
				_apply_desk_consumed(payload)
			DeskServicePointSystemScript.EVENT_DESK_SPAWNED_ITEM:
				_apply_desk_spawned(payload)
			DeskServicePointSystemScript.EVENT_CLIENT_PHASE_CHANGED:
				_debug_desk_event("client_phase_changed", payload)
			DeskServicePointSystemScript.EVENT_CLIENT_COMPLETED:
				_debug_desk_event("client_completed", payload)
			DeskServicePointSystemScript.EVENT_DESK_PHASE_CHANGED:
				_debug_desk_event("desk_phase_changed", payload)
			DeskServicePointSystemScript.EVENT_DESK_REJECTED_DELIVERY:
				_debug_desk_event("desk_rejected_delivery", payload)

func _apply_desk_consumed(payload: Dictionary) -> void:
	var item_id: StringName = StringName(str(payload.get(DeskServicePointSystemScript.PAYLOAD_ITEM_INSTANCE_ID, "")))
	if item_id == StringName():
		return
	var node: ItemNode = _item_nodes.get(item_id, null)
	if node == null:
		return
	_detach_item_node(node)
	_item_nodes.erase(item_id)
	node.queue_free()

func _apply_desk_spawned(payload: Dictionary) -> void:
	var desk_id: StringName = StringName(str(payload.get(DeskServicePointSystemScript.PAYLOAD_DESK_ID, "")))
	var item_id: StringName = StringName(str(payload.get(DeskServicePointSystemScript.PAYLOAD_ITEM_INSTANCE_ID, "")))
	if desk_id == StringName() or item_id == StringName():
		return
	var desk_state: RefCounted = _desk_by_id.get(desk_id, null)
	if desk_state == null:
		return
	var instance := _find_item_instance(item_id)
	if instance == null:
		return
	_spawn_or_move_item_node(desk_state.desk_slot_id, instance)

func _debug_desk_event(label: String, payload: Dictionary) -> void:
	print("DeskEvent %s %s" % [label, payload])

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
	var best_slot: WardrobeSlot = null
	var best_distance := INF
	var best_dot := -INF
	for slot in _slots:
		var distance := origin.distance_to(slot.global_position)
		if distance > radius:
			continue
		var direction := (slot.global_position - origin).normalized()
		var slot_dot := direction.dot(_player.get_last_move_dir())
		if best_slot == null or distance < best_distance - 0.001:
			best_slot = slot
			best_distance = distance
			best_dot = slot_dot
			continue
		if abs(distance - best_distance) <= DISTANCE_TIE_THRESHOLD:
			if slot_dot > best_dot + 0.001 or (is_equal_approx(slot_dot, best_dot) and slot.name < best_slot.name):
				best_slot = slot
				best_distance = distance
				best_dot = slot_dot
	return best_slot

func _validate_world() -> void:
	var issues: Array = []
	var item_locations := {}
	for slot in _slots:
		var slot_item := slot.get_item()
		if slot_item:
			if item_locations.has(slot_item):
				issues.append(
					"Item %s duplicated between %s and %s" % [
						slot_item.item_id,
						item_locations[slot_item],
						slot.get_slot_identifier(),
					]
				)
			else:
				item_locations[slot_item] = slot.get_slot_identifier()
	var hand_item := _player.get_active_hand_item()
	if hand_item:
		if item_locations.has(hand_item):
			issues.append("Item %s exists in slot and hand" % hand_item.item_id)
		else:
			item_locations[hand_item] = "hand"
	if issues.size() > 0:
		for issue in issues:
			push_error("Wardrobe integrity violation: %s" % issue)

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

func _spawn_or_move_item_node(slot_id: StringName, instance: ItemInstance) -> void:
	var slot: WardrobeSlot = _slot_lookup.get(str(slot_id), null)
	if slot == null or instance == null:
		return
	var node: ItemNode = _item_nodes.get(instance.id, null)
	if node == null:
		node = ITEM_SCENE.instantiate() as ItemNode
		node.item_id = str(instance.id)
		node.item_type = _resolve_item_type_from_kind(instance.kind)
		_apply_item_visuals(node, instance.color)
		_item_nodes[instance.id] = node
		_spawned_items.append(node)
	else:
		_apply_item_visuals(node, instance.color)
	_detach_item_node(node)
	slot.put_item(node)

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

func _apply_item_visuals(item: ItemNode, tint: Variant) -> void:
	var sprite := item.get_node_or_null("Sprite") as Sprite2D
	if sprite:
		var texture := _get_item_texture(item.item_type)
		if texture:
			sprite.texture = texture
		if tint == null:
			sprite.modulate = Color.WHITE
		else:
			sprite.modulate = _parse_color(tint)

func _get_item_texture(item_type: int) -> Texture2D:
	var paths: Array = ITEM_TEXTURE_PATHS.get(item_type, ITEM_TEXTURE_PATHS[ItemNode.ItemType.COAT])
	for path in paths:
		if ResourceLoader.exists(path, "Texture2D"):
			var resource := load(path)
			if resource is Texture2D:
				return resource
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

func _resolve_kind_from_item_type(item_type: int) -> StringName:
	match item_type:
		ItemNode.ItemType.TICKET:
			return ItemInstanceScript.KIND_TICKET
		ItemNode.ItemType.ANCHOR_TICKET:
			return ItemInstanceScript.KIND_ANCHOR_TICKET
		_:
			return ItemInstanceScript.KIND_COAT

func _resolve_item_type_from_kind(kind: StringName) -> ItemNode.ItemType:
	match kind:
		ItemInstanceScript.KIND_TICKET:
			return ItemNode.ItemType.TICKET
		ItemInstanceScript.KIND_ANCHOR_TICKET:
			return ItemNode.ItemType.ANCHOR_TICKET
		_:
			return ItemNode.ItemType.COAT

func _make_item_instance(item: ItemNode) -> ItemInstance:
	var color := _get_item_color(item)
	return ItemInstanceScript.new(
		StringName(item.item_id),
		_resolve_kind_from_item_type(item.item_type),
		color
	)

func _instance_from_snapshot(snapshot: Dictionary) -> ItemInstance:
	var id: StringName = snapshot.get("id", StringName())
	var kind: StringName = snapshot.get("kind", ItemInstanceScript.KIND_COAT)
	var color_variant: Variant = snapshot.get("color", Color.WHITE)
	var color := _parse_color(color_variant)
	return ItemInstanceScript.new(id, kind, color)

func _parse_color(value: Variant) -> Color:
	match typeof(value):
		TYPE_COLOR:
			return value
		TYPE_STRING:
			return Color.from_string(value, Color.WHITE)
		TYPE_ARRAY:
			var components := value as Array
			if components.size() >= 3:
				var r := float(components[0])
				var g := float(components[1])
				var b := float(components[2])
				var a := float(components[3]) if components.size() >= 4 else 1.0
				return Color(r, g, b, a)
	return Color.WHITE

func _get_item_color(item: ItemNode) -> Color:
	var sprite := item.get_node_or_null("Sprite") as Sprite2D
	if sprite:
		return sprite.modulate
	return Color.WHITE

func _ensure_challenge_provider() -> void:
	if challenge_provider == null:
		challenge_provider = WardrobeChallengeProviderScript.new()
	if challenge_provider:
		if _content_db == null:
			push_warning("ContentDB singleton missing; challenge data may not load.")
		else:
			challenge_provider.set_content_db(_content_db)
		challenge_provider.ensure_ready()

func _on_event_item_picked(slot_id: StringName, item: Dictionary, _tick: int) -> void:
	var slot: WardrobeSlot = _slot_lookup.get(str(slot_id), null)
	var node: ItemNode = slot.take_item() if slot else null
	var item_id: StringName = item.get("id", StringName())
	if node == null:
		node = _item_nodes.get(item_id, null)
	if node and _player:
		_player.hold_item(node)
	_hand_item_instance = _instance_from_snapshot(item)

func _on_event_item_placed(slot_id: StringName, item: Dictionary, _tick: int) -> void:
	var slot: WardrobeSlot = _slot_lookup.get(str(slot_id), null)
	var node: ItemNode = _player.take_item_from_hand() if _player else null
	var item_id: StringName = item.get("id", StringName())
	if node == null:
		node = _item_nodes.get(item_id, null)
	if slot and node:
		slot.put_item(node)
	_hand_item_instance = null

func _on_event_item_swapped(
	slot_id: StringName,
	_incoming_item: Dictionary,
	outgoing_item: Dictionary,
	_tick: int
) -> void:
	var slot: WardrobeSlot = _slot_lookup.get(str(slot_id), null)
	var slot_outgoing: ItemNode = slot.take_item() if slot else null
	var incoming_node: ItemNode = _player.take_item_from_hand() if _player else null
	if slot and incoming_node:
		slot.put_item(incoming_node)
	if slot_outgoing and _player:
		_player.hold_item(slot_outgoing)
	_hand_item_instance = _instance_from_snapshot(outgoing_item)

func _on_event_action_rejected(_slot_id: StringName, _reason: StringName, _tick: int) -> void:
	pass
