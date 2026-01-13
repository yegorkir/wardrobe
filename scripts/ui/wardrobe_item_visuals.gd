extends RefCounted
class_name WardrobeItemVisualsAdapter

const ItemInstanceScript := preload("res://scripts/domain/storage/item_instance.gd")
const WardrobeItemConfigScript := preload("res://scripts/ui/wardrobe_item_config.gd")
const ITEM_TEXTURE_PATHS := {
	ItemNode.ItemType.COAT: [
		"res://assets/sprites/item_coat.png",
		"res://assets/sprites/placeholder/item_coat.png",
	],
	ItemNode.ItemType.TICKET: [
		"res://assets/sprites/item_ticket.png",
		"res://assets/sprites/placeholder/item_ticket.png",
	],
	ItemNode.ItemType.ANCHOR_TICKET: [
		"res://assets/sprites/item_anchor_ticket.png",
		"res://assets/sprites/placeholder/item_anchor_ticket.png",
	],
	ItemNode.ItemType.BOTTLE: [
		"res://assets/sprites/item_bottle.png",
		"res://assets/sprites/placeholder/item_coat.png",
	],
	ItemNode.ItemType.CHEST: [
		"res://assets/sprites/item_chest.png",
		"res://assets/sprites/placeholder/item_coat.png",
	],
	ItemNode.ItemType.HAT: [
		"res://assets/sprites/item_hat.png",
		"res://assets/sprites/placeholder/item_coat.png",
	],
}

var _item_scene: PackedScene
var _slot_lookup: Dictionary = {}
var _item_nodes: Dictionary = {}
var _spawned_items: Array = []
var _detach_item_node: Callable
var _find_item_instance: Callable

func configure(
	item_scene: PackedScene,
	slot_lookup: Dictionary,
	item_nodes: Dictionary,
	spawned_items: Array,
	detach_item_node: Callable,
	find_item_instance: Callable = Callable()
) -> void:
	_item_scene = item_scene
	_slot_lookup = slot_lookup
	_item_nodes = item_nodes
	_spawned_items = spawned_items
	_detach_item_node = detach_item_node
	_find_item_instance = find_item_instance

func spawn_or_move_item_node(slot_id: StringName, instance: ItemInstance) -> void:
	var slot: WardrobeSlot = _slot_lookup.get(slot_id, null)
	if slot == null or instance == null:
		return
	var node: ItemNode = _item_nodes.get(instance.id, null)
	if node == null:
		node = _item_scene.instantiate() as ItemNode
		node.item_id = str(instance.id)
		node.item_type = resolve_item_type(instance)
		node.set_item_instance(instance)
		apply_item_visuals(node, instance.color)
		_item_nodes[instance.id] = node
		_spawned_items.append(node)
	else:
		node.set_item_instance(instance)
		apply_item_visuals(node, instance.color)
	if _detach_item_node.is_valid():
		_detach_item_node.call(node)
	slot.put_item(node)
	refresh_quality_stars(node)

func apply_item_visuals(item: ItemNode, tint: Variant) -> void:
	var sprite := item.get_node_or_null("Sprite") as Sprite2D
	if sprite:
		var texture := get_item_texture(item.item_type)
		if texture:
			sprite.texture = texture
		if tint == null:
			sprite.modulate = Color.WHITE
		else:
			sprite.modulate = parse_color(tint)
	item.configure_pick_box_from_sprite()
	item.refresh_physics_shape_from_sprite()

func refresh_quality_stars(item: ItemNode) -> void:
	if item == null:
		return
	var instance: ItemInstance = null
	if _find_item_instance.is_valid():
		instance = _find_item_instance.call(StringName(item.item_id)) as ItemInstance
	
	if instance == null or instance.quality_state == null:
		_hide_stars(item)
		return
	
	_render_stars(item, instance.quality_state.current_stars, instance.quality_state.max_stars)

func _render_stars(item: ItemNode, current: float, max_val: int) -> void:
	var stars_container = item.get_node_or_null("QualityStars")
	if stars_container == null:
		stars_container = Node2D.new()
		stars_container.name = "QualityStars"
		item.add_child(stars_container)
		# Position it under the item
		stars_container.position = Vector2(0, item.get_visual_half_height() + 8)
	
	# Clear existing stars
	for child in stars_container.get_children():
		child.queue_free()
	
	var star_size := 16.0
	var spacing := 4.0
	var total_width := float(max_val) * star_size + float(max_val - 1) * spacing
	var start_x := -total_width * 0.5 + star_size * 0.5
	
	for i in range(max_val):
		# Background (empty slot)
		var bg := ColorRect.new()
		bg.size = Vector2(star_size, star_size)
		bg.position = Vector2(start_x + i * (star_size + spacing) - star_size * 0.5, -star_size * 0.5)
		bg.color = Color.GRAY
		stars_container.add_child(bg)
		
		# Fill
		if float(i) < current:
			var fill := ColorRect.new()
			fill.position = bg.position
			fill.color = Color.GOLD
			
			if float(i) + 1.0 <= current:
				# Full
				fill.size = Vector2(star_size, star_size)
			elif float(i) + 0.5 <= current:
				# Half
				fill.size = Vector2(star_size * 0.5, star_size)
			else:
				# Should not happen with 0.5 steps, but just in case
				fill.size = Vector2(0, star_size)
				
			if fill.size.x > 0:
				stars_container.add_child(fill)

func _hide_stars(item: ItemNode) -> void:
	var stars_container = item.get_node_or_null("QualityStars")
	if stars_container:
		stars_container.visible = false

func get_item_texture(item_type: int) -> Texture2D:
	var paths: Array = ITEM_TEXTURE_PATHS.get(item_type, ITEM_TEXTURE_PATHS[ItemNode.ItemType.COAT])
	for path in paths:
		if ResourceLoader.exists(path, "Texture2D"):
			var resource := load(path)
			if resource is Texture2D:
				return resource
	return null

func resolve_kind_from_item_type(item_type: int) -> StringName:
	return WardrobeItemConfigScript.get_kind_for_item_type(item_type)

func resolve_item_type(instance: ItemInstance) -> ItemNode.ItemType:
	if instance == null:
		return ItemNode.ItemType.COAT
	return WardrobeItemConfigScript.resolve_item_type(instance.id, instance.kind)

func parse_color(value: Variant) -> Color:
	match typeof(value):
		TYPE_COLOR:
			return value
		TYPE_STRING:
			return Color.from_string(value, Color.WHITE)
		TYPE_ARRAY:
			var components := value as Array
			if components.size() >= 3:
				var r := float(components[0])
				var g := float(components[1])
				var b := float(components[2])
				var a := float(components[3]) if components.size() >= 4 else 1.0
				return Color(r, g, b, a)
	return Color.WHITE

func get_item_color(item: ItemNode) -> Color:
	var sprite := item.get_node_or_null("Sprite") as Sprite2D
	if sprite:
		return sprite.modulate
	return Color.WHITE
