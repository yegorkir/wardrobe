# Checklist: Bulb Visual Dual Routing

- [x] Set LightSwitch to toggle LightService directly.
- [x] Update BulbLightRig to react to bulb changes and forward `set_is_on` to BulbVisual.
- [x] Wire BulbRow rigs to BulbVisual and configure LightSwitch row metadata.
- [x] Preserve external-only click handling when external visuals are present.
- [x] Run `GODOT_TEST_HOME="$PWD/.godot_test_home_persist" task tests`.
- [x] Launch Godot once with `"$GODOT_BIN" --path .`.
