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

func configure(
	item_scene: PackedScene,
	slot_lookup: Dictionary,
	item_nodes: Dictionary,
	spawned_items: Array,
	detach_item_node: Callable
) -> void:
	_item_scene = item_scene
	_slot_lookup = slot_lookup
	_item_nodes = item_nodes
	_spawned_items = spawned_items
	_detach_item_node = detach_item_node

func spawn_or_move_item_node(slot_id: StringName, instance: ItemInstance) -> void:
	var slot: WardrobeSlot = _slot_lookup.get(slot_id, null)
	if slot == null or instance == null:
		return
	var node: ItemNode = _item_nodes.get(instance.id, null)
	if node == null:
		node = _item_scene.instantiate() as ItemNode
		node.item_id = str(instance.id)
		node.item_type = resolve_item_type(instance)
		apply_item_visuals(node, instance.color)
		_item_nodes[instance.id] = node
		_spawned_items.append(node)
	else:
		apply_item_visuals(node, instance.color)
	if _detach_item_node.is_valid():
		_detach_item_node.call(node)
	slot.put_item(node)

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
