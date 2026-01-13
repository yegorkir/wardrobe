# Plan: Dynamic Zombie Aura

## 1. Domain Configuration
- Create `scripts/domain/magic/zombie_exposure_config.gd` (RefCounted).
    - Fields: `radius_per_stage`, `quality_loss_per_stage`, `exposure_threshold`.
    - Defaults: 50.0, 0.5, 3.0.

## 2. Archetype Update
- Update `scripts/domain/content/item_archetype_definition.gd`.
    - Add `zombie_innate_stage: int` (default 0).
    - Update constructors/loaders to accept this.

## 3. System Refactor (`ZombieExposureSystem`)
- Inject `ZombieExposureConfig` into `_init`.
- Remove `WEAK_AURA` constant logic.
- Update `tick`:
    - Use `config.quality_loss_per_stage` for effect intensity.
    - Use `config.exposure_threshold`.

## 4. Service Refactor (`ExposureService`)
- Inject `ZombieExposureConfig`.
- Update `tick`:
    - Calculate radius: `(state.stage_index + archetype.zombie_innate_stage) * config.radius_per_stage`.
    - Remove `WEAK_AURA_RADIUS` constant.
    - Remove `is_emitting_weak_aura` checks (replaced by `radius > 0`).

## 5. Visuals & UI
- Update `WorkdeskScene.gd`:
    - Use `ExposureService` logic (or helper) to get visual radius for particles.
    - Ensure `ItemNode.set_emitting_aura` accepts the dynamic radius.

## 6. Tests
- Update `tests/unit/domain/magic/exposure_test.gd`:
    - Inject mock/default config.
    - Verify 0.5 damage application.
    - Verify radius scaling with stage.

## 7. App Integration
- In `WorkdeskScene` (or `WardrobeWorldSetup`), instantiate `ZombieExposureConfig` and pass it to services.
- Define "True Zombie" archetypes with `innate_stage = 5` (approx equivalent to old 250px radius? 5 * 50 = 250).
