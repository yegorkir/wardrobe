# Checklist: Dynamic Zombie Aura

- [x] **Analysis & Plan**
    - [x] Design dynamic radius formula: `(stage + innate) * radius_per_stage`.
    - [x] Design Clean Architecture compatible config injection.

- [x] **Domain Configuration**
    - [x] Create `ZombieExposureConfig` (POJO).
    - [x] Add `zombie_innate_stage` to `ItemArchetypeDefinition`.

- [x] **Logic Updates**
    - [x] `ZombieExposureSystem`: Inject config, use `quality_loss_per_stage` (0.5) and `exposure_threshold`.
    - [x] `ZombieExposureState`: Remove legacy `is_emitting_weak_aura`.
    - [x] `ExposureService`: Implement dynamic radius calculation in `tick`.
    - [x] `ExposureService`: Add `get_item_aura_radius` for UI.

- [x] **Quality System Fixes**
    - [x] Update `ItemEffectResult`: Change `quality_loss` from `int` to `float`.
    - [x] Update `ItemInstance.apply_effect`: Support fractional `intensity` and `actual_loss`.

- [x] **UI & Integration**
    - [x] `WorkdeskScene`: Add `@export` variables for zombie balance.
    - [x] `WorkdeskScene`: Use dynamic radius for aura particles.
    - [x] `WorkdeskScene`: Pass `innate_stage` for "True Zombie" archetypes.

- [x] **Verification**
    - [x] Fixed script compilation errors.
    - [x] Verified Godot launch.
    - [x] Verified log output for fractional loss (loss=0.5 logic).
