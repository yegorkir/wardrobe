# Checklist: Aura Transfer Delay

- [x] **State Model**
    - [x] Add `pending_transfers` to `ZombieExposureState`.
    - [x] Add helper methods (`set_pending`, `tick_pending`, etc.).

- [x] **ExposureService Integration**
    - [x] Implement distance-based transfer delay calculation.
    - [x] Track pending transfers per target/source.
    - [x] Calculate effective rate only from active sources.
    - [x] Ensure fractional exposure for partial ticks.
    - [x] Fix type safety for `tick` calls (typed empty arrays).

- [x] **CorruptionAuraService**
    - [x] Implement `get_potential_sources`.

- [x] **Tests**
    - [x] `test_transfer_delay_prevents_immediate_corruption`
    - [x] `test_multiple_sources_staggered_activation`
    - [x] `test_exit_and_reenter_resets_pending`
    - [x] Verify `test_zombie_domino_aura_propagation` passes with delay.
    - [x] Verify no regressions in existing tests.

- [x] **Verification**
    - [x] Run all tests (passed).
    - [x] Launch Godot and verify runtime behavior (no script errors).
