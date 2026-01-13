# 2026-01-12 Iteration 7: Vampire/Zombie Effects

## Context
Implementing vampire light corrosion and zombie aura mechanics as per [Plan](../notes/2026-01-12_plan_iteration7_vampire_zombie_effects.md) and [Analysis](../notes/2026-01-12_analysis_iteration7_vampire_zombie_effects.md).

## Changes

### Domain
- [ ] Add `archetype_id` to `ItemInstance`.
- [ ] Create `ItemEffectType`, `EffectSourceType`, `ItemEffect`, `ItemEffectResult` in `scripts/domain/effects/`.
- [ ] Add `apply_effect` to `ItemInstance` (or new service).
- [ ] Implement `VampireExposureState` and `VampireExposureSystem`.
- [ ] Implement `ZombieExposureState`, `CorruptionAuraService`, and `ZombieExposureSystem`.

### App
- [ ] Integrate exposure systems into the main shift loop.
- [ ] Wire up adapters to provide data.

### UI
- [ ] Add `Particles2D` to `ItemNode`.
- [ ] Visual feedback for Zombie Aura.

### Content
- [ ] Update item definitions to include archetype IDs (if applicable, or just runtime for now).

### Tests
- [ ] Unit tests for exposure logic.
- [ ] Integration tests.
