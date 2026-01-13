# Iteration 7 (7A/7B) — Summary Status Check (2026-01-13)

## What appears completed
- Item archetype id on items + snapshots.
- Unified effect API (`ItemEffect*`) and `apply_effect`.
- Vampire and zombie exposure systems + aura rate service.
- Exposure tick integration in `WorkdeskScene`.
- Aura particle visuals in `ItemNode`.
- Unit tests for exposure logic and aura service.

## Outstanding or unverified
- Weak aura propagation radius likely ineffective for non-zombie items (radius is `0.0` for normal archetypes).
- Aura service does not expose affecting-source lists for logs/debug.
- Vampire exposure UI progress indicator not implemented.
- Deterministic scenario/integration tests missing.
- Latest test logs show parser errors in `item_instance.gd` for `ItemEffect*`; tests need re-run/verification.
- Checklist/changelog not updated to match current state.
