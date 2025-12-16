extends Control

@onready var _wave_label: Label = %WaveValue
@onready var _time_label: Label = %TimeValue
@onready var _money_label: Label = %MoneyValue
@onready var _magic_label: Label = %MagicValue
@onready var _debt_label: Label = %DebtValue
@onready var _end_shift_button: Button = %EndShiftButton
@onready var _run_manager := get_node_or_null("/root/RunManager")
var _hud_connected := false

func _ready() -> void:
	if _run_manager:
		_run_manager.hud_updated.connect(_on_hud_updated)
		_hud_connected = true
		_on_hud_updated(_run_manager.get_hud_snapshot())
	else:
		push_warning("RunManager singleton not found; HUD will not update.")
	_end_shift_button.pressed.connect(_on_end_shift_pressed)

func _exit_tree() -> void:
	if _hud_connected:
		_run_manager.hud_updated.disconnect(_on_hud_updated)
		_hud_connected = false

func _on_hud_updated(snapshot: Dictionary) -> void:
	_wave_label.text = "Wave: %s" % snapshot.get("wave", "-")
	_time_label.text = "Time: %s" % snapshot.get("time", "-")
	_money_label.text = "Money: %s" % snapshot.get("money", "-")
	_magic_label.text = "Magic: %s" % snapshot.get("magic", "-")
	_debt_label.text = "Debt: %s" % snapshot.get("debt", "-")

func _on_end_shift_pressed() -> void:
	if _run_manager:
		_run_manager.end_shift()
	else:
		push_warning("Cannot end shift: RunManager singleton missing.")
