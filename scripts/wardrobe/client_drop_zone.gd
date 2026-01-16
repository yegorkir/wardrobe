@tool
extends Area2D

class_name ClientDropZone

const GROUP := "sp_client_drop_zone"

@export var size: Vector2 = Vector2(120.0, 80.0)
var service_point_id: StringName = StringName()

func _ready() -> void:
	add_to_group(GROUP)
	monitoring = true
	monitorable = true
	_ensure_shape()

func is_point_inside(global_point: Vector2) -> bool:
	var local := to_local(global_point)
	var rect := Rect2(-size * 0.5, size)
	return rect.has_point(local)

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
