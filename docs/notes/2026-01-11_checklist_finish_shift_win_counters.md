# Checklist: Finish shift win counters (Iteration 4.1)

- [x] Update plan to map checkout completion to `EVENT_CLIENT_COMPLETED` and require `client_id` threading for dedup.
- [x] Update plan to note `content/waves` as the single source of target thresholds.
- [x] Update analysis with confirmed event mapping and `client_id` payload availability.
- [x] Update analysis to reflect the config boundary (`content/waves` -> app layer).
- [x] Record documentation updates in a dedicated changelog note.
- [x] Add domain-level dedup for checkin/checkout counters keyed by `client_id`.
- [x] Thread `client_id` through desk event bridge and workdesk handlers for counter updates.
- [x] Align client count creation with `content/waves` to keep targets config-driven.
- [x] Update unit tests for new counter APIs and add dedup coverage.
- [x] Remove wave timer/fail logic and debug-only flag from `scripts/ui/workdesk_scene.gd`.
- [x] Prevent `configure_shift_clients` from overwriting shift targets.
- [x] Add target fields to `content/waves/wave_1.json` and read them in `WardrobeStep3SetupAdapter`.
- [x] Split `wave.clients` roster from client count to avoid accidental shortening.
- [x] Add a test to guard against target override regressions.
- [x] Update Iteration 4.1 status in `docs/steps/iteration_plan.md`.
