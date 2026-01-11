# Checklist: Patience Strikes Lose

- [x] Locate patience tick and failure flow in `WorkdeskScene`.
- [x] Add `ShiftPatienceState` + `ShiftPatienceSystem` to own patience/strike state outside UI.
- [x] Extend `ShiftService` with strike config, patience snapshots, strike logging, and `shift_failed` emission.
- [x] Update `RunManagerBase` to configure/tick patience and end shift on `shift_failed`.
- [x] Refactor `WorkdeskScene` to tick patience through the app layer and refresh UI snapshots.
- [x] Add `StrikesValue` HUD labels and wire `WardrobeHudAdapter` to render strike counts.
- [x] Update `ShiftSummary` to display shift status and strikes.
- [x] Add unit tests for strike transitions, no double counting, and fail-at-limit signaling.
- [x] Run `GODOT_TEST_HOME="$PWD/.godot_test_home_persist" task tests`.
- [x] Launch Godot once with `"$GODOT_BIN" --path .`.
