# Changelog: Iteration 4.1 cleanup plan (targets, wave timer, swap contract)

- Added a dedicated plan note capturing remaining work around swap contract, target source-of-truth hardening, and optional HUD cleanup in `docs/notes/2026-01-11_plan_iteration4_1_cleanup_targets_wave_timer.md`.
- Introduced an interaction config object with an explicit `swap_enabled` flag and wired it into the interaction resolver/service to formalize swap-disabled behavior (`scripts/app/interaction/interaction_config.gd`, `scripts/app/interaction/pick_put_swap_resolver.gd`, `scripts/app/interaction/interaction_service.gd`, `scripts/domain/interaction/interaction_engine.gd`).
- Documented the swap-disabled contract as a config flag in `docs/design_document.md`.
- Added a unit test to ensure `configure_shift_clients` does not override configured shift targets in `tests/unit/shift_service_win_test.gd`.
- Updated `InteractionConfig.duplicate_config()` to use `get_script().new()` to satisfy headless parse checks in `scripts/app/interaction/interaction_config.gd`.
