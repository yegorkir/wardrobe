# Changelog: Architecture simplification (P0.1+)

## P0.1 — InteractionService extraction
- Added `scripts/app/interaction/interaction_service.gd` to centralize interaction state (hand item, tick, storage) and command execution.
- Updated `scripts/ui/wardrobe_scene.gd` to use the new service for command creation/execution and hand state updates.
- Added unit coverage for the new service in `tests/unit/interaction_service_test.gd`.
- Ran `task tests` (warnings about duplicate global class names and macOS CA certificates from Godot).
- Ran `task build-all` (exports succeeded; Godot reported editor settings save errors and a temp `project.binary` cleanup warning).

## P0.2 — InteractionResult value object
- Added `scripts/domain/interaction/interaction_result.gd` and returned it from `scripts/domain/interaction/interaction_engine.gd`.
- Updated `scripts/app/interaction/interaction_service.gd` and `scripts/ui/wardrobe_scene.gd` to consume typed results.
- Updated interaction unit tests to assert against `InteractionResult` fields.
- Ran `task tests` (warnings about duplicate global class names and macOS CA certificates from Godot).
- `task build-all` failed: Godot reported `Pure virtual function called!` and `web-local` exited with status 134.

## P0.3 — Desk event split (domain vs UI)
- Added `scripts/ui/desk_event_dispatcher.gd` to isolate desk-domain processing from UI concerns.
- Simplified `scripts/ui/wardrobe_interaction_events.gd` to presentation-only handling.
- Updated `scripts/ui/wardrobe_scene.gd` to route desk events through dispatcher + presenter.
- Ran `task tests` (warnings about duplicate global class names and macOS CA certificates from Godot).
- Ran `task build-all` (exports succeeded; Godot reported editor settings save errors on macOS).

## P1.1 — RunState value object
- Added `scripts/domain/run/run_state.gd` for typed run state storage.
- Updated `scripts/app/shift/shift_service.gd` to use `RunState` instead of dictionaries.
- Updated `scripts/domain/magic/magic_system.gd` and `scripts/domain/inspection/inspection_system.gd` to accept `RunState`.
- Updated `tests/unit/magic_system_test.gd` to use `RunState`.
- Ran `task tests` (warnings about duplicate global class names and macOS CA certificates from Godot).
- `task build-all` failed: `web-local` exited with status 134 and Godot reported `Pure virtual function called!` plus editor settings save errors.

## P1.2 — Event schema unification
- Added `scripts/domain/events/event_schema.gd` as the shared event schema module.
- Updated interaction/desk systems and UI adapters to reference the unified schema constants.
- Removed `scripts/domain/interaction/interaction_event_schema.gd`.
- Ran `task tests` (warnings about duplicate global class names and macOS CA certificates from Godot).
- Ran `task build-all` (exports succeeded; Godot reported editor settings save errors and CA certificate warnings).

## P1.3 — Step 3 setup context
- Added `scripts/ui/wardrobe_step3_setup_context.gd` to group Step 3 setup dependencies.
- Updated `scripts/ui/wardrobe_step3_setup.gd` to accept a context object.
- Updated `scripts/ui/wardrobe_scene.gd` to build and pass the context.
- Ran `task tests` (warnings about duplicate global class names and macOS CA certificates from Godot).
- `task build-all` failed: `web-local` exited with status 134 and Godot reported `Pure virtual function called!`, temp project binary errors, and editor settings save errors.

## P2.1 — Identifier standardization
- Standardized slot lookup keys to `StringName` in `scripts/ui/wardrobe_scene.gd`.
- Removed redundant `str(...)` conversions for slot lookup paths.
- Ran `task tests` (warnings about duplicate global class names and macOS CA certificates from Godot).
- Ran `task build-all` (exports succeeded; Godot reported editor settings save errors and temp `project.binary` cleanup warnings).

## P2.2 — Debug world validation split
- Added `scripts/ui/wardrobe_world_validator.gd` to isolate debug-only integrity checks.
- Replaced inline validation with `_debug_validate_world()` guard in `scripts/ui/wardrobe_scene.gd`.
- Ran `task tests` (warnings about duplicate global class names and macOS CA certificates from Godot).
- Ran `task build-all` (exports succeeded; Godot reported editor settings save errors and macOS CA certificate warnings).
