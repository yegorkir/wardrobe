class_name ItemNode
extends RigidBody2D

const PhysicsLayers := preload("res://scripts/wardrobe/config/physics_layers.gd")

enum ItemType {
	COAT,
	TICKET,
	ANCHOR_TICKET,
	BOTTLE,
	CHEST,
	HAT,
}

const DEFAULT_MASS_BY_TYPE: Dictionary = {
	ItemType.COAT: 1.2,
	ItemType.TICKET: 0.5,
	ItemType.ANCHOR_TICKET: 0.7,
	ItemType.BOTTLE: 0.6,
	ItemType.CHEST: 3.0,
	ItemType.HAT: 0.6,
}

enum State {
	STABLE,
	DRAGGING,
	SETTLING,
}

const COLLISION_PADDING := 2.0
const SETTLE_LINEAR_THRESHOLD := 6.0
const SETTLE_ANGULAR_THRESHOLD := 0.4
const SETTLE_REQUIRED_TIME := 1.0
const SUPPORT_RAY_LENGTH := 48.0
const SETTLE_GRACE_FRAMES := 2
const DEFAULT_COLLISION_LAYER := PhysicsLayers.LAYER_ITEM_BIT
const DEFAULT_COLLISION_MASK := PhysicsLayers.MASK_ITEM_DEFAULT
const PASS_THROUGH_PICK_SCALE := 1.6

@export var item_id: String = ""
@export var item_type: ItemType = ItemType.COAT
@export var item_mass: float = 0.0
@export var cog_offset: Vector2 = Vector2.ZERO
@export var debug_log: bool = false

var ticket_number: int = -1
var durability: float = 100.0

@onready var _pick_shape: CollisionShape2D = $PickArea/CollisionShape2D
@onready var _sprite: Sprite2D = $Sprite
@onready var _physics_shape: CollisionShape2D = get_node_or_null("PhysicsShape") as CollisionShape2D

var _physics_tick
var _settle_time := 0.0
var _is_dragging := false
var _state: int = State.STABLE
var _settle_grace_frames := 0
var _pass_through_active := false
var _pass_through_until_y := 0.0
var _pass_through_restore_layer := 0
var _pass_through_restore_mask := 0
var _pick_default_size := Vector2.ZERO
var _reject_falling := false
var current_surface: Node

const PASS_THROUGH_RESTORE_EPS := 0.5

func _ready() -> void:
	contact_monitor = true
	max_contacts_reported = 8
	freeze = true
	freeze_mode = FREEZE_MODE_KINEMATIC
	_apply_mass_defaults()
	mass = maxf(0.1, item_mass)
	collision_layer = DEFAULT_COLLISION_LAYER
	collision_mask = DEFAULT_COLLISION_MASK
	_prepare_pick_area()
	_cache_default_pick_size()
	_prepare_physics_shape()
	_apply_physics_material()
	_update_center_of_mass()
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	if _pass_through_active:
		if get_bottom_y_global() >= _pass_through_until_y - PASS_THROUGH_RESTORE_EPS:
			_restore_pass_through()
	if freeze or _is_dragging:
		_settle_time = 0.0
		return
	if _settle_grace_frames > 0:
		_settle_grace_frames -= 1
		return
	if abs(linear_velocity.length()) <= SETTLE_LINEAR_THRESHOLD and abs(angular_velocity) <= SETTLE_ANGULAR_THRESHOLD:
		_settle_time += delta
		if _settle_time >= SETTLE_REQUIRED_TIME:
			_settle_time = 0.0
			var tick = _resolve_physics_tick()
			if tick:
				tick.request_settle_check(self)
	else:
		_settle_time = 0.0

func attach_to_anchor(anchor: Node2D) -> void:
	if anchor == null:
		return
	if get_parent():
		reparent(anchor)
	else:
		anchor.add_child(self)
	global_position = anchor.global_position
	global_rotation = 0.0
	global_scale = Vector2.ONE
	position = Vector2.ZERO

func get_pick_half_width() -> float:
	if _pick_shape and _pick_shape.shape is RectangleShape2D:
		return (_pick_shape.shape as RectangleShape2D).size.x * 0.5
	if _pick_shape and _pick_shape.shape is CircleShape2D:
		return (_pick_shape.shape as CircleShape2D).radius
	return 16.0

func get_pick_half_height() -> float:
	if _pick_shape and _pick_shape.shape is RectangleShape2D:
		return (_pick_shape.shape as RectangleShape2D).size.y * 0.5
	if _pick_shape and _pick_shape.shape is CircleShape2D:
		return (_pick_shape.shape as CircleShape2D).radius
	return 16.0

func configure_pick_box(size_px: float) -> void:
	if _pick_shape == null:
		return
	var rect_shape := _pick_shape.shape as RectangleShape2D
	if rect_shape == null:
		return
	rect_shape.size = Vector2(size_px, size_px)

func configure_pick_box_from_sprite() -> void:
	if _sprite == null or _sprite.texture == null:
		return
	if _pick_shape == null:
		return
	var rect_shape := _pick_shape.shape as RectangleShape2D
	if rect_shape == null:
		return
	var size := _sprite.texture.get_size() * _sprite.scale
	rect_shape.size = size

func refresh_physics_shape_from_sprite() -> void:
	if _physics_shape == null or _physics_shape.shape == null:
		return
	if _physics_shape.shape is RectangleShape2D:
		var rect := _physics_shape.shape as RectangleShape2D
		var size := _resolve_sprite_size()
		if size != Vector2.ZERO:
			rect.size = Vector2(maxf(2.0, size.x - COLLISION_PADDING), maxf(2.0, size.y - COLLISION_PADDING))
			_update_center_of_mass()

func get_visual_half_width() -> float:
	if _sprite == null or _sprite.texture == null:
		return get_pick_half_width()
	return _sprite.texture.get_size().x * _sprite.scale.x * 0.5

func get_visual_half_height() -> float:
	if _sprite == null or _sprite.texture == null:
		return get_pick_half_height()
	return _sprite.texture.get_size().y * _sprite.scale.y * 0.5

func get_global_cog() -> Vector2:
	return global_transform * center_of_mass

func get_support_ray_length() -> float:
	return SUPPORT_RAY_LENGTH

func get_physics_shape_query() -> Dictionary:
	if _physics_shape == null:
		return {}
	if _physics_shape.shape == null:
		return {}
	return {
		"shape": _physics_shape.shape,
		"transform": _physics_shape.global_transform,
	}

func get_global_bottom_y() -> float:
	return get_bottom_y_global()

func get_collider_aabb_global() -> Rect2:
	if _physics_shape == null or _physics_shape.shape == null:
		return _get_sprite_aabb()
	var shape := _physics_shape.shape as Shape2D
	var shape_transform := _physics_shape.global_transform
	return _get_shape_aabb(shape, shape_transform)

func get_bottom_y_global() -> float:
	var rect := get_collider_aabb_global()
	if rect.size != Vector2.ZERO:
		return rect.position.y + rect.size.y
	return global_position.y + get_visual_half_height()

func snap_to_surface(hit_position: Vector2, epsilon: float) -> void:
	if not freeze:
		return
	var bottom_y := get_bottom_y_global()
	var delta := hit_position.y - bottom_y
	if abs(delta) <= epsilon:
		global_position.y += delta

func snap_bottom_to_y(target_y: float) -> void:
	global_position.y += target_y - get_bottom_y_global()

func force_snap_bottom_to_y(target_y: float) -> void:
	snap_bottom_to_y(target_y)

func enter_drag_mode() -> void:
	_is_dragging = true
	_clear_pass_through()
	freeze = true
	freeze_mode = FREEZE_MODE_KINEMATIC
	collision_layer = 0
	collision_mask = 0
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	_state = State.DRAGGING

func exit_drag_mode() -> void:
	_is_dragging = false
	collision_layer = DEFAULT_COLLISION_LAYER
	collision_mask = DEFAULT_COLLISION_MASK
	freeze = false
	sleeping = false
	_state = State.SETTLING
	_settle_grace_frames = SETTLE_GRACE_FRAMES

func enable_pass_through_until_y(target_y: float) -> void:
	_start_pass_through(target_y, false)

func start_reject_fall(target_y: float) -> void:
	_start_pass_through(target_y, true)

func _start_pass_through(target_y: float, reject: bool) -> void:
	_pass_through_active = true
	_reject_falling = reject
	_pass_through_until_y = target_y
	_pass_through_restore_layer = collision_layer
	_pass_through_restore_mask = collision_mask
	collision_layer = DEFAULT_COLLISION_LAYER
	collision_mask = PhysicsLayers.MASK_FLOOR_ONLY
	_expand_pick_area()

func _restore_pass_through() -> void:
	_pass_through_active = false
	_pass_through_until_y = 0.0
	collision_layer = _pass_through_restore_layer
	collision_mask = _pass_through_restore_mask
	_restore_pick_area()
	if _reject_falling:
		_reject_falling = false
		_state = State.SETTLING
		_settle_grace_frames = SETTLE_GRACE_FRAMES

func _clear_pass_through() -> void:
	if _pass_through_active:
		collision_layer = _pass_through_restore_layer
		collision_mask = _pass_through_restore_mask
	_pass_through_active = false
	_pass_through_until_y = 0.0
	_reject_falling = false
	_restore_pick_area()

func _prepare_pick_area() -> void:
	var pick_area := $PickArea as Area2D
	if pick_area == null:
		return
	pick_area.collision_layer = PhysicsLayers.LAYER_PICK_AREA_BIT
	pick_area.collision_mask = PhysicsLayers.LAYER_PICK_AREA_BIT
	pick_area.input_pickable = true

func _cache_default_pick_size() -> void:
	if _pick_shape == null:
		return
	if _pick_shape.shape is RectangleShape2D:
		var rect := _pick_shape.shape as RectangleShape2D
		_pick_default_size = rect.size

func _expand_pick_area() -> void:
	if _pick_shape == null:
		return
	if _pick_shape.shape is RectangleShape2D:
		var rect := _pick_shape.shape as RectangleShape2D
		if _pick_default_size == Vector2.ZERO:
			_pick_default_size = rect.size
		rect.size = _pick_default_size * PASS_THROUGH_PICK_SCALE

func _restore_pick_area() -> void:
	if _pick_shape == null:
		return
	if _pick_shape.shape is RectangleShape2D and _pick_default_size != Vector2.ZERO:
		var rect := _pick_shape.shape as RectangleShape2D
		rect.size = _pick_default_size

func _prepare_physics_shape() -> void:
	if _physics_shape == null:
		_physics_shape = CollisionShape2D.new()
		_physics_shape.name = "PhysicsShape"
		add_child(_physics_shape)
	if _physics_shape.shape == null:
		var size := _resolve_sprite_size()
		if size == Vector2.ZERO:
			size = Vector2(32.0, 32.0)
		var rect := RectangleShape2D.new()
		rect.size = Vector2(maxf(2.0, size.x - COLLISION_PADDING), maxf(2.0, size.y - COLLISION_PADDING))
		_physics_shape.shape = rect

func _apply_physics_material() -> void:
	if physics_material_override != null:
		return
	var physics_material := PhysicsMaterial.new()
	physics_material.friction = 0.8
	physics_material.bounce = 0.1
	physics_material_override = physics_material

func _update_center_of_mass() -> void:
	center_of_mass_mode = CENTER_OF_MASS_MODE_CUSTOM
	center_of_mass = _resolve_local_center() + cog_offset

func _apply_mass_defaults() -> void:
	if item_mass > 0.0:
		return
	var default_mass: float = float(DEFAULT_MASS_BY_TYPE.get(item_type, 1.0))
	item_mass = default_mass

func _resolve_sprite_size() -> Vector2:
	if _sprite == null or _sprite.texture == null:
		return Vector2.ZERO
	return _sprite.texture.get_size() * _sprite.scale

func _resolve_local_center() -> Vector2:
	if _physics_shape != null and _physics_shape.shape != null:
		return _physics_shape.position
	return Vector2.ZERO

func _get_sprite_aabb() -> Rect2:
	var half := Vector2(get_visual_half_width(), get_visual_half_height())
	return Rect2(global_position - half, half * 2.0)

func _get_shape_aabb(shape: Shape2D, shape_transform: Transform2D) -> Rect2:
	if shape == null:
		return Rect2()
	if shape is RectangleShape2D:
		var rect := shape as RectangleShape2D
		var half := rect.size * 0.5
		var points := PackedVector2Array([
			Vector2(-half.x, -half.y),
			Vector2(half.x, -half.y),
			Vector2(half.x, half.y),
			Vector2(-half.x, half.y),
		])
		var min_x := INF
		var max_x := -INF
		var min_y := INF
		var max_y := -INF
		for point in points:
			var world := shape_transform * point
			min_x = minf(min_x, world.x)
			max_x = maxf(max_x, world.x)
			min_y = minf(min_y, world.y)
			max_y = maxf(max_y, world.y)
		return Rect2(Vector2(min_x, min_y), Vector2(max_x - min_x, max_y - min_y))
	if shape is CircleShape2D:
		var circle := shape as CircleShape2D
		var center := shape_transform.origin
		var r := circle.radius
		return Rect2(Vector2(center.x - r, center.y - r), Vector2(r * 2.0, r * 2.0))
	return Rect2()


func _resolve_physics_tick():
	if _physics_tick != null and is_instance_valid(_physics_tick):
		return _physics_tick
	var node := get_tree().get_first_node_in_group(PhysicsLayers.GROUP_TICK)
	_physics_tick = node
	return _physics_tick

func _on_body_entered(body: Node) -> void:
	if body == null:
		return
	if _state != State.DRAGGING and _state != State.SETTLING:
		return
	if body is RigidBody2D:
		var other := body as RigidBody2D
		_log_debug("hit by %s pos=%.1f,%.1f vel=%.1f,%.1f" % [
			other.name,
			other.global_position.x,
			other.global_position.y,
			other.linear_velocity.x,
			other.linear_velocity.y,
		])
		call_deferred("_wake_from_hit")
		other.set_deferred("freeze", false)
		other.set_deferred("sleeping", false)

func _wake_from_hit() -> void:
	freeze = false
	sleeping = false
	apply_torque_impulse(randf_range(-2.0, 2.0))
	_log_debug("wake item=%s pos=%.1f,%.1f vel=%.1f,%.1f" % [
		item_id,
		global_position.x,
		global_position.y,
		linear_velocity.x,
		linear_velocity.y,
	])

func _log_debug(message: String) -> void:
	if not debug_log:
		return
	print("[ItemNode] %s" % message)

func is_settling() -> bool:
	return _state == State.SETTLING

func allow_settle() -> bool:
	return _settle_grace_frames <= 0

func mark_stable() -> void:
	_state = State.STABLE

func is_reject_falling() -> bool:
	return _reject_falling

func is_pass_through_active() -> bool:
	return _pass_through_active

func can_register_on_surface() -> bool:
	return not _reject_falling

func set_current_surface(surface: Node) -> void:
	current_surface = surface

func clear_current_surface() -> void:
	current_surface = null
