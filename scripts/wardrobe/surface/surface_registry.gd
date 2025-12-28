class_name SurfaceRegistryService
extends Node

const WardrobeSurface2DScript := preload("res://scripts/wardrobe/surface/wardrobe_surface_2d.gd")

var _floors: Array[WardrobeSurface2D] = []
var _shelves: Array[WardrobeSurface2D] = []

static func get_autoload() -> SurfaceRegistryService:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	return tree.root.get_node_or_null("SurfaceRegistry") as SurfaceRegistryService

func register_floor(surface: WardrobeSurface2D) -> void:
	_add_unique(_floors, surface)

func unregister_floor(surface: WardrobeSurface2D) -> void:
	_remove_existing(_floors, surface)

func register_shelf(surface: WardrobeSurface2D) -> void:
	_add_unique(_shelves, surface)

func unregister_shelf(surface: WardrobeSurface2D) -> void:
	_remove_existing(_shelves, surface)

func get_floors() -> Array[WardrobeSurface2D]:
	return _floors.duplicate()

func get_shelves() -> Array[WardrobeSurface2D]:
	return _shelves.duplicate()

func get_floor_below(item_x: float, item_bottom_y: float) -> WardrobeSurface2D:
	var best: WardrobeSurface2D = null
	var best_delta := INF
	for surface in _floors:
		if surface == null or not is_instance_valid(surface):
			continue
		var surface_y: float = surface.get_surface_collision_y_global()
		var delta: float = surface_y - item_bottom_y
		if delta < 0.0:
			continue
		if not _is_x_within_surface_bounds(surface, item_x):
			continue
		if delta < best_delta:
			best_delta = delta
			best = surface
	return best

func pick_floor_for_item(item_x: float, item_bottom_y: float) -> WardrobeSurface2D:
	var candidates: Array[WardrobeSurface2D] = []
	for surface in _floors:
		if surface == null or not is_instance_valid(surface):
			continue
		if _is_x_within_surface_bounds(surface, item_x):
			candidates.append(surface)
	if candidates.is_empty():
		for surface in _floors:
			if surface == null or not is_instance_valid(surface):
				continue
			candidates.append(surface)
	var best_below: WardrobeSurface2D = null
	var best_below_delta := INF
	var best_below_name := ""
	for surface in candidates:
		var surface_y: float = surface.get_surface_collision_y_global()
		var delta: float = surface_y - item_bottom_y
		if delta < 0.0:
			continue
		if delta < best_below_delta or (is_equal_approx(delta, best_below_delta) and String(surface.name) < best_below_name):
			best_below = surface
			best_below_delta = delta
			best_below_name = String(surface.name)
	if best_below != null:
		return best_below
	var best: WardrobeSurface2D = null
	var best_abs_delta := INF
	var best_name := ""
	for surface in candidates:
		var surface_y: float = surface.get_surface_collision_y_global()
		var delta: float = abs(surface_y - item_bottom_y)
		if delta < best_abs_delta or (is_equal_approx(delta, best_abs_delta) and String(surface.name) < best_name):
			best = surface
			best_abs_delta = delta
			best_name = String(surface.name)
	return best

func remove_item_from_all(item: ItemNode) -> void:
	if item == null:
		return
	if item.current_surface != null and is_instance_valid(item.current_surface):
		var surface := item.current_surface as WardrobeSurface2D
		if surface != null:
			surface.remove_item(item)
		item.clear_current_surface()
		return
	for shelf in _shelves:
		if shelf != null:
			shelf.remove_item(item)
	for floor_node in _floors:
		if floor_node != null:
			floor_node.remove_item(item)
	item.clear_current_surface()

func _add_unique(store: Array, surface: WardrobeSurface2D) -> void:
	if surface == null:
		return
	if store.has(surface):
		return
	store.append(surface)

func _remove_existing(store: Array, surface: WardrobeSurface2D) -> void:
	if surface == null:
		return
	store.erase(surface)

func _is_x_within_surface_bounds(surface: WardrobeSurface2D, item_x: float) -> bool:
	var bounds: Rect2 = surface.get_surface_bounds_global()
	if bounds.size == Vector2.ZERO:
		return true
	return item_x >= bounds.position.x and item_x <= bounds.position.x + bounds.size.x
