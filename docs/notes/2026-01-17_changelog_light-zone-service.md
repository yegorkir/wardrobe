# Changelog: light-zone-service (2026-01-17)

- Added an integration test that reproduces the service light rig wiring failure by toggling the service bulb row and asserting the visual color in `tests/integration/light/test_workdesk_light_zones_scene.gd`.
- Confirmed the new test fails before the fix because the service rig/switch are never connected to `LightService` (visuals stay at default color).
- Wired the service bulb rig and switch into `WorkdeskScene` by adding `@onready` references and calling `setup()` during `_finish_ready_setup` in `scripts/ui/workdesk_scene.gd`.
- Assigned a dedicated `row_index` for the service bulb rig and switch in `scenes/screens/WorkdeskScene.tscn` to avoid clobbering `BulbRow0`.
- Updated the service light rig integration test to assert that toggling the service row does not flip row 0 state.
- Added a `control_light_visual` option to `scripts/wardrobe/lights/bulb_light_rig.gd` and enabled it on the service rig so its LightVisual glow toggles with the service switch.
- Expanded the service light rig test to assert the LightVisual visibility toggles alongside the bulb color.
- Wired the service light zone into `LightZonesAdapter` using `service_zone_path`/`service_row_index` so item lighting respects the service bulb state.
- Extended the integration test to cover `is_item_in_light` for the service zone when the service bulb is toggled.
- Re-ran the canonical test suite with the new wiring; all tests pass (one existing `get_system_ca_certificates` warning remains).
- Launched Godot once with `"$GODOT_BIN" --path .` to validate runtime startup after the change.
