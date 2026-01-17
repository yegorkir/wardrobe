# Checklist: Desk Client Exit Animation

- [x] Locate desk client UI flow, completion events, and desk assignment blockers to identify a safe exit animation hook.
- [x] Implement exit tween support in `scripts/ui/workdesk_clients_ui_adapter.gd`, including leftward motion, fade-out, scale-down, and cleanup on completion.
- [x] Track desk exit blocking state in `scripts/ui/workdesk_clients_ui_adapter.gd` and expose it to prevent early desk assignment.
- [x] Trigger exit animation on client completion in `scripts/ui/workdesk_scene.gd` and integrate exit blocking into `_is_drop_zone_blocked`.
- [x] Trigger exit animation on client phase change (drop-off → pick-up) so the desk client visibly leaves at ticket handoff.
- [x] Run `GODOT_TEST_HOME="$PWD/.godot_test_home_persist" task tests` (completed with log line: `ERROR: Condition "ret != noErr" is true. Returning: ""`, exit code 0).
- [x] Launch Godot once with `"$GODOT_BIN" --path .` (startup logs observed; command exited after ~15s timeout window).
