# Checklist: Wrong item fall

- [x] Extend event schema with wrong-item reason, drop event, penalty event, and reject payload fields.
- [x] Implement desk reject consequence policy and idempotent outcome system.
- [x] Add deterministic floor resolver and configure from SurfaceRegistry floors in scenes.
- [x] Wire UI adapter to perform reject drops and preserve landing cause.
- [x] Add archetype-level wrong-item penalty data and pass into client state.
- [x] Update tests for reject policy, outcome idempotency, and penalty strike transition.
- [x] Apply wrong-item consequences for drop-off rejects.
- [x] Emit drop-off reject for non-ticket items on desk.
- [x] Run `GODOT_TEST_HOME="$PWD/.godot_test_home_persist" task tests` (warnings present: landing behavior class name conflicts + `ret != noErr` message).
- [x] Run `"$GODOT_BIN" --path .` to validate startup (command timed out after launch output).
