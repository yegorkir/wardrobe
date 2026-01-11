# 2026-01-11 — Patience strikes lose (implementation notes)

## Summary
- Moved patience + strike tracking into app/domain state (`ShiftPatienceState`, `ShiftPatienceSystem`, `ShiftService`).
- Added strike fields to HUD snapshots and shift summary, plus a `shift_failed` signal to reuse the existing end-shift flow.
- Updated Workdesk patience ticking to call the app layer and removed UI-owned fail-on-zero behavior.
- Added strike HUD labels to Workdesk/Wardrobe screens and unit tests for strike transitions + failure threshold.

## Decisions
- Keep strike counting in `ShiftService` with `ShiftPatienceState` as the single source of truth; UI only reads snapshots.
- Use `shift_failed` to trigger `RunManager.end_shift()` so failure reuses the existing summary flow.

## References
- Signals (emit/connect): https://docs.godotengine.org/en/4.5/getting_started/step_by_step/signals.html
- Dictionary.duplicate (snapshot copies): https://docs.godotengine.org/en/4.5/classes/class_dictionary.html#class-dictionary-method-duplicate
