# Plan: Iteration 4.1 cleanup (targets, wave timer, swap contract)

## Goal

Lock the win condition to explicit shift targets sourced from wave config, keep client count independent from roster lists, and prevent legacy wave-fail logic from reappearing. Establish a visible contract for swap being disabled in MVP.

## Current status (verified)

- Targets no longer overwritten by `total_clients` and now sourced from wave config via `WardrobeStep3SetupAdapter`.
- Wave timer/fail path removed from `WorkdeskScene`.
- `client_count` is used for population; `clients` is used for archetype selection.

## Remaining work

1. **Swap contract**
   - Introduce a single explicit config flag for swap (e.g., `swap_enabled = false` or `swap_disabled = true`) in a content or app-layer config object.
   - Route resolver behavior through this flag (default false for MVP).
   - Update docs to state swap is disabled by contract, not just current implementation.

2. **Targets source-of-truth hardening**
   - Keep `target_checkin`/`target_checkout` derived from wave config only.
   - Guard against any reintroduction of `configure_shift_clients` setting targets.
   - If needed, add a lightweight unit test asserting `configure_shift_clients` does not change targets.

3. **HUD clarity (optional)**
   - If the wave timer is fully retired, consider hiding or repurposing time/wave UI labels to avoid misleading signals.

## Test/verification plan (when implementing)

- Run canonical tests:
  - `GODOT_TEST_HOME="$PWD/.godot_test_home_persist" task tests`
- Launch Godot once:
  - `"$GODOT_BIN" --path .`

## Open questions

- Should swap contract live in wave config, a global game config, or a small app-layer `ShiftSetup` object?
- Do we want the wave/time HUD removed or repurposed now that wave timer logic is gone?
