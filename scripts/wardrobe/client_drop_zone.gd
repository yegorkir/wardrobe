@tool
extends Area2D

class_name ClientDropZone

const GROUP := "sp_client_drop_zone"
const PhysicsLayers := preload("res://scripts/wardrobe/config/physics_layers.gd")
const ItemNodeScript := preload("res://scripts/wardrobe/item_node.gd")
const DebugLog := preload("res://scripts/wardrobe/debug/debug_log.gd")

@export var size: Vector2 = Vector2(120.0, 80.0)
@export var auto_size_sprite_path: NodePath = NodePath()
@export var debug_draw: bool = false
var service_point_id: StringName = StringName()
var service_point_node: Node
var _auto_sprite: Sprite2D

func _ready() -> void:
	add_to_group(GROUP)
	monitoring = true
	monitorable = true
	_apply_collision_settings()
	if debug_draw:
		z_as_relative = false
		z_index = 2000
	_resolve_auto_sprite()
	_apply_auto_size()
	_ensure_shape()
	queue_redraw()

func is_point_inside(global_point: Vector2) -> bool:
	var local := to_local(global_point)
	var rect := Rect2(-size * 0.5, size)
	return rect.has_point(local)

func has_blocking_items() -> bool:
	_apply_collision_settings()
	var bodies := get_overlapping_bodies()
	if DebugLog.enabled():
		DebugLog.logf(
			"DropZone overlap_check desk=%s bodies=%d monitoring=%s monitorable=%s layer=%d mask=%d expected_mask=%d",
			[
				String(service_point_id),
				bodies.size(),
				str(monitoring),
				str(monitorable),
				int(collision_layer),
				int(collision_mask),
				int(PhysicsLayers.MASK_ITEMS_QUERY),
			]
		)
	for body in bodies:
		if body is ItemNodeScript:
			if DebugLog.enabled():
				DebugLog.logf(
					"DropZone blocked desk=%s body=%s",
					[String(service_point_id), String(body.name)]
				)
			return true
		if body is Node and body.has_method("get_item_instance"):
			if DebugLog.enabled():
				DebugLog.logf(
					"DropZone blocked desk=%s body=%s",
					[String(service_point_id), String(body.name)]
				)
			return true
	return false

func _apply_collision_settings() -> void:
	collision_layer = 0
	collision_mask = PhysicsLayers.MASK_ITEMS_QUERY

func _draw() -> void:
	if not debug_draw:
		return
	var rect := Rect2(-size * 0.5, size)
	draw_rect(rect, Color(0.2, 0.8, 0.4, 0.15), true)
	draw_rect(rect, Color(0.2, 0.8, 0.4, 0.9), false, 2.0)

func _ensure_shape() -> void:
	var shape_node := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape_node == null:
		shape_node = CollisionShape2D.new()
		shape_node.name = "CollisionShape2D"
		add_child(shape_node)
	var rect := shape_node.shape as RectangleShape2D
	if rect == null:
		rect = RectangleShape2D.new()
		shape_node.shape = rect
	rect.size = size

func _resolve_auto_sprite() -> void:
	if auto_size_sprite_path == NodePath():
		return
	var node := get_node_or_null(auto_size_sprite_path)
	if node is Sprite2D:
		_auto_sprite = node as Sprite2D
	if _auto_sprite == null:
		return
	var callback := Callable(self, "_on_auto_sprite_changed")
	if not _auto_sprite.texture_changed.is_connected(callback):
		_auto_sprite.texture_changed.connect(callback)
	if not _auto_sprite.frame_changed.is_connected(callback):
		_auto_sprite.frame_changed.connect(callback)

func _on_auto_sprite_changed() -> void:
	_apply_auto_size()
	_ensure_shape()

func _apply_auto_size() -> void:
	if _auto_sprite == null:
		return
	var rect := _auto_sprite.get_rect()
	var sprite_scale := _auto_sprite.scale
	var scaled := Vector2(abs(sprite_scale.x), abs(sprite_scale.y))
	var new_size := rect.size * scaled
	if new_size.x > 0.0 and new_size.y > 0.0:
		size = new_size
		queue_redraw()
