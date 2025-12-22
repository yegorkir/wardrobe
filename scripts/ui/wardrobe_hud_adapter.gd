extends RefCounted
class_name WardrobeHudAdapter

var _run_manager: RunManagerBase
var _wave_label: Label
var _time_label: Label
var _money_label: Label
var _magic_label: Label
var _debt_label: Label
var _end_shift_button: Button
var _hud_connected := false
var _button_connected := false

func configure(
	run_manager: RunManagerBase,
	wave_label: Label,
	time_label: Label,
	money_label: Label,
	magic_label: Label,
	debt_label: Label,
	end_shift_button: Button
) -> void:
	_run_manager = run_manager
	_wave_label = wave_label
	_time_label = time_label
	_money_label = money_label
	_magic_label = magic_label
	_debt_label = debt_label
	_end_shift_button = end_shift_button

func setup_hud() -> void:
	if _run_manager:
		_run_manager.hud_updated.connect(_on_hud_updated)
		_hud_connected = true
		_on_hud_updated(_run_manager.get_hud_snapshot())
	else:
		push_warning("RunManager singleton not found; HUD will not update.")
	if _end_shift_button and not _button_connected:
		_end_shift_button.pressed.connect(_on_end_shift_pressed)
		_button_connected = true

func teardown_hud() -> void:
	if _run_manager and _hud_connected:
		_run_manager.hud_updated.disconnect(_on_hud_updated)
		_hud_connected = false
	if _end_shift_button and _button_connected:
		_end_shift_button.pressed.disconnect(_on_end_shift_pressed)
		_button_connected = false

func _on_hud_updated(snapshot: Dictionary) -> void:
	if _wave_label:
		_wave_label.text = "Wave: %s" % snapshot.get("wave", "-")
	if _time_label:
		_time_label.text = "Time: %s" % snapshot.get("time", "-")
	if _money_label:
		_money_label.text = "Money: %s" % snapshot.get("money", "-")
	if _magic_label:
		_magic_label.text = "Magic: %s" % snapshot.get("magic", "-")
	if _debt_label:
		_debt_label.text = "Debt: %s" % snapshot.get("debt", "-")

func _on_end_shift_pressed() -> void:
	if _run_manager:
		_run_manager.end_shift()
	else:
		push_warning("Cannot end shift: RunManager singleton missing.")
