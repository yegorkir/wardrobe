# Checklist: Remove drag shake

- [x] Locate drag-warning shake logic in `CursorHand` and confirm it is the sole source of drag jitter.
- [x] Remove the looping shake tween while preserving warning icon visibility and color feedback.
- [x] Ensure held item position snaps back to the cursor anchor whenever warning state changes.
- [x] Run `GODOT_TEST_HOME="$PWD/.godot_test_home_persist" task tests` and capture the result.
- [x] Launch `"$GODOT_BIN" --path .` once to validate runtime startup (timed out after logs appeared).
