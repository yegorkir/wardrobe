extends Control

class_name QueueHudView

const QueueHudSnapshotScript := preload("res://scripts/app/queue/queue_hud_snapshot.gd")
const QueueHudClientVMScript := preload("res://scripts/app/queue/queue_hud_client_vm.gd")
const STATUS_LEAVING_RED := StringName("leaving_red")

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
	wrapper.custom_minimum_size = Vector2(42, 42)
	wrapper.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	wrapper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var content := Control.new()
	content.anchor_right = 1.0
	content.anchor_bottom = 1.0
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
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
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.anchor_right = 1.0
	icon.anchor_bottom = 1.0
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(icon)
	wrapper.set_meta("content", content)
	wrapper.set_meta("icon", icon)
	return wrapper

func _update_item(item: Control, vm) -> void:
	var icon := item.get_meta("icon", null) as TextureRect
	if icon:
		icon.texture = _resolve_texture(vm.portrait_key)

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
	var tween := create_tween()
	tween.tween_property(item, "modulate:a", 0.0, 0.15)
	tween.tween_callback(func() -> void: item.queue_free())

func _play_append(item: Control) -> void:
	var content := item.get_meta("content", null) as Control
	if content == null:
		return
	content.position = Vector2(20, 0)
	item.modulate = Color(1, 1, 1, 0)
	var tween := create_tween()
	tween.tween_property(item, "modulate:a", 1.0, 0.15)
	tween.tween_property(content, "position", Vector2.ZERO, 0.15)

func _play_timeout(client_id: StringName, item: Control) -> void:
	if _leaving_ids.has(client_id):
		return
	_leaving_ids[client_id] = true
	var tween := create_tween()
	tween.tween_property(item, "modulate", Color(1.0, 0.3, 0.3, 1.0), 0.1)
	tween.tween_property(item, "modulate:a", 0.0, 0.2)
	tween.tween_callback(func() -> void:
		_items_by_id.erase(client_id)
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
