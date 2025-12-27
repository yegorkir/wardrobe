# Desk service point refactor

## Goal
- Reduce duplication in dropoff/pickup handling and remove the unbounded loop when selecting the next client, without changing behavior.

## Changes
- Extracted shared event helpers for delivery rejection, desk consumption, and phase change.
- Bounded queue scan for next client assignment using the current queue size.

## Tests
- `task tests`
- If running just a parse check: `godot --path . --headless --check-only --script res://scripts/app/desk/desk_service_point_system.gd`
