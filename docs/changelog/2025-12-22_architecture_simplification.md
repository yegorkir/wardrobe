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
