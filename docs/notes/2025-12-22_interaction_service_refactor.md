# P0.1 InteractionService extraction

## Goal
Move interaction state and command execution out of `scripts/ui/wardrobe_scene.gd` into an app-layer service to reduce UI responsibility and keep SimulationCore-first boundaries clearer.

## Scope
- New service in `scripts/app/interaction/interaction_service.gd`.
- UI updates in `scripts/ui/wardrobe_scene.gd`.
- Unit tests for service behavior.

## Notes
- No engine-specific behavior changes; refactor only.
- No external docs referenced for this change.
