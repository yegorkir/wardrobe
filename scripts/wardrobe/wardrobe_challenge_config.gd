extends Resource

class_name WardrobeChallengeConfig

const DEFAULT_BEST_RESULTS_FILE := "user://challenge_bests.json"
const DEFAULT_CHALLENGE_ID := "color_match_basic"
const DEFAULT_SEED_ID := "step2_seed"
const DEFAULT_SEED_TABLE := [
	{
		"slot_id": "DeskSlot_0",
		"item_id": "coat_001",
		"item_type": "COAT",
		"color": "#e69966",
	},
	{
		"slot_id": "Hook_0_SlotA",
		"item_id": "ticket_001",
		"item_type": "TICKET",
		"color": "#66ccff",
	},
	{
		"slot_id": "Hook_1_SlotB",
		"item_id": "coat_002",
		"item_type": "COAT",
		"color": "#b366e6",
	},
	{
		"slot_id": "Hook_3_SlotA",
		"item_id": "ticket_002",
		"item_type": "TICKET",
		"color": "#33e6b3",
	},
	{
		"slot_id": "Hook_5_SlotB",
		"item_id": "anchor_ticket_001",
		"item_type": "ANCHOR_TICKET",
		"color": "#ffd24d",
	},
]

@export var default_challenge_id := DEFAULT_CHALLENGE_ID
@export var default_seed_id := DEFAULT_SEED_ID
@export_file("*.json") var best_results_path := DEFAULT_BEST_RESULTS_FILE
@export var fallback_seed_table: Array = []

func _init() -> void:
	if fallback_seed_table.is_empty():
		fallback_seed_table = DEFAULT_SEED_TABLE.duplicate(true)
