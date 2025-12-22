# P1.1 RunState value object

## Goal
Replace dictionary-based run state with a typed `RunState` object to improve maintainability and reduce loose contracts.

## Scope
- Added `scripts/domain/run/run_state.gd`.
- Updated `scripts/app/shift/shift_service.gd` to use `RunState`.
- Updated `scripts/domain/magic/magic_system.gd` and `scripts/domain/inspection/inspection_system.gd` signatures.
- Updated unit tests referencing run state.

## Notes
- No engine API behavior changes; refactor only.
- No external docs referenced for this change.
