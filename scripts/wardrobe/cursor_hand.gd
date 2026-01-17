class_name CursorHand
extends Node2D

const PhysicsLayers := preload("res://scripts/wardrobe/config/physics_layers.gd")
const DebugLog := preload("res://scripts/wardrobe/debug/debug_log.gd")

@export var small_scale: Vector2 = Vector2(0.7, 0.7)
@export var big_scale: Vector2 = Vector2.ONE
@export var preview_duration: float = 0.1
@export var follow_offset: Vector2 = Vector2.ZERO
@export var warning_offset: Vector2 = Vector2(0, -50)

var _hand_item: ItemNode
var _scale_tween: Tween
var _shake_tween: Tween
var _gravity_line: Line2D
var _cog_marker: ColorRect
var _warning_icon: Polygon2D
var _physics_tick
var _default_modulate := Color.WHITE

func _ready() -> void:
	_setup_feedback_nodes()

func _process(_delta: float) -> void:
	global_position = get_global_mouse_position() + follow_offset
	_update_drag_feedback()

func hold_item(node: ItemNode) -> void:
	if node == null:
		return
	_hand_item = node
	if node.get_parent():
		node.reparent(self)
	else:
		add_child(node)
	node.position = Vector2.ZERO
	node.rotation = 0.0
	node.scale = big_scale
	node.z_index = 0
	_default_modulate = _get_item_sprite_modulate(node)
	var tick = _resolve_physics_tick()
	if tick:
		tick.set_drag_probe(node)
	_log_debug("hold_item item=%s parent=%s", [node.item_id, _hand_item.get_parent().name])

func take_item_from_hand() -> ItemNode:
	var item := _hand_item
	if item:
		var tick = _resolve_physics_tick()
		if tick:
			tick.clear_drag_probe(item)
	_hand_item = null
	_reset_feedback()
	if item:
		_log_debug("take_item item=%s", [item.item_id])
	return item

func get_active_hand_item() -> ItemNode:
	return _hand_item

func set_preview_small(enabled: bool) -> void:
	if _hand_item == null:
		return
	var target := small_scale if enabled else big_scale
	if _scale_tween and _scale_tween.is_valid():
		_scale_tween.kill()
	_scale_tween = create_tween()
	_scale_tween.tween_property(_hand_item, "scale", target, preview_duration)
	_scale_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _setup_feedback_nodes() -> void:
	_gravity_line = Line2D.new()
	_gravity_line.width = 2.0
	_gravity_line.default_color = Color(0.9, 0.9, 0.9, 0.9)
	_gravity_line.visible = false
	add_child(_gravity_line)
	_cog_marker = ColorRect.new()
	_cog_marker.color = Color(0.9, 0.9, 0.9, 0.9)
	_cog_marker.size = Vector2(4.0, 4.0)
	_cog_marker.visible = false
	add_child(_cog_marker)
	_warning_icon = Polygon2D.new()
	_warning_icon.polygon = PackedVector2Array([
		Vector2(0, 0),
		Vector2(10, 0),
		Vector2(5, -10),
	])
	_warning_icon.color = Color(0.95, 0.2, 0.2, 1.0)
	_warning_icon.visible = false
	add_child(_warning_icon)

func _update_drag_feedback() -> void:
	if _hand_item == null:
		_reset_feedback()
		return
	var cog_local := to_local(_hand_item.get_global_cog())
	_gravity_line.visible = true
	_gravity_line.points = PackedVector2Array([
		cog_local,
		cog_local + Vector2(0.0, _hand_item.get_support_ray_length()),
	])
	_cog_marker.visible = true
	_cog_marker.position = cog_local - _cog_marker.size * 0.5
	_warning_icon.position = warning_offset
	var tick = _resolve_physics_tick()
	var supported: bool = tick.is_drag_probe_supported() if tick else true
	_apply_warning_state(not supported)

func _apply_warning_state(is_warning: bool) -> void:
	_warning_icon.visible = is_warning
	_set_item_modulate(is_warning)
	_update_shake(is_warning)

func _update_shake(_is_warning: bool) -> void:
	if _hand_item == null:
		return
	if _shake_tween and _shake_tween.is_valid():
		_shake_tween.kill()
	_hand_item.position = Vector2.ZERO

func _set_item_modulate(is_warning: bool) -> void:
	var sprite := _hand_item.get_node_or_null("Sprite") as Sprite2D
	if sprite == null:
		return
	if is_warning:
		sprite.modulate = Color(1.0, 0.3, 0.3, 1.0)
	else:
		sprite.modulate = _default_modulate

func _get_item_sprite_modulate(item: ItemNode) -> Color:
	var sprite := item.get_node_or_null("Sprite") as Sprite2D
	if sprite:
		return sprite.modulate
	return Color.WHITE

func _reset_feedback() -> void:
	if _gravity_line:
		_gravity_line.visible = false
	if _cog_marker:
		_cog_marker.visible = false
	if _warning_icon:
		_warning_icon.visible = false
	if _shake_tween and _shake_tween.is_valid():
		_shake_tween.kill()
	if _hand_item:
		_hand_item.position = Vector2.ZERO
		_set_item_modulate(false)


func _resolve_physics_tick():
	if _physics_tick != null and is_instance_valid(_physics_tick):
		return _physics_tick
	var node := get_tree().get_first_node_in_group(PhysicsLayers.GROUP_TICK)
	_physics_tick = node
	return _physics_tick

func _log_debug(format: String, args: Array = []) -> void:
	if not DebugLog.enabled():
		return
	if args.is_empty():
		DebugLog.log("CursorHand %s" % format)
		return
	DebugLog.logf("CursorHand " + format, args)
