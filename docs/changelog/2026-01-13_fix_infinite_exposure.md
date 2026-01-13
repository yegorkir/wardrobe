# Changelog: Fix Infinite Zombie Exposure Stages

## 2026-01-13
- Fixed a bug where zombie exposure stages would continue to increment indefinitely for items that had already lost all quality.
- Updated `ZombieExposureSystem.tick` to check `item.quality_state.current_stars`. If the item is fully corrupted (stars <= 0), exposure accumulation stops and the exposure state is reset.
