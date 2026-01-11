# Changelog: Patience Strikes Lose

- Added `ShiftPatienceState` and `ShiftPatienceSystem` to own patience countdowns and strike increments outside UI.
- Extended `ShiftService` with strike config, patience snapshots, strike event logging, and `shift_failed` emission.
- Updated `RunManagerBase` to configure/tick patience and end shifts when `shift_failed` fires.
- Reworked `WorkdeskScene` patience ticking to call the app layer and removed fail-on-zero UI logic.
- Added strike HUD fields to `WardrobeHudAdapter`, plus `StrikesValue` labels in Workdesk/Wardrobe HUD scenes.
- Added strike/status rendering to `ShiftSummary`.
- Added unit tests covering strike transitions, no-double-counting, active-client ticking, and fail-at-limit signaling.
- Ran `task tests` and verified project startup via `"$GODOT_BIN" --path .`.
