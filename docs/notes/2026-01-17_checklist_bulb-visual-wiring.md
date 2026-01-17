# Checklist: Bulb Visual Wiring

- [x] Inspect WorkdeskScene wiring between BulbLightRig, BulbVisual, and LightSwitch.
- [x] Update BulbLightRig `external_visual_path` to point at BulbVisual nodes.
- [x] Confirm BulbVisual continues forwarding `set_is_on` to LightSwitch.
- [x] Run `GODOT_TEST_HOME="$PWD/.godot_test_home_persist" task tests`.
- [x] Launch Godot once with `"$GODOT_BIN" --path .`.
