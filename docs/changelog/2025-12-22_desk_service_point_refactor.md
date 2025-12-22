# Changelog: Desk service point refactor

- Reviewed `scripts/app/desk/desk_service_point_system.gd` to map duplicated dropoff/pickup branches and the unbounded queue loop.
- Introduced shared helpers for delivery rejection, desk item consumption, and phase-change event creation.
- Rewired `_handle_dropoff` and `_handle_pickup` to use the helpers while preserving event payloads and queue actions.
- Replaced the `while true` loop in `_assign_next_client_to_desk` with a bounded scan based on the queue size.
- Added a task note describing the refactor and verification commands.
- Fixed `_make_phase_change_event` typing to accept `StringName`, matching `ClientState.phase` and resolving test parse failures.
- Ran `task tests`; all 32 tests passed (warnings about duplicate class names and macOS certificate lookup reported by Godot).
