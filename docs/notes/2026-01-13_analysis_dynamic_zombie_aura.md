# Analysis: Dynamic Zombie Aura (Iteration 7 Refinement)

## Goal
Replace the binary "Weak Aura" vs "Full Zombie" mechanic with a unified, scalable system where **Aura Radius** and **Quality Loss** are functions of the **Corruption Stage**. True Zombie items should simply be items with a high "base stage".

## Current State
- `ZombieExposureState`: Tracks `stage_index` and `is_emitting_weak_aura`.
- `ExposureService`: Uses fixed `WEAK_AURA_RADIUS` (100.0) or Archetype radius.
- `ZombieExposureSystem`: Applies fixed damage (1.0) on stage transition.
- **Problem:** Rigid separation between "weak" and "strong". Hardcoded values. No gradual progression.

## Domain Model Changes
### 1. `ZombieExposureConfig` (New Value Object)
To adhere to Clean Architecture, config should be a POJO (RefCounted) injected into systems, not a Global/Resource accessed directly.
- `radius_per_stage`: float (Default: 50.0)
- `quality_loss_per_stage`: float (Default: 0.5)
- `exposure_threshold`: float (Default: 3.0)

### 2. `ZombieExposureState`
- Remove `is_emitting_weak_aura`. It is now implicit (`stage > 0`).
- The "effective stage" for radius calculation needs to account for the item's archetype nature.
    - *Option A:* Store `base_stage` in state.
    - *Option B:* Pass `base_stage` from `ItemArchetypeDefinition` during tick.
    - *Selected:* **Option B**. State tracks *accumulated* corruption. Archetype defines *innate* corruption. Total Stage = `accumulated + innate`.

### 3. `ItemArchetypeDefinition`
- Add `zombie_innate_stage`: int.
    - Regular items: 0.
    - Zombie items: configurable (e.g., 6 or 10).

## Logic Updates
### `ExposureService` (Orchestrator)
- **Radius Calculation:**
  `radius = (state.stage_index + archetype.zombie_innate_stage) * config.radius_per_stage`
- **Source Strength:**
  Depends on stage? Currently strength is 1.0. Let's keep it 1.0 for now, or make it stage-dependent later if needed. The request specifically mentioned radius.

### `ZombieExposureSystem` (Rules)
- **Damage:**
  On stage up, apply `ItemEffect(ZOMBIE_AURA, config.quality_loss_per_stage)`.
- **Termination:**
  Logic for stopping at `quality <= 0` remains (implemented in previous fix).

## UI/Visuals
- `WorkdeskScene` must calculate visual radius using the same formula (`total_stage * radius_per_stage`) to sync particles with domain logic.
- `ItemNode` particles need to scale.

## Architecture & Dependecies
- Config should be defined in `scripts/wardrobe/config/` but mapped to a Domain object.
- Tests will need updated mocks for `ZombieExposureConfig`.

## Risks
- **Performance:** Dynamic radius calculation per tick is cheap (multiplication).
- **Balance:** 0.5 damage per stage means items live twice as long (assuming 3 stars). Radius growing by 50px might cover the whole table quickly (Stage 10 = 500px).
- **UI:** Partial stars (0.5 loss) must be supported by `ItemVisuals`.
