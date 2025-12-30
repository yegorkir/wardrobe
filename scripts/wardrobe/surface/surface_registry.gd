class_name SurfaceRegistryService
extends Node

var _floors: Array[Node] = []
var _shelves: Array[Node] = []

func register_floor(surface: Node) -> void:
	_add_unique(_floors, surface)

func unregister_floor(surface: Node) -> void:
	_remove_existing(_floors, surface)

func register_shelf(surface: Node) -> void:
	_add_unique(_shelves, surface)

func unregister_shelf(surface: Node) -> void:
	_remove_existing(_shelves, surface)

func get_floors() -> Array[Node]:
	return _floors.duplicate()

func get_shelves() -> Array[Node]:
	return _shelves.duplicate()

func get_floor_below(item_x: float, item_bottom_y: float) -> Node:
	var best: Node = null
	var best_delta := INF
	for surface in _floors:
		if surface == null or not is_instance_valid(surface):
			continue
		if not surface.has_method("get_surface_y_global"):
			continue
		var surface_y_var: Variant = surface.call("get_surface_y_global")
		if typeof(surface_y_var) != TYPE_FLOAT:
			continue
		var surface_y := surface_y_var as float
		var delta := surface_y - item_bottom_y
		if delta < 0.0:
			continue
		if not _is_x_within_surface_bounds(surface, item_x):
			continue
		if delta < best_delta:
			best_delta = delta
			best = surface
	return best

func remove_item_from_all(item: ItemNode) -> void:
	if item == null:
		return
	for shelf in _shelves:
		if shelf != null and shelf.has_method("remove_item"):
			shelf.call("remove_item", item)
	for floor_node in _floors:
		if floor_node != null and floor_node.has_method("remove_item"):
			floor_node.call("remove_item", item)

func _add_unique(store: Array, surface: Node) -> void:
	if surface == null:
		return
	if store.has(surface):
		return
	store.append(surface)

func _remove_existing(store: Array, surface: Node) -> void:
	if surface == null:
		return
	store.erase(surface)

func _is_x_within_surface_bounds(surface: Node, item_x: float) -> bool:
	if not surface.has_method("get_surface_bounds_global"):
		return true
	var bounds_var: Variant = surface.call("get_surface_bounds_global")
	if typeof(bounds_var) != TYPE_RECT2:
		return true
	var bounds := bounds_var as Rect2
	if bounds.size == Vector2.ZERO:
		return true
	return item_x >= bounds.position.x and item_x <= bounds.position.x + bounds.size.x
