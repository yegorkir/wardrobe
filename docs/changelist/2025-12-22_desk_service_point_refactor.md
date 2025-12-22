# Checklist: Desk service point refactor

- [x] Inspect `scripts/app/desk/desk_service_point_system.gd` for duplicated dropoff/pickup logic and queue assignment flow.
- [x] Add helper functions for rejection events, desk item consumption events, and phase-change events.
- [x] Update `_handle_dropoff` to use helpers while preserving queue requeue behavior and event ordering.
- [x] Update `_handle_pickup` to use helpers while preserving wrong-coat rejection and completion events.
- [x] Replace the unbounded loop in `_assign_next_client_to_desk` with a bounded loop tied to queue size.
- [x] Document the refactor and verification steps in a new task note.
- [ ] Run `task tests`.
- [ ] Run `godot --path . --headless --check-only --script res://scripts/app/desk/desk_service_point_system.gd`.
