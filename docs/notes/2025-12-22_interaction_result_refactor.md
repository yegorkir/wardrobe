# P0.2 InteractionResult refactor

## Goal
Replace dictionary-based interaction results with a typed `InteractionResult` value object to simplify contracts and improve maintainability.

## Scope
- New `scripts/domain/interaction/interaction_result.gd` value object.
- `scripts/domain/interaction/interaction_engine.gd` returns `InteractionResult`.
- `scripts/app/interaction/interaction_service.gd` and `scripts/ui/wardrobe_scene.gd` updated to consume typed results.
- Unit tests updated for the new API.

## Notes
- No engine API behavior changes; refactor only.
- No external docs referenced for this change.
