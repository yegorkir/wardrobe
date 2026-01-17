# Changelog: desk-light-items (2026-01-17)

- Added a service light zone size assertion in `tests/integration/light/test_workdesk_light_zones_scene.gd` to reproduce the mismatch between configured `zone_width`/`zone_height` and the runtime collision shape.
- Observed the service light collision shape remain at the prefab default size prior to the fix, causing items on the desk to be reported as not in light.
- Updated `scripts/wardrobe/lights/bulb_light_rig.gd` to apply zone geometry, visual parameters, and layout in `_ready()` for runtime as well as editor.
- Adjusted `scripts/wardrobe/lights/bulb_light_rig.gd` to align `CollisionShape2D.position` with half the zone size so the light rect matches the configured rig origin.
- Added `test_workdesk_service_light_affects_desk_slot` in `tests/integration/light/test_workdesk_light_zones_scene.gd` to assert a desk tray slot position is lit only when the service bulb is on.
- Confirmed the workdesk service light zone now reports the configured dimensions in the integration test.
- Updated `scenes/screens/WorkdeskScene.tscn` to route the service light checks through `ServiceLightZone`, aligned it left, and bound it to the service bulb row.
- Adjusted the service light integration test to use the service zone rig dimensions and its collision shape.
- Re-ran `GODOT_TEST_HOME="$PWD/.godot_test_home_persist" task tests` after the fix; suite exited 0 with the existing CA cert error line.
- Launched Godot with `"$GODOT_BIN" --path .` to validate runtime startup; log included pre-existing `Nil` assignment and `get_run_state` errors, plus the lambda-capture freed error.
