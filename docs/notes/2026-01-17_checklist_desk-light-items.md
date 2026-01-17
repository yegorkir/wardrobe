# Checklist: desk-light-items (2026-01-17)

- [x] Reviewed `LightZonesAdapter` and `BulbLightRig` behavior to confirm where light zone rects are sourced.
- [x] Identified that `BulbLightRig` only updates collision geometry in editor mode, leaving runtime shapes at prefab defaults.
- [x] Added an integration assertion for the service light zone size in `tests/integration/light/test_workdesk_light_zones_scene.gd` to lock the expected runtime dimensions.
- [x] Updated `scripts/wardrobe/lights/bulb_light_rig.gd` so `_ready()` applies zone geometry, visual params, and layout in runtime.
- [x] Aligned `CollisionShape2D.position` to half the zone size so the service light rect matches the configured rig origin.
- [x] Added `test_workdesk_service_light_affects_desk_slot` to lock the service light coverage over a desk tray slot position.
- [x] Routed `LightZonesAdapter` to the `ServiceLightZone` rig and aligned it to cover the desk slots.
- [x] Ran `GODOT_TEST_HOME="$PWD/.godot_test_home_persist" task tests` after the change (exit 0, with existing CA cert error line and a slow test-scan warning).
- [x] Ran `GODOT_TEST_HOME="$PWD/.godot_test_home_persist" task tests` after the latest update (exit 0, with existing CA cert error line).
- [x] Launched Godot with `"$GODOT_BIN" --path .` to confirm the project starts (log included existing Nil assignment, missing `get_run_state`, and lambda-capture freed errors).
