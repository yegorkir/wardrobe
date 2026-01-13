# Checklist: Fix Infinite Zombie Exposure Stages

- [x] **Analysis**
    - [x] Identify cause: `ZombieExposureSystem` continues to increment stages even when `item.quality_state.current_stars` is 0.
    - [x] Verify `ItemInstance` and `ItemQualityState` structure.

- [x] **Implementation**
    - [x] Update `ZombieExposureSystem.tick`:
        - [x] Check if `item.quality_state.current_stars <= 0.0`.
        - [x] If true, call `state.reset_exposure_only()` and return early.

- [x] **Verification**
    - [x] Run unit tests to ensure no regressions.
    - [x] (Optional) Verify via logs that `ZOMBIE_STAGE_COMPLETE` stops appearing for dead items.
