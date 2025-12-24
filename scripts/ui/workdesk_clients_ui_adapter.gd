extends RefCounted
class_name WorkdeskClientsUIAdapter

const ItemInstanceScript := preload("res://scripts/domain/storage/item_instance.gd")

class DeskClientView extends RefCounted:
	var client_visual: CanvasItem
	var patience_bg: Control
	var patience_fill: Control
	var patience_full_width: float = 0.0

	func configure(
		client_node: CanvasItem,
		patience_bg_node: Control,
		patience_fill_node: Control
	) -> void:
		client_visual = client_node
		patience_bg = patience_bg_node
		patience_fill = patience_fill_node
		if patience_bg:
			patience_full_width = patience_bg.size.x
		elif patience_fill:
			patience_full_width = patience_fill.size.x

	func set_client_visible(visible: bool) -> void:
		if client_visual:
			client_visual.visible = visible
		if patience_bg:
			patience_bg.visible = visible
		if patience_fill:
			patience_fill.visible = visible

	func set_client_color(color: Color) -> void:
		if client_visual == null:
			return
		if client_visual is ColorRect:
			var rect := client_visual as ColorRect
			rect.color = color
			return
		client_visual.modulate = color

	func set_patience_ratio(ratio: float) -> void:
		if patience_fill == null:
			return
		var clamped := clampf(ratio, 0.0, 1.0)
		var width := patience_full_width
		if width <= 0.0:
			width = patience_fill.size.x
		patience_fill.size = Vector2(width * clamped, patience_fill.size.y)

var _desks_by_id: Dictionary = {}
var _desk_states_by_id: Dictionary = {}
var _patience_by_client_id: Dictionary = {}
var _patience_max_by_client_id: Dictionary = {}
var _clients_by_id: Dictionary = {}

func configure(
	desks_by_id: Dictionary,
	desk_states_by_id: Dictionary,
	patience_by_client_id: Dictionary,
	patience_max_by_client_id: Dictionary,
	clients_by_id_opt: Dictionary
) -> void:
	_desks_by_id = desks_by_id
	_desk_states_by_id = desk_states_by_id
	_patience_by_client_id = patience_by_client_id
	_patience_max_by_client_id = patience_max_by_client_id
	_clients_by_id = clients_by_id_opt

func refresh() -> void:
	for desk_id in _desks_by_id.keys():
		var desk_view: DeskClientView = _desks_by_id.get(desk_id, null)
		if desk_view == null:
			continue
		var desk_state: RefCounted = _desk_states_by_id.get(desk_id, null)
		if desk_state == null:
			desk_view.set_client_visible(false)
			continue
		var client_id: StringName = desk_state.current_client_id
		if client_id == StringName():
			desk_view.set_client_visible(false)
			continue
		desk_view.set_client_visible(true)
		desk_view.set_client_color(_resolve_client_color(client_id))
		var patience_left := float(_patience_by_client_id.get(client_id, 0.0))
		var patience_max := float(_patience_max_by_client_id.get(client_id, 0.0))
		var ratio := 0.0
		if patience_max > 0.0:
			ratio = patience_left / patience_max
		desk_view.set_patience_ratio(ratio)

func _resolve_client_color(client_id: StringName) -> Color:
	var client: RefCounted = _clients_by_id.get(client_id, null)
	if client != null and client.has_method("get_coat_item"):
		var coat: ItemInstance = client.get_coat_item() as ItemInstance
		if coat != null:
			return coat.color
	var id_str := String(client_id)
	var hash_value := 0
	for index in id_str.length():
		hash_value = int((hash_value * 31 + id_str.unicode_at(index)) % 360)
	var hue := float(hash_value) / 360.0
	return Color.from_hsv(hue, 0.5, 0.9)
