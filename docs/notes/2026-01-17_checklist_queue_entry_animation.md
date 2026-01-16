# Checklist: Queue Entry Animation

- [x] Locate the queue HUD entry animation code and the QueueHud layout nodes.
- [x] Add QueueKpis anchor reference and animation constants for the new entry motion.
- [x] Implement queue item tween from QueueKpis to the target slot and restore container layout afterward.
- [x] Keep a minimal fallback append animation if QueueKpis is missing.
- [x] Increase entry travel distance to make the new animation visibly longer.
- [x] Align entry start with QueueItems right edge per feedback.
- [x] Run `GODOT_TEST_HOME="$PWD/.godot_test_home_persist" task tests`.
- [x] Launch Godot once via `"$GODOT_BIN" --path .` (startup logs observed; command timed out after 5s).
