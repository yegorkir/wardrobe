# Changelog: Desk Client Exit Animation

- Added exit animation constants in `scripts/ui/workdesk_clients_ui_adapter.gd` to control leftward movement, fade-out, and scaling during desk departure.
- Added exit tween handling in `scripts/ui/workdesk_clients_ui_adapter.gd` to play the leave animation, suppress patience bar visuals during exit, and reset visuals when complete.
- Added per-desk exit blocking state in `scripts/ui/workdesk_clients_ui_adapter.gd` so desk assignment waits until the animation finishes.
- Connected client completion events to the UI exit flow in `scripts/ui/workdesk_scene.gd` so departures trigger the animation immediately on completion.
- Expanded desk blocking logic in `scripts/ui/workdesk_scene.gd` to treat an active exit animation as a blocker alongside drop zone items.
- Triggered desk exit animation on client phase change (drop-off → pick-up) in `scripts/ui/workdesk_scene.gd` to match desk-leave timing.
- Re-ran `GODOT_TEST_HOME="$PWD/.godot_test_home_persist" task tests` (exit code 0; log included `ERROR: Condition "ret != noErr" is true. Returning: ""`).
- Ran `"$GODOT_BIN" --path .` to validate startup (logs observed within ~15s).
- Ran `GODOT_TEST_HOME="$PWD/.godot_test_home_persist" task tests` (exit code 0; log included `ERROR: Condition "ret != noErr" is true. Returning: ""`).
- Attempted `"$GODOT_BIN" --path .` for the required launch check; the command timed out after ~10s while producing startup logs.
