# Aura self-exclusion tests (2026-01-13)

## Summary
- Added unit coverage for aura self-exclusion.
- Added a domino propagation test to ensure weak aura spreads to a third item after the first corruption stage.
- Added stage gating test: sources only affect targets with a lower corruption stage.

## Files touched
- `tests/unit/domain/magic/exposure_test.gd`
