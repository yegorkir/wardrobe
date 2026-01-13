# Changelog: Dynamic Zombie Aura

## 2026-01-13
- **Unified Progression System**: Replaced the binary "weak aura" mechanic with a unified system where aura radius grows with the corruption stage.
- **Dynamic Radius**: Aura radius is now calculated as `(accumulated_stage + innate_stage) * radius_per_stage`.
- **Configurable Balance**:
    - Created `ZombieExposureConfig` to centralize balance parameters.
    - Added `@export` variables to `WorkdeskScene` for real-time adjustment in the Godot Inspector (`radius_per_stage`, `quality_loss_per_stage`, `exposure_threshold`).
- **Archetype Enhancements**: Added `zombie_innate_stage` to archetypes. "True Zombies" (e.g., zombie_rag) now start with a high innate stage (e.g., 5), giving them a large initial radius.
- **Fractional Quality Loss**:
    - Updated the quality system (`ItemInstance`, `ItemEffectResult`) to support `float` loss.
    - Set default zombie corruption loss to `0.5` stars per stage.
- **Visuals**:
    - Updated `WorkdeskScene` to use the dynamic radius for `ItemNode` aura particles.
    - Particles now accurately reflect the item's growing threat level.
- **Bugfixes**:
    - Fixed compilation errors in `ExposureService` due to variable naming typos.
    - Fixed a bug where fractional quality loss was being truncated to `0` in logs and calculations.
