# 2026-01-16 — Checklist: bulb light rig tests

- [x] Reviewed `tests/AGENTS.md` unit-test constraints and confirmed Node/SceneTree usage is disallowed in `tests/unit/`.
- [x] Inspected `tests/unit/wardrobe/lights/test_bulb_light_rig.gd` for Node/SceneTree usage and confirmed the test is not pure logic.
- [x] Moved BulbLightRig tests into `tests/integration/wardrobe/lights/` to align with the test pyramid.
- [x] Removed the duplicated `test_external_visual_with_callback` to resolve the GDScript parse error.
- [x] Removed the `class_name` registration to avoid global class conflicts in tests.
- [x] Run `GODOT_TEST_HOME="$PWD/.godot_test_home_persist" task tests` (warnings present; see task output).
- [x] Launch Godot with `"$GODOT_BIN" --path .` (timed out after 10s but project boot logged).
