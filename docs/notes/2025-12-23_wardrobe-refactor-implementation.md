# Wardrobe refactor implementation notes (2025-12-23)

## Context
Executing the refactor plan in `docs/notes/2025-12-23_wardrobe-refactor-plan.md` with adapter extraction and layered cleanup.

## Step 1 — Adapter extraction
- Added `scripts/ui/wardrobe_hud_adapter.gd` for HUD/RunManager wiring and end-shift handling.
- Added `scripts/ui/wardrobe_world_setup_adapter.gd` to collect slots/desks, manage Step 3 setup context, and hold world state containers.
- Added `scripts/ui/wardrobe_interaction_adapter.gd` to own interaction command execution, event handling, and slot selection.
- Updated `scripts/ui/wardrobe_scene.gd` to orchestrate adapters and minimize direct responsibilities.
- Adjusted adapter field typing in `scripts/ui/wardrobe_scene.gd` to avoid headless class resolution errors.

## Step 2 — Slot selection simplification
- Simplified slot scoring in `scripts/ui/wardrobe_interaction_adapter.gd` to avoid temporary dictionaries.

## Step 3 — Step 3 setup helpers
- Split `scripts/ui/wardrobe_step3_setup.gd` into helper methods and a demo-client factory.

## Step 4 — InteractionEngine validation helper
- Read tick once and centralized validation in `scripts/domain/interaction/interaction_engine.gd`.

## Step 5 — Desk event handler table
- Replaced `match` dispatch with a handler table in `scripts/ui/wardrobe_interaction_events.gd`.

## Meta — Test workflow alignment
- Updated `AGENTS.md` to require `GODOT_TEST_HOME="$PWD/.godot_test_home_persist" task tests`.
- Updated verification commands in `docs/notes/2025-12-23_wardrobe-refactor-plan.md`.

## Step 6 — Notes naming policy
- Updated `AGENTS.md` to require all auxiliary notes (analysis/summary/changelog/checklist/etc.) to use `docs/notes/YYYY-MM-DD_<type>_<slug>.md`.

## Step 7 — Interaction context object
- Added `scripts/ui/wardrobe_interaction_context.gd` to group interaction dependencies.
- Updated `scripts/ui/wardrobe_scene.gd` and `scripts/ui/wardrobe_interaction_adapter.gd` to use the context object.
- Fixed headless parse errors by removing fragile typed references in the adapter configuration flow.

## Step 8 — Interaction logger adapter
- Added `scripts/ui/wardrobe_interaction_logger.gd` and routed interaction logging through it.
- Kept logging policy encapsulated in UI adapter, ready for future ShiftLog sink.

## Step 9 — Taskfile test output filter
- Updated `task tests` to write raw logs to `reports/test_run_<timestamp>.log` and filter console output to `ERROR/WARN` plus exit code.
- Added `task check-only` for lightweight script parsing checks.

## Step 10 — Unhandled desk-event policy
- Added unhandled desk-event policy handling to `scripts/ui/wardrobe_interaction_events.gd` (warn/debug/ignore).

## Tests
- `GODOT_TEST_HOME="$PWD/.godot_test_home_persist" task tests` run after each step (CA certificates warning on macOS, all tests passed).

## Step 11 — ShiftLog sink for interaction logger
- Wired `scripts/ui/wardrobe_interaction_logger.gd` to `WardrobeShiftLog` with typed payloads.
- Added `desk_event_unhandled_policy` export to `scripts/ui/wardrobe_scene.gd` and applied it during setup.

## Tests
- `GODOT_TEST_HOME="$PWD/.godot_test_home_persist" task tests` (CA certificates warning on macOS, all tests passed).
