# Checklist: light-zone-service (2026-01-17)

- [x] Reviewed `WorkdeskScene` lighting setup to find missing service rig/switch wiring.
- [x] Added `test_workdesk_service_light_rig_wiring` to reproduce the missing wiring by toggling the service bulb and checking the rig visual state.
- [x] Ran `GODOT_TEST_HOME="$PWD/.godot_test_home_persist" task tests` and observed the new test fail before the fix.
- [x] Added `@onready` references for `ServiceZone/LightZone/BulbLightRig` and `ServiceZone/LightZone/LightSwitch`, then wired them with `setup(_light_service)` during `_finish_ready_setup`.
- [x] Updated the service bulb rig and switch to use a unique `row_index` so they do not toggle `BulbRow0`.
- [x] Extended the service light rig integration test to confirm toggling the service row does not affect row 0.
- [x] Added `control_light_visual` to `BulbLightRig` and enabled it on the service rig to toggle the glow independently of `LightZonesAdapter`.
- [x] Verified the integration test asserts LightVisual visibility changes with the service bulb state.
- [x] Connected the service zone path and row index in `LightZonesAdapter` so `is_item_in_light` reflects the service bulb state.
- [x] Updated the service light rig integration test to verify service zone lighting toggles with the service bulb.
- [x] Re-ran `GODOT_TEST_HOME="$PWD/.godot_test_home_persist" task tests` and confirmed the suite passes (only existing CA cert warning logged).
- [x] Launched Godot with `"$GODOT_BIN" --path .` to confirm the project starts after changes.
