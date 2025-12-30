class_name SurfaceRegistryService
extends Node

const WardrobeSurface2DScript := preload("res://scripts/wardrobe/surface/wardrobe_surface_2d.gd")

var _floors: Array = []
var _shelves: Array = []

static func resolve(node_owner: Node) -> SurfaceRegistryService:
	if node_owner == null:
		return null
	var tree := node_owner.get_tree()
	if tree == null:
		return null
	return tree.root.get_node_or_null("SurfaceRegistry") as SurfaceRegistryService

func register_floor(surface: Node) -> void:
	_add_unique(_floors, surface)

func unregister_floor(surface: Node) -> void:
	_remove_existing(_floors, surface)

func register_shelf(surface: Node) -> void:
	_add_unique(_shelves, surface)

func unregister_shelf(surface: Node) -> void:
	_remove_existing(_shelves, surface)

func get_floors() -> Array:
	return _floors.duplicate()

func get_shelves() -> Array:
	return _shelves.duplicate()

func get_floor_below(item_x: float, item_bottom_y: float) -> Node:
	var best: Node = null
	var best_delta := INF
	for surface in _floors:
		if surface == null or not is_instance_valid(surface) or not surface.is_class("WardrobeSurface2D"):
			continue
		var surface_y: float = surface.get_surface_y_global()
		var delta: float = surface_y - item_bottom_y
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
	if item.current_surface != null and is_instance_valid(item.current_surface):
		var surface := item.current_surface
		if surface.is_class("WardrobeSurface2D"):
			surface.remove_item(item)
		item.clear_current_surface()
		return
	for shelf in _shelves:
		if shelf != null and shelf.is_class("WardrobeSurface2D"):
			shelf.remove_item(item)
	for floor_node in _floors:
		if floor_node != null and floor_node.is_class("WardrobeSurface2D"):
			floor_node.remove_item(item)
	item.clear_current_surface()

func _add_unique(store: Array, surface: Node) -> void:
	if surface == null or not surface.is_class("WardrobeSurface2D"):
		return
	if store.has(surface):
		return
	store.append(surface)

func _remove_existing(store: Array, surface: Node) -> void:
	if surface == null:
		return
	store.erase(surface)

func _is_x_within_surface_bounds(surface: Node, item_x: float) -> bool:
	var bounds: Rect2 = surface.get_surface_bounds_global()
	if bounds.size == Vector2.ZERO:
		return true
	return item_x >= bounds.position.x and item_x <= bounds.position.x + bounds.size.x
