# 2026-01-11 — Checklist: Step3 win + queue mix

- [x] Added shift targets and check-in/check-out counters in `RunState` with derived `need_in/need_out/outstanding` helpers.
- [x] Updated `ShiftWinPolicy` to evaluate canonical shift state only and ignore active-client blocking.
- [x] Introduced RunManager + ShiftService APIs for registering check-in and check-out completion and queue mix snapshots.
- [x] Hooked Workdesk desk events to emit check-in/check-out completion and configured per-shift targets.
- [x] Added queue mix policy + dual-pool queue state, wired selection into desk assignments with fallback behavior.
- [x] Updated and added unit tests for shift win, queue pools, and queue mix policy rules.
