# P0.3 Desk event dispatcher/presenter split

## Goal
Separate desk event domain processing from UI presentation to keep adapters focused and reduce cross-layer responsibilities.

## Scope
- Added `scripts/ui/desk_event_dispatcher.gd` for domain event processing.
- Simplified `scripts/ui/wardrobe_interaction_events.gd` to UI-only presentation.
- Updated `scripts/ui/wardrobe_scene.gd` to use the dispatcher + presenter split.

## Notes
- No behavior changes intended; refactor only.
- No external docs referenced for this change.
