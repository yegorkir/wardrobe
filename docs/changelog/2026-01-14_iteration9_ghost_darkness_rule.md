# Changelog: Iteration 9 (Ghost Darkness Rule)

## [Unreleased]
### Added
- **Domain**: `InteractionRules` class to encapsulate picking logic (Ghost Rule).
- **Domain**: `is_ghost` and `ghost_dark_alpha` properties in `ItemArchetypeDefinition`.
- **Visuals**: `play_reject_effect` in `ItemNode` (red flash feedback) for blocked actions.
- **UI**: Validation callback support in `WardrobeDragDropAdapter` to decouple input from gameplay rules.
- **Tests**: Unit tests for `InteractionRules`.
- **Tests**: Integration test `test_ghost_pick_rules.gd` verifying blocking in `WorkdeskScene`.

### Changed
- **WorkdeskScene**: Now validates item picking against `InteractionRules` and current light state from `LightZonesAdapter`.
- **WorkdeskScene**: Improved `_get_item_archetype` to find instances directly from spawned nodes if not found in client storage.
- **CurtainLightAdapter**: Now connects to `LightService.curtain_changed` signal to ensure visuals stay in sync with service state even when changed via code/tests.

