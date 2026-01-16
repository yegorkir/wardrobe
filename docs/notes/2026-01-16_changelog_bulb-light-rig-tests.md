# 2026-01-16 — Changelog: bulb light rig tests

## Summary
- Moved BulbLightRig tests out of `tests/unit/` to keep unit tests SceneTree-free per `tests/AGENTS.md`.

## Details
- Relocated `BulbLightRigTest` to the integration tier so Node/SceneTree usage stays outside unit coverage.
- Kept test logic unchanged to avoid behavior drift while restoring the unit-test contract.
- Removed the duplicated `test_external_visual_with_callback` definition to fix a parse error after relocation.
- Dropped `class_name BulbLightRigTest` to avoid global class name conflicts in test runs.

## References
- Godot 4.5 `SceneTree` class: https://docs.godotengine.org/en/4.5/classes/class_scenetree.html
