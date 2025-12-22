# Changelog: Architecture simplification (P0.1+)

## P0.1 — InteractionService extraction
- Added `scripts/app/interaction/interaction_service.gd` to centralize interaction state (hand item, tick, storage) and command execution.
- Updated `scripts/ui/wardrobe_scene.gd` to use the new service for command creation/execution and hand state updates.
- Added unit coverage for the new service in `tests/unit/interaction_service_test.gd`.
- Ran `task tests` (warnings about duplicate global class names and macOS CA certificates from Godot).
- Ran `task build-all` (exports succeeded; Godot reported editor settings save errors and a temp `project.binary` cleanup warning).
