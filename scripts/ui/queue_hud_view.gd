extends Control

class_name QueueHudView

const QueueHudSnapshotScript := preload("res://scripts/app/queue/queue_hud_snapshot.gd")
const QueueHudClientVMScript := preload("res://scripts/app/queue/queue_hud_client_vm.gd")
const STATUS_LEAVING_RED := StringName("leaving_red")
const APPEND_QUEUE_PADDING := 16.0
const APPEND_EXTRA_DISTANCE := 200.0
const APPEND_FADE_DURATION := 0.2
const APPEND_MOVE_DURATION := 0.9
const EXIT_MOVE_DISTANCE := 80.0
const EXIT_SCALE_FACTOR := 0.7
const EXIT_DURATION := 0.7

@onready var _queue_items: HBoxContainer = %QueueItems
@onready var _remaining_checkin_label: Label = %RemainingCheckinValue
@onready var _remaining_checkout_label: Label = %RemainingCheckoutValue
@onready var _strikes_label: Label = %QueueStrikesValue

var _items_by_id: Dictionary = {}
var _leaving_ids: Dictionary = {}
var _default_texture: Texture2D = preload("res://assets/sprites/placeholder/slot.png")

func apply_snapshot(snapshot) -> void:
	if snapshot == null:
		return
	_update_kpis(snapshot)
	_sync_items(snapshot.upcoming_clients)

func _update_kpis(snapshot) -> void:
	_remaining_checkin_label.text = "%d" % snapshot.remaining_checkin
	_remaining_checkout_label.text = "%d" % snapshot.remaining_checkout
	_strikes_label.text = "Strikes: %d/%d" % [
		snapshot.strikes_current,
		snapshot.strikes_limit,
	]

func _sync_items(clients: Array) -> void:
	var incoming_ids: Array[StringName] = []
	for vm in clients:
		incoming_ids.append(vm.client_id)
	for existing_id in _items_by_id.keys():
		if incoming_ids.has(existing_id):
			continue
		_remove_item(existing_id, false)
	for vm in clients:
		var item: Control = _items_by_id.get(vm.client_id, null)
		if item == null:
			item = _create_item(vm)
			_queue_items.add_child(item)
			_items_by_id[vm.client_id] = item
			_play_append(item)
		_update_item(item, vm)
		if vm.status == STATUS_LEAVING_RED:
			_play_timeout(vm.client_id, item)

func _create_item(vm) -> Control:
	var wrapper := Control.new()
	wrapper.custom_minimum_size = Vector2(112, 112)
	wrapper.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	wrapper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var content := Control.new()
	content.anchor_right = 1.0
	content.anchor_bottom = 1.0
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.clip_contents = true
	wrapper.add_child(content)
	var bg := ColorRect.new()
	bg.color = Color(0.12, 0.12, 0.12, 0.8)
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(bg)
	var icon := TextureRect.new()
	icon.texture = _resolve_texture(vm.portrait_key)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	icon.anchor_right = 1.0
	icon.anchor_bottom = 1.0
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(icon)
	wrapper.set_meta("content", content)
	wrapper.set_meta("icon", icon)
	
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 10)
	bar.anchor_top = 1.0
	bar.anchor_bottom = 1.0
	bar.anchor_right = 1.0
	bar.offset_top = -15
	bar.offset_bottom = -5
	bar.offset_left = 5
	bar.offset_right = -5
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var style_bg := StyleBoxFlat.new()
	style_bg.bg_color = Color(0.1, 0.1, 0.1, 1.0)
	bar.add_theme_stylebox_override("background", style_bg)
	
	var style_fill := StyleBoxFlat.new()
	style_fill.bg_color = Color(1.0, 1.0, 1.0, 1.0)
	bar.add_theme_stylebox_override("fill", style_fill)
	
	content.add_child(bar)
	wrapper.set_meta("patience_bar", bar)
	
	return wrapper

func _update_item(item: Control, vm) -> void:
	var icon := item.get_meta("icon", null) as TextureRect
	if icon:
		icon.texture = _resolve_texture(vm.portrait_key)
	
	var bar := item.get_meta("patience_bar", null) as ProgressBar
	if bar:
		bar.value = vm.patience_ratio * 100.0
		# Simple color feedback
		if vm.patience_ratio < 0.25:
			bar.modulate = Color(1, 0.3, 0.3) # Red
		elif vm.patience_ratio < 0.5:
			bar.modulate = Color(1, 0.8, 0.2) # Orange/Yellow
		else:
			bar.modulate = Color(0.4, 1, 0.4) # Green

func _remove_item(client_id: StringName, immediate: bool) -> void:
	if _leaving_ids.has(client_id):
		return
	var item: Control = _items_by_id.get(client_id, null)
	if item == null:
		return
	_items_by_id.erase(client_id)
	if immediate:
		item.queue_free()
		return
	_play_queue_exit(client_id, item)

func _play_append(item: Control) -> void:
	call_deferred("_play_append_from_queue_items", item)

func _play_append_from_queue_items(item: Control) -> void:
	if not is_instance_valid(item):
		return
	await get_tree().process_frame
	if not is_instance_valid(item) or _queue_items == null:
		return
	var target_pos := item.global_position
	var items_pos := _queue_items.global_position
	var items_right := items_pos.x + _queue_items.size.x
	var start_x := items_right + APPEND_QUEUE_PADDING + APPEND_EXTRA_DISTANCE
	var start_pos := Vector2(start_x, target_pos.y)
	item.set_as_top_level(true)
	item.global_position = start_pos
	item.modulate = Color(1, 1, 1, 0)
	var tween := create_tween().bind_node(item)
	tween.tween_property(item, "modulate:a", 1.0, APPEND_FADE_DURATION)
	tween.tween_property(item, "global_position", target_pos, APPEND_MOVE_DURATION).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func() -> void:
		if is_instance_valid(item):
			item.set_as_top_level(false)
	)

func _play_simple_append(item: Control) -> void:
	var content := item.get_meta("content", null) as Control
	if content == null:
		return
	content.position = Vector2(20, 0)
	item.modulate = Color(1, 1, 1, 0)
	var tween := create_tween().bind_node(item)
	tween.tween_property(item, "modulate:a", 1.0, 0.15)
	tween.tween_property(content, "position", Vector2.ZERO, 0.15)

func _play_timeout(client_id: StringName, item: Control) -> void:
	if _leaving_ids.has(client_id):
		return
	_leaving_ids[client_id] = true
	var tween := create_tween().bind_node(item)
	tween.tween_property(item, "modulate", Color(1.0, 0.3, 0.3, 1.0), 0.1)
	tween.tween_property(item, "modulate:a", 0.0, 0.2)
	tween.tween_callback(func() -> void:
		_items_by_id.erase(client_id)
		item.queue_free()
		_leaving_ids.erase(client_id)
	)

func _play_queue_exit(client_id: StringName, item: Control) -> void:
	if _leaving_ids.has(client_id):
		return
	_leaving_ids[client_id] = true
	var start_pos := item.global_position
	var end_pos := start_pos + Vector2(0.0, EXIT_MOVE_DISTANCE)
	var start_scale := item.scale
	var end_scale := start_scale * EXIT_SCALE_FACTOR
	item.set_as_top_level(true)
	item.global_position = start_pos
	var tween := create_tween().bind_node(item)
	tween.tween_property(item, "global_position", end_pos, EXIT_DURATION).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(item, "scale", end_scale, EXIT_DURATION).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(item, "modulate:a", 0.0, EXIT_DURATION)
	tween.tween_callback(func() -> void:
		if is_instance_valid(item):
			item.queue_free()
		_leaving_ids.erase(client_id)
	)

func _resolve_texture(portrait_key: StringName) -> Texture2D:
	if portrait_key == StringName():
		return _default_texture
	var key_text := String(portrait_key)
	if key_text.begins_with("res://"):
		if ResourceLoader.exists(key_text):
			return load(key_text)
	var candidate := "res://assets/portraits/%s.png" % key_text
	if ResourceLoader.exists(candidate):
		return load(candidate)
	return _default_texture
