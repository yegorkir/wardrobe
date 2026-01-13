# Changelog: Aura Transfer Delay

## 2026-01-13
- Added `pending_transfers` dictionary to `ZombieExposureState` to track delay before corruption starts.
- Added helper methods `set_pending`, `clear_pending`, `tick_pending`, `is_active`, `get_active_sources` to `ZombieExposureState`.
- Implemented `get_potential_sources` in `CorruptionAuraService` to identify sources in range before applying delay.
- Updated `ExposureService.tick` to:
    - Compute distance-based transfer delay (`t = clamp(distance / speed, min, max)`).
    - Manage `pending_transfers` state (decrement, clear if out of range).
    - Calculate exposure rate only from active sources (`pending <= 0`).
    - Use fractional exposure for the tick where delay completes.
- Fixed `ExposureService` to use typed empty arrays (`Array[StringName]`) when calling `tick` on systems, preventing runtime type errors.
- Added unit tests in `tests/unit/domain/magic/test_aura_transfer_delay.gd` covering:
    - Delayed corruption start.
    - Multiple sources with staggered activation.
    - Resetting pending state on exit/re-enter.
- Updated `tests/unit/domain/magic/exposure_test.gd` to account for transfer delay in `test_zombie_domino_aura_propagation`.
