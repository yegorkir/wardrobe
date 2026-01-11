extends GdUnitTestSuite

const REQUIRED_SCENES := [
	"res://scenes/Main.tscn",
	"res://scenes/screens/MainMenu.tscn",
	"res://scenes/screens/WardrobeScene.tscn",
	"res://scenes/screens/ShiftSummary.tscn",
	"res://scenes/screens/ModifierSelect.tscn",
]

const CONTENT_DIRECTORIES := {
	"archetypes": "res://content/archetypes",
	"modifiers": "res://content/modifiers",
	"waves": "res://content/waves",
}

const REQUIRED_INPUT_ACTIONS := [
	"tap",
	"cancel",
	"debug_toggle",
	"move_left",
	"move_right",
	"move_up",
	"move_down",
	"interact",
	"debug_reset",
]

const WARDROBE_SCENE := preload("res://scenes/screens/WardrobeScene.tscn")

class LogProbe:
	var entries: Array = []

	func attach_run_manager(run_manager: RunManagerBase) -> void:
		run_manager.run_state_changed.connect(func(state_name: String) -> void:
			record("run_state_changed", {"state": state_name}))
		run_manager.screen_requested.connect(func(screen_id: String, payload: Variant = {}) -> void:
			record("screen_requested", {"screen": screen_id, "payload": payload}))
		run_manager.hud_updated.connect(func(snapshot) -> void:
			record("hud_updated", {"snapshot": snapshot}))

	func record(event_name: String, payload: Dictionary) -> void:
		entries.append({
			"event": event_name,
			"payload": payload.duplicate(true),
		})

	func has(event_name: String, expected_payload: Dictionary = {}) -> bool:
		for entry in entries:
			if entry["event"] != event_name:
				continue
			if _payload_matches(entry["payload"], expected_payload):
				return true
		return false

	func clear() -> void:
		entries.clear()

	func _payload_matches(payload: Dictionary, expected: Dictionary) -> bool:
		for key in expected.keys():
			if payload.get(key) != expected[key]:
				return false
		return true

var _content_samples := {}

func before_test() -> void:
	_content_samples = {
		"archetypes": "",
		"modifiers": "",
		"waves": "",
	}

func test_required_scenes_and_input_map_exist() -> void:
	for scene_path in REQUIRED_SCENES:
		assert_bool(ResourceLoader.exists(scene_path)).override_failure_message(
			"Expect scene %s to exist" % scene_path
		).is_true()
	for action in REQUIRED_INPUT_ACTIONS:
		assert_bool(InputMap.has_action(action)).override_failure_message(
			"Missing input action '%s'" % action
		).is_true()

func test_content_files_are_valid_json() -> void:
	for category in CONTENT_DIRECTORIES.keys():
		var base_path: String = CONTENT_DIRECTORIES[category]
		var files := DirAccess.get_files_at(base_path)
		var valid_entry_found := false
		for file_name in files:
			if not file_name.ends_with(".json"):
				continue
			var path := "%s/%s" % [base_path, file_name]
			var json_text := FileAccess.get_file_as_string(path)
			var parsed: Variant = JSON.parse_string(json_text)
			assert_int(typeof(parsed)).is_equal(TYPE_DICTIONARY)
			var id_value := str(parsed.get("id", ""))
			assert_str(id_value).is_not_empty()
			valid_entry_found = true
			if str(_content_samples.get(category, "")).is_empty():
				_content_samples[category] = id_value
		assert_bool(valid_entry_found).override_failure_message(
			"No valid entries found in %s" % base_path
		).is_true()

func test_content_db_registers_loaded_entries() -> void:
	# Ensure ContentDB exposes the sampled IDs and reports its load summary.
	test_content_files_are_valid_json()
	var content_db := _get_autoload("ContentDB") as ContentDBBase
	assert_object(content_db).is_not_null()
	_assert_content_entry_loaded(
		"archetypes",
		_content_samples.get("archetypes", ""),
		func(id_value: String) -> bool:
			return not content_db.get_archetype(id_value).is_empty()
	)
	_assert_content_entry_loaded(
		"modifiers",
		_content_samples.get("modifiers", ""),
		func(id_value: String) -> bool:
			return not content_db.get_modifier(id_value).is_empty()
	)
	_assert_content_entry_loaded(
		"waves",
		_content_samples.get("waves", ""),
		func(id_value: String) -> bool:
			return not content_db.get_wave(id_value).is_empty()
	)
	var content_logs := content_db.get_log_entries()
	for category in CONTENT_DIRECTORIES.keys():
		assert_bool(_has_log_event(content_logs, "category_loaded", {"category": category})).is_true()
	assert_bool(_has_log_event(content_logs, "content_summary")).is_true()

func test_save_manager_flow_and_run_manager_transitions() -> void:
	# Verifies disk IO (save → reload) and screen navigation signals.
	var run_manager := _get_autoload("RunManager") as RunManagerBase
	var save_manager := _get_autoload("SaveManager") as SaveManagerBase
	assert_object(run_manager).is_not_null()
	assert_object(save_manager).is_not_null()
	var initial_logs := save_manager.get_log_entries()
	assert_bool(
		_has_log_event(initial_logs, "meta_loaded")
		or _has_log_event(initial_logs, "meta_defaulted")
	).override_failure_message(
		"SaveManager should log meta_loaded or meta_defaulted on startup"
	).is_true()
	var save_log_cursor := _make_log_cursor(save_manager)
	var reload_sample := {
		"save_version": 99,
		"total_currency": 314,
		"unlocks": ["skeleton_core_loop"],
	}
	save_manager.save_meta(reload_sample)
	var sample_entries := _pop_new_entries(save_log_cursor)
	assert_bool(_has_log_event(sample_entries, "meta_saved")).is_true()
	var reloaded_meta: Dictionary = save_manager.reload_meta_from_disk()
	var reload_entries := _pop_new_entries(save_log_cursor)
	assert_bool(_has_log_event(reload_entries, "meta_loaded")).is_true()
	assert_int(int(reloaded_meta.get("total_currency", -1))).is_equal(314)
	assert_array(reloaded_meta.get("unlocks", [])).is_equal(["skeleton_core_loop"])
	save_manager.clear_save()
	var cleared_entries := _pop_new_entries(save_log_cursor)
	assert_bool(_has_log_event(cleared_entries, "meta_cleared")).is_true()
	assert_bool(_has_log_event(cleared_entries, "run_cleared")).is_true()
	var log_probe := LogProbe.new()
	log_probe.attach_run_manager(run_manager)
	run_manager.go_to_menu()
	await _wait_frames(1)
	assert_bool(log_probe.has("screen_requested", {"screen": RunManagerBase.SCREEN_MAIN_MENU})).is_true()
	log_probe.clear()
	run_manager.start_run()
	await _wait_frames(1)
	assert_bool(log_probe.has("run_state_changed", {"state": RunManagerBase.RUN_STATE_SHIFT})).is_true()
	assert_bool(log_probe.has("screen_requested", {"screen": RunManagerBase.SCREEN_WARDROBE})).is_true()
	save_manager.clear_save()
	run_manager.end_shift()
	var save_entries := _pop_new_entries(save_log_cursor)
	var meta_saved_entry := _get_log_event(save_entries, "meta_saved")
	assert_dict(meta_saved_entry).is_not_empty()
	var saved_payload: Dictionary = meta_saved_entry.get("payload", {})
	var summary = run_manager.get_last_summary()
	var expected_total: int = summary.money if summary else 0
	var saved_data: Dictionary = saved_payload.get("data", {})
	assert_int(int(saved_data.get("total_currency", -1))).is_equal(expected_total)
	assert_str(str(saved_payload.get("path", ""))).is_equal(SaveManagerBase.META_SAVE_PATH)
	await _wait_frames(1)
	assert_bool(log_probe.has("screen_requested", {"screen": RunManagerBase.SCREEN_SHIFT_SUMMARY})).is_true()
	assert_bool(FileAccess.file_exists(SaveManagerBase.META_SAVE_PATH)).is_true()
	save_manager.clear_save()
	var final_entries := _pop_new_entries(save_log_cursor)
	assert_bool(_has_log_event(final_entries, "meta_cleared")).is_true()

func test_wardrobe_scene_receives_hud_updates() -> void:
	# Directly instantiates WardrobeScene and verifies HUD reacts to RunManager signals.
	var run_manager := _get_autoload("RunManager") as RunManagerBase
	assert_object(run_manager).is_not_null()
	run_manager.start_shift()
	var wardrobe: Node = auto_free(WARDROBE_SCENE.instantiate())
	get_tree().root.add_child(wardrobe)
	await _wait_frames(1)
	var money_label := wardrobe.get_node("HUDLayer/HUDContainer/HUDPanel/VBox/MoneyValue") as Label
	assert_object(money_label).is_not_null()
	var initial_value := _extract_label_value(money_label.text)
	run_manager.adjust_demo_money(3)
	await _wait_frames(1)
	var updated_value := _extract_label_value(money_label.text)
	assert_int(updated_value).is_greater(initial_value)
	wardrobe.queue_free()
	await _wait_frames(1)

func _assert_content_entry_loaded(category: String, sample_id: String, predicate: Callable) -> void:
	assert_str(sample_id).is_not_empty()
	assert_bool(predicate.call(sample_id)).override_failure_message(
		"ContentDB missing entry for %s:%s" % [category, sample_id]
	).is_true()

func _payload_matches(payload: Dictionary, expected: Dictionary) -> bool:
	for key in expected.keys():
		if payload.get(key) != expected[key]:
			return false
	return true

func _has_log_event(entries: Array, event_name: String, expected_payload: Dictionary = {}) -> bool:
	return not _get_log_event(entries, event_name, expected_payload).is_empty()

func _get_log_event(entries: Array, event_name: String, expected_payload: Dictionary = {}) -> Dictionary:
	for entry in entries:
		if entry.get("event") != event_name:
			continue
		var payload: Dictionary = entry.get("payload", {})
		if _payload_matches(payload, expected_payload):
			return entry
	return {}

func _make_log_cursor(source: Object) -> Dictionary:
	return {
		"source": source,
		"cursor": source.get_log_entries().size(),
	}

func _pop_new_entries(cursor: Dictionary) -> Array:
	var source: Object = cursor.get("source")
	if source == null:
		return []
	var entries: Array = source.get_log_entries()
	var start: int = int(cursor.get("cursor", 0))
	var result: Array = []
	for i in range(start, entries.size()):
		result.append(entries[i])
	cursor["cursor"] = entries.size()
	return result

func _extract_label_value(text: String) -> int:
	var parts := text.split(": ")
	if parts.size() < 2:
		return -1
	var value_text := parts[1].strip_edges()
	if value_text == "-":
		return -1
	return int(value_text)

func _wait_frames(count: int) -> void:
	for _i in range(count):
		await get_tree().process_frame

func _get_autoload(autoload_name: String) -> Node:
	return get_tree().root.get_node_or_null(autoload_name)
