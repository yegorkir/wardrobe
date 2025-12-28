class_name WardrobeSurface2D
extends Node2D

const ItemNodeScript := preload("res://scripts/wardrobe/item_node.gd")

func get_surface_y_global() -> float:
	push_warning("%s missing get_surface_y_global override." % name)
	return global_position.y

func get_surface_kind() -> StringName:
	return StringName("unknown")

func get_surface_collision_y_global() -> float:
	push_warning("%s missing get_surface_collision_y_global override." % name)
	return get_surface_y_global()

func get_surface_bounds_global() -> Rect2:
	push_warning("%s missing get_surface_bounds_global override." % name)
	return Rect2()

func remove_item(_item: ItemNode) -> void:
	push_warning("%s missing remove_item override." % name)

func drop_item_with_fall(_item: ItemNode, _drop_global_pos: Vector2) -> Vector2:
	push_warning("%s missing drop_item_with_fall override." % name)
	return _drop_global_pos
