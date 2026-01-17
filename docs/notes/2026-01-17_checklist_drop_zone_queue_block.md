# Checklist: drop zone blocks desk assignment

- [x] Review desk assignment flow and identify that it ignores drop zone occupancy.
- [x] Add a drop-zone blocker callback to `DeskServicePointSystem`.
- [x] Build a drop-zone index in `WorkdeskScene` and wire the blocker.
- [x] Add item overlap detection to `ClientDropZone`.
- [x] Add a unit test for the blocker behavior.
- [x] Add debug logs for drop zone blocking and desk assignment skips.
- [x] Add drop zone overlap diagnostics and desk assignment pre-check logs.
- [x] Enforce drop zone collision settings before overlap checks.
- [x] Block desk assignment when tray slots contain items and add coverage.
- [x] Clear desk assignment and mark clients away after ticket delivery when tray items block assignment.
- [x] Trigger desk assignment when a tray slot is emptied.
- [x] Run `GODOT_TEST_HOME="$PWD/.godot_test_home_persist" task tests` (log shows `ERROR: Condition "ret != noErr" is true. Returning: ""` but exit code was 0).
- [x] Run `"$GODOT_BIN" --path .`.
