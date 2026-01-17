# Light zone service investigation (2026-01-17)

## Context
A new service light zone (bulb rig + switch) was added under `ServiceZone/LightZone`, but it did not react to toggles or display the bulb state.
After wiring it, the service LightSwitch toggled BulbRow0/Bulb0 and rotated LightSwitch0 because it shared the same default row index.

## Repro
- Added integration coverage in `tests/integration/light/test_workdesk_light_zones_scene.gd` for the service light rig wiring.
- `GODOT_TEST_HOME="$PWD/.godot_test_home_persist" task tests` failed with `test_workdesk_service_light_rig_wiring`.

## Root cause
`WorkdeskScene` only calls `setup()` for the StorageHall bulbs and switches. The service light rig and switch were never wired to `LightService`, so their `_unhandled_input` guards short-circuited and visuals never updated.
The service light rig and switch also kept the default `row_index = 0`, which overlaps with `BulbRow0` and causes the shared bulb state to toggle.

## Fix
- Register the service bulb rig and switch in `WorkdeskScene` and call `setup()` alongside the existing light controls.
- The new test now toggles the service rig via `LightService` and asserts the visual state change.
- Assign a unique `row_index` to the service light rig and switch in `WorkdeskScene.tscn`.
- Extend the integration test to assert that toggling the service row does not enable row 0.
- Add `control_light_visual` to `BulbLightRig` so service lights can manage their own glow when not controlled by `LightZonesAdapter`.
- Enable `control_light_visual` on the service rig and assert the LightVisual visibility in the integration test.
- Connect the service light zone to `LightZonesAdapter` with a `service_zone_path` and a dedicated `service_row_index` so items are only lit when the service bulb is on.

## Tests
- `GODOT_TEST_HOME="$PWD/.godot_test_home_persist" task tests` (passes; still logs `get_system_ca_certificates` warning)
- `"$GODOT_BIN" --path .`

## Docs
- Godot 4.5 `Signal` API: https://docs.godotengine.org/en/4.5/classes/class_signal.html
