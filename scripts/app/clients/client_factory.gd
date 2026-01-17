extends RefCounted

class_name ClientFactory

const ClientStateScript := preload("res://scripts/domain/clients/client_state.gd")
const ItemInstanceScript := preload("res://scripts/domain/storage/item_instance.gd")
const WardrobeItemConfigScript := preload("res://scripts/ui/wardrobe_item_config.gd")
const DebugLog := preload("res://scripts/wardrobe/debug/debug_log.gd")

var _content_db: Object
var _register_item: Callable
var _client_roster: Array[StringName] = []
var _colors: Array[Color] = [
	Color(0.85, 0.35, 0.35),
	Color(0.35, 0.7, 0.45),
	Color(0.35, 0.45, 0.9),
	Color(0.9, 0.75, 0.35),
	Color(0.75, 0.35, 0.85),
	Color(0.35, 0.85, 0.8),
	Color(0.85, 0.6, 0.35),
]

func configure(content_db: Object, register_item: Callable, client_roster: Array[StringName] = []) -> void:
	_content_db = content_db
	_register_item = register_item
	_client_roster = client_roster

func build_checkin_client(index: int) -> RefCounted:
	var client_id := StringName("client_in_%d_%d" % [index, Time.get_ticks_msec()])
	var color := _colors[index % _colors.size()]
	
	var item_type := WardrobeItemConfigScript.get_demo_item_type_for_client(index)
	var item_id := WardrobeItemConfigScript.build_client_item_id(item_type, index)
	var item_kind := WardrobeItemConfigScript.get_kind_for_item_type(item_type)

	var client_def_id := _resolve_client_def_id(index)
	var client_def := _resolve_client_definition(client_def_id)
	
	var item_archetype_id := _map_item_archetype(client_def.archetype_id)
	
	var coat := ItemInstanceScript.new(
		item_id,
		item_kind,
		item_archetype_id,
		color
	)
	
	if _register_item.is_valid():
		_register_item.call(coat)
	elif DebugLog.enabled():
		DebugLog.logf("ClientFactory register_item_missing client=%s item=%s", [String(client_id), String(item_id)])
		
	return ClientStateScript.new(
		client_id,
		coat,
		null,
		StringName(),
		StringName("color_%d" % index),
		client_def.archetype_id,
		client_def.wrong_item_penalty,
		client_def_id,
		client_def.portrait_key
	)

func build_checkout_client(index: int, target_item: RefCounted) -> RefCounted:
	# target_item is the ItemInstance (coat) already in storage
	var client_id := StringName("client_out_%d_%d" % [index, Time.get_ticks_msec()])
	var color_val: Variant = target_item.get("color") if target_item else Color.WHITE
	var color: Color = color_val if color_val is Color else Color.WHITE
	
	var ticket_id := StringName("ticket_claim_%s_%d" % [client_id, index])
	var ticket := ItemInstanceScript.new(
		ticket_id,
		ItemInstanceScript.KIND_TICKET,
		StringName(),
		color
	)
	# Copy ticket symbol from target_item if it's stored with one
	# In our system, tickets in cabinets have symbols. 
	# If a client comes to checkout, they should have a ticket that matches the coat's ticket.
	if target_item.get("ticket_symbol_index") != -1:
		ticket.ticket_symbol_index = target_item.get("ticket_symbol_index")

	if _register_item.is_valid():
		_register_item.call(ticket)
	elif DebugLog.enabled():
		DebugLog.logf("ClientFactory register_item_missing client=%s item=%s", [String(client_id), String(ticket_id)])

	var client_def_id := _resolve_client_def_id(index)
	var client_def := _resolve_client_definition(client_def_id)

	return ClientStateScript.new(
		client_id,
		null,
		ticket,
		StringName(),
		StringName("color_%d" % index),
		client_def.archetype_id,
		client_def.wrong_item_penalty,
		client_def_id,
		client_def.portrait_key
	)

func _resolve_client_def_id(index: int) -> StringName:
	if _client_roster.is_empty():
		return StringName("client_human")
	return _client_roster[index % _client_roster.size()]

func _resolve_client_definition(client_def_id: StringName) -> Dictionary:
	if _content_db == null:
		return {
			"archetype_id": StringName("human"),
			"portrait_key": StringName(),
			"wrong_item_penalty": 0.0,
		}
	
	var client_def: Variant = _content_db.call("get_client", String(client_def_id))
	var client_payload: Dictionary = client_def.get("payload", {}) if client_def else {}
	var archetype_id := StringName(str(client_payload.get("archetype_id", "human")))
	var portrait_key := StringName(str(client_payload.get("portrait_key", "")))
	var penalty: float = float(client_payload.get("wrong_item_patience_penalty", 0.0))
	
	return {
		"archetype_id": archetype_id,
		"portrait_key": portrait_key,
		"wrong_item_penalty": penalty,
	}

func _map_item_archetype(client_archetype_id: StringName) -> StringName:
	if client_archetype_id == "vampire" or client_archetype_id == "client_vampire":
		return StringName("vampire_cloak")
	elif client_archetype_id == "zombie" or client_archetype_id == "client_zombie":
		return StringName("zombie_rag")
	elif client_archetype_id == "ghost" or client_archetype_id == "client_ghost":
		return StringName("ghost_sheet")
	return StringName()
