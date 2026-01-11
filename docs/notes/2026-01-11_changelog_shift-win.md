# 2026-01-11 — Changelog: Shift win doc setup

- Added Shift win state fields to `RunState` for total/served/active client tracking.
- Added `ShiftWinPolicy` (app-layer) and ShiftService hooks to evaluate win conditions and emit `shift_won`.
- Logged shift win/fail outcomes into ShiftLog and surfaced end reasons in shift summary payload.
- Routed win completion through RunManager signal handling; WorkdeskScene now reports progress instead of ending shift directly.
- Added unit tests for win policy and ShiftService win/fail behavior.
