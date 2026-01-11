# 2026-01-11 — Changelog: Step3 win + queue mix

- Added canonical shift counters (`checkin_done`, `checkout_done`, targets, derived needs) to `RunState` and exposed queue-mix snapshots via `ShiftService`.
- Replaced shift win policy inputs with `RunState`, updated win payloads to emit check-in/check-out counters, and exposed new RunManager APIs for check-in/check-out completion.
- Updated Workdesk flow to register check-in (drop-off accepted) and check-out (client completed) events, and set shift targets per wave.
- Implemented a queue mix policy and extended queue state to track separate check-in/check-out pools with fallback selection.
- Wired desk service point selection to use queue mix snapshots and updated queue tests to cover the new pools and policy behavior.
