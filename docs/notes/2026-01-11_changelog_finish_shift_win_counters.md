# Changelog: Finish shift win counters (Iteration 4.1)

- Updated `docs/steps/i4.1_finish_shift_win_counters.md` to anchor checkout completion to `EVENT_CLIENT_COMPLETED` (treated as client left scene) and to require threading `client_id` for domain-level dedup.
- Clarified that thresholds must be injected from `content/waves` and removed ambiguous wording about other sources in the plan at `docs/steps/i4.1_finish_shift_win_counters.md`.
- Expanded analysis in `docs/notes/2026-01-11_analysis_finish_shift_win_counters.md` to reflect confirmed event mapping, `client_id` availability in event payloads, and the `content/waves` source-of-truth boundary.
- Added this changelog and a paired checklist note for Iteration 4.1 documentation updates.
- Added domain-level dedup for shift counters via `client_id` and updated counter APIs to accept ids across `RunState`, `ShiftService`, and `RunManagerBase`.
- Threaded `client_id` through the desk events bridge and workdesk handlers to ensure checkin/checkout events map to domain events deterministically.
- Sourced client counts from `content/waves` in `WardrobeStep3SetupAdapter` to align configured targets with wave definitions.
- Updated unit tests to pass `client_id` and added a dedup coverage check in `tests/unit/shift_service_win_test.gd`.
- Removed wave timer/fail path from `scripts/ui/workdesk_scene.gd` and its debug-only flag to avoid non-canon shift endings.
- Stopped `ShiftService.configure_shift_clients` from overwriting targets; targets now come only from `configure_shift_targets`.
- Added `client_count`, `target_checkin`, and `target_checkout` to `content/waves/wave_1.json` and use them via `WardrobeStep3SetupAdapter`.
- Decoupled `wave.clients` (archetype roster) from client count in `WardrobeStep3SetupAdapter`, keeping roster for archetype selection only.
- Added a unit test guarding against target overrides in `tests/unit/shift_service_win_test.gd`.
- Updated Iteration 4.1 status in `docs/steps/iteration_plan.md` to reflect config-driven targets and removal of total_clients override.
