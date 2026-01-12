# Iteration 5: Item Quality Stars Implementation

## Changelog

### Domain
- [x] Added `scripts/domain/quality/item_quality_config.gd`
- [x] Added `scripts/domain/quality/item_quality_state.gd`
- [x] Added `scripts/domain/quality/item_quality_service.gd`
- [x] Updated `scripts/domain/storage/item_instance.gd` to include `quality_state`
- [x] Updated `scripts/domain/events/event_schema.gd` with quality events.
- [x] Updated `scripts/domain/run/run_state.gd` to include `item_registry`.

### App
- [x] Updated `scripts/app/shift/shift_service.gd` to handle `register_item`, apply fall damage, and log quality changes.
- [x] Added `FALL_IMPACT_TO_DAMAGE_DIVISOR = 100.0` in `shift_service.gd` for damage balancing.
- [x] Updated `scripts/autoload/bases/run_manager_base.gd` to expose `register_item` and `find_item`.

### UI / Adapters
- [x] Updated `scripts/ui/wardrobe_item_visuals.gd` to render quality stars.
- [x] Updated `scripts/ui/wardrobe_physics_tick_adapter.gd` to trigger visual updates on landing.
- [x] **Fix**: Updated `item_node.gd` and `wardrobe_physics_tick_adapter.gd` to capture impact velocity before it is zeroed by the floor transfer logic (using physics state velocity).
- [x] **Fix**: Implemented impact detection on `_on_body_entered` in `ItemNode` to trigger damage immediately on collision (resolving "snap vs touch" timing for physics drops).
- [x] Updated `scripts/ui/workdesk_scene.gd` to wire dependencies (`find_item`, `register_item`).
- [x] Updated `scripts/ui/wardrobe_world_setup_adapter.gd` to register items.
- [x] Updated `scripts/ui/wardrobe_step3_setup.gd` to register demo items.
- [x] Updated `scripts/ui/wardrobe_dragdrop_adapter.gd` to pass `find_item_instance`.

### Tests
- [x] Added `tests/unit/domain/quality/test_item_quality.gd`
- [x] Added `tests/unit/domain/quality/test_quality_integration.gd` (includes quantization and scaling tests).

## Checklist

### Domain Implementation
- [x] Define `ItemQualityConfig` with `max_stars`.
- [x] Define `ItemQualityState` with `current_stars` and `apply_damage`.
- [x] Implement `ItemQualityService` to handle damage application and events.
- [x] Integrate `ItemQualityState` into `ItemInstance`.
- [x] Ensure `duplicate_instance` and `to_snapshot` handle quality.

### Testing
- [x] Verify default quality initialization.
- [x] Verify damage application reduces stars correctly.
- [x] Verify clamping (no negative stars, no overflow).
- [x] Verify source independence.

### Balancing & Fixes
- [x] Implement impact-to-damage scaling (divisor 100.0).
- [x] Fix zero-impact bug on floor landing (velocity buffering in ItemNode from physics state).
- [x] Fix damage timing (trigger on collision, not just settle).

### UI Rendering
- [x] UI rendering of stars (ColorRect placeholders for now).
- [x] Integration with Landing system (Fall damage updates visuals).
