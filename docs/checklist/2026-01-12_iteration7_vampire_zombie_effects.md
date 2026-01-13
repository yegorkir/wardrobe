# Iteration 7 Checklist

- [x] **Domain: Item Archetype**
    - [x] Add `archetype_id` to `ItemInstance`.
    - [x] Ensure initialization supports it.

- [x] **Domain: Effects API**
    - [x] Create `scripts/domain/effects/item_effect_types.gd` (Enums).
    - [x] Create `scripts/domain/effects/item_effect.gd` (Value Object).
    - [x] Create `scripts/domain/effects/item_effect_result.gd`.
    - [x] Add `apply_effect` to `ItemInstance` (delegating to Quality/Exposure).

- [x] **Domain: Vampire Exposure**
    - [x] Create `scripts/domain/magic/vampire_exposure_state.gd`.
    - [x] Create `scripts/domain/magic/vampire_exposure_system.gd`.
    - [x] Implement `tick_vampire_exposure`.

- [x] **Domain: Zombie Exposure**
    - [x] Create `scripts/domain/magic/zombie_exposure_state.gd`.
    - [x] Create `scripts/domain/magic/corruption_aura_service.gd`.
    - [x] Create `scripts/domain/magic/zombie_exposure_system.gd`.
    - [x] Implement `tick_zombie_exposure`.

- [x] **App: Integration**
    - [x] Update Shift/Game loop to tick exposure systems.
    - [x] Pass `is_in_light` and `is_dragging`.

- [x] **UI: Visuals**
    - [x] Add particles to item prefab.
    - [x] Script to control particles based on state.

- [ ] **Tests**
    - [ ] Test Vampire logic.
    - [ ] Test Zombie logic.
    - [ ] Verify determinism.
