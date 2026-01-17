extends RefCounted

class_name ItemInstance

const ItemQualityConfigScript := preload("res://scripts/domain/quality/item_quality_config.gd")
const ItemQualityStateScript := preload("res://scripts/domain/quality/item_quality_state.gd")
const ItemEffectScript := preload("res://scripts/domain/effects/item_effect.gd")
const ItemEffectResultScript := preload("res://scripts/domain/effects/item_effect_result.gd")
const ItemEffectTypesScript := preload("res://scripts/domain/effects/item_effect_types.gd")

const KIND_COAT := StringName("COAT")
const KIND_TICKET := StringName("TICKET")
const KIND_ANCHOR_TICKET := StringName("ANCHOR_TICKET")

var id: StringName
var kind: StringName
var archetype_id: StringName
var color: Color
var quality_state: RefCounted # ItemQualityState
var ticket_symbol_index: int = -1

func _init(item_id: StringName, item_kind: StringName, item_archetype_id: StringName = &"", item_color: Color = Color.WHITE, p_quality_state: RefCounted = null) -> void:
	id = item_id
	kind = item_kind
	archetype_id = item_archetype_id
	color = item_color
	
	if p_quality_state:
		quality_state = p_quality_state
	else:
		# MVP Default: 3 stars
		var default_config = ItemQualityConfigScript.new(3)
		quality_state = ItemQualityStateScript.new(default_config)

func duplicate_instance() -> ItemInstance:
	var dup_quality = null
	if quality_state:
		dup_quality = quality_state.call("duplicate_state")
	var duplicate := get_script().new(id, kind, archetype_id, color, dup_quality) as ItemInstance
	duplicate.ticket_symbol_index = ticket_symbol_index
	return duplicate

func to_snapshot() -> Dictionary:
	var snapshot := {
		"id": id,
		"kind": kind,
		"archetype_id": archetype_id,
		"color": color,
	}
	if ticket_symbol_index >= 0:
		snapshot["ticket_symbol_index"] = ticket_symbol_index
	if quality_state:
		snapshot["quality"] = quality_state.call("to_snapshot")
	return snapshot

func apply_effect(effect: ItemEffect) -> ItemEffectResult:
	var quality_loss_amount := 0.0
	var accepted := false
	
	# Mapping effect types to quality loss logic
	if effect.type == ItemEffectTypesScript.Type.LIGHT_CORROSION:
		quality_loss_amount = effect.intensity
		accepted = true
	elif effect.type == ItemEffectTypesScript.Type.ZOMBIE_AURA:
		quality_loss_amount = effect.intensity
		accepted = true
	
	var actual_loss := 0.0
	if quality_loss_amount > 0.0 and quality_state:
		actual_loss = quality_state.reduce_quality(quality_loss_amount)
	
	return ItemEffectResultScript.new(accepted, actual_loss, [])

func can_be_corrupted() -> bool:
	return kind != KIND_TICKET and kind != KIND_ANCHOR_TICKET
