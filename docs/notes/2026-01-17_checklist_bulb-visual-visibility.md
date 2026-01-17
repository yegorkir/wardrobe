# Checklist: Bulb Visual Visibility

- [x] Inspect BulbVisual prefab to verify default sprite visibility.
- [x] Hide BulbOn by default so the off state is visible before toggles.
- [x] Resolve the external visual via NodePath to avoid serialized node mismatch.
- [ ] Run `GODOT_TEST_HOME="$PWD/.godot_test_home_persist" task tests`.
- [ ] Launch Godot once with `"$GODOT_BIN" --path .`.
