# Checklist: Iteration 9 (Ghost Darkness Rule)

## Domain
- [x] Add `is_ghost` and `ghost_dark_alpha` to `ItemArchetypeDefinition`.
- [x] Create `scripts/domain/interaction/interaction_rules.gd`.
- [x] Implement `InteractionRules.can_pick(archetype, is_in_light)`.

## Visuals
- [x] Add `play_reject_effect()` to `ItemNode`.

## UI
- [x] Update `WardrobeDragDropAdapter` to accept a `validate_pick_callback`.
- [x] Implement validation check in `_try_pick_surface_item` and `_perform_slot_interaction`.

## App
- [x] Update `WorkdeskScene` to configure `_dragdrop_adapter` with validation rule.
- [x] Implement `_validate_pick_rule` in `WorkdeskScene` using `LightZonesAdapter` and `InteractionRules`.
- [x] Update `_get_item_archetype` to handle ghost configuration (temporary hardcoded or config-based).

## Tests
- [x] Unit tests for `InteractionRules`.
- [x] Integration tests for ghost pick blocking.
