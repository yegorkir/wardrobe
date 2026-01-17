extends Control

@onready var _start_workdesk_button: Button = %StartWorkdeskButton
@onready var _debug_mode_checkbox: CheckBox = %DebugModeCheckbox
@onready var _quit_button: Button = %QuitButton
@onready var _run_manager: RunManagerBase = get_node_or_null("/root/RunManager") as RunManagerBase

@export_group("Client Flow Defaults")
@export var flow_tick_interval: float = 0.2
@export var flow_min_free_hooks: int = 1
@export var flow_max_queue_size: int = 5
@export var flow_spawn_cooldown: Vector2 = Vector2(2.0, 4.0)
@export var flow_checkout_ratio: float = 0.5

var _ui_tick_interval: SpinBox
var _ui_max_queue: SpinBox
var _ui_cooldown_min: SpinBox
var _ui_cooldown_max: SpinBox
var _ui_checkout_ratio: HSlider
var _ui_ratio_label: Label

var _ui_slot_decay: SpinBox
var _ui_queue_mult: HSlider
var _ui_queue_mult_label: Label
var _ui_patience_max: SpinBox
var _ui_strikes: SpinBox

func _ready() -> void:
	_start_workdesk_button.pressed.connect(_on_start_workdesk_pressed)
	_quit_button.pressed.connect(_on_quit_pressed)
	if OS.get_name() == "Web":
		_quit_button.disabled = true
		_quit_button.text = "Quit (N/A on Web)"
	
	_build_debug_settings_ui()

func _on_start_workdesk_pressed() -> void:
	if _run_manager:
		# Update Shift Config (Patience)
		var shift_config := {
			"slot_decay_rate": _ui_slot_decay.value,
			"queue_decay_multiplier": _ui_queue_mult.value,
			"patience_max": _ui_patience_max.value,
			"strikes_limit": int(_ui_strikes.value)
		}
		_run_manager.update_shift_config(shift_config)

		var cooldown = Vector2(_ui_cooldown_min.value, _ui_cooldown_max.value)
		# Ensure min <= max
		if cooldown.x > cooldown.y:
			cooldown.y = cooldown.x
			
		var payload := {
			"debug": _debug_mode_checkbox.button_pressed,
			"flow_tick_interval": _ui_tick_interval.value,
			"flow_min_free_hooks": flow_min_free_hooks, # No UI for this yet, keep default
			"flow_max_queue_size": int(_ui_max_queue.value),
			"flow_spawn_cooldown": cooldown,
			"flow_checkout_ratio": _ui_checkout_ratio.value
		}
		_run_manager.start_shift_with_screen(RunManagerBase.SCREEN_WARDROBE, payload)
	else:
		push_warning("Cannot start run: RunManager singleton missing.")

func _on_quit_pressed() -> void:
	get_tree().quit()

func _build_debug_settings_ui() -> void:
	var container := VBoxContainer.new()
	container.name = "DebugSettings"
	
	# Try to find a place to put it. 
	# Assuming MainMenu has a VBoxContainer or MarginContainer structure.
	# We'll add it to the main control or find a specific container.
	# If we can't find a good spot, we'll just add it to the root of MainMenu and position it.
	
	var parent_control = find_child("Content", true, false)
	if not parent_control:
		parent_control = self
	
	# Create a Panel for visibility
	var panel = PanelContainer.new()
	parent_control.add_child(panel)
	# Position absolute if added to root, or rely on container layout
	if parent_control == self:
		panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		panel.position = Vector2(-320, 20) # Offset from top right? No, anchors work differently.
		# Simplest: Top Right corner
		panel.anchor_left = 1.0
		panel.anchor_right = 1.0
		panel.offset_left = -320
		panel.offset_bottom = 600 # Increased height
	
	panel.add_child(container)
	
	var title = Label.new()
	title.text = "Flow Director Settings"
	container.add_child(title)
	
	_ui_tick_interval = _add_setting_spinbox(container, "Tick Interval (s)", 0.05, 5.0, 0.05, flow_tick_interval)
	_ui_max_queue = _add_setting_spinbox(container, "Max Queue", 1, 20, 1, float(flow_max_queue_size))
	
	container.add_child(HSeparator.new())
	var cd_label = Label.new()
	cd_label.text = "Spawn Cooldown (s)"
	container.add_child(cd_label)
	_ui_cooldown_min = _add_setting_spinbox(container, "Min", 0.0, 60.0, 0.1, flow_spawn_cooldown.x)
	_ui_cooldown_max = _add_setting_spinbox(container, "Max", 0.0, 60.0, 0.1, flow_spawn_cooldown.y)
	
	container.add_child(HSeparator.new())
	_ui_checkout_ratio = HSlider.new()
	_ui_checkout_ratio.min_value = 0.0
	_ui_checkout_ratio.max_value = 1.0
	_ui_checkout_ratio.step = 0.05
	_ui_checkout_ratio.value = flow_checkout_ratio
	
	var ratio_hbox = HBoxContainer.new()
	var r_label = Label.new()
	r_label.text = "Checkout Ratio"
	_ui_ratio_label = Label.new()
	_ui_ratio_label.text = "%.2f" % flow_checkout_ratio
	ratio_hbox.add_child(r_label)
	ratio_hbox.add_child(_ui_ratio_label)
	
	container.add_child(ratio_hbox)
	container.add_child(_ui_checkout_ratio)
	
	_ui_checkout_ratio.value_changed.connect(func(v): _ui_ratio_label.text = "%.2f" % v)

	# Patience Settings Section
	container.add_child(HSeparator.new())
	var spacer = Control.new()
	spacer.custom_minimum_size.y = 10
	container.add_child(spacer)
	
	var pat_title = Label.new()
	pat_title.text = "Patience Settings"
	container.add_child(pat_title)

	_ui_slot_decay = _add_setting_spinbox(container, "Slot Decay (/s)", 0.1, 10.0, 0.1, 1.0)
	
	_ui_queue_mult = HSlider.new()
	_ui_queue_mult.min_value = 0.0
	_ui_queue_mult.max_value = 2.0
	_ui_queue_mult.step = 0.1
	_ui_queue_mult.value = 0.5
	
	var q_hbox = HBoxContainer.new()
	var q_label = Label.new()
	q_label.text = "Queue Mult"
	_ui_queue_mult_label = Label.new()
	_ui_queue_mult_label.text = "%.1f" % 0.5
	q_hbox.add_child(q_label)
	q_hbox.add_child(_ui_queue_mult_label)
	
	container.add_child(q_hbox)
	container.add_child(_ui_queue_mult)
	_ui_queue_mult.value_changed.connect(func(v): _ui_queue_mult_label.text = "%.1f" % v)
	
	_ui_patience_max = _add_setting_spinbox(container, "Max Patience (s)", 5.0, 120.0, 5.0, 30.0)
	_ui_strikes = _add_setting_spinbox(container, "Strikes Limit", 1, 10, 1, 3)

func _add_setting_spinbox(parent: Control, label_text: String, min_v: float, max_v: float, step: float, default_v: float) -> SpinBox:
	var hbox = HBoxContainer.new()
	var label = Label.new()
	label.text = label_text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var spin = SpinBox.new()
	spin.min_value = min_v
	spin.max_value = max_v
	spin.step = step
	spin.value = default_v
	spin.custom_minimum_size.x = 100
	hbox.add_child(label)
	hbox.add_child(spin)
	parent.add_child(hbox)
	return spin
