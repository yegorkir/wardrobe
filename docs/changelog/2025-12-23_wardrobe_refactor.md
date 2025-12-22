# Changelog: Wardrobe refactor (adapters)

## Step 1 — Adapter extraction (HUD/World/Interaction)
- Added `scripts/ui/wardrobe_hud_adapter.gd` to own RunManager/HUD wiring and end-shift behavior.
- Added `scripts/ui/wardrobe_world_setup_adapter.gd` to collect slots/desks, manage Step 3 setup context, and centralize world state containers.
- Added `scripts/ui/wardrobe_interaction_adapter.gd` to encapsulate interaction execution, event handling, and input-driven slot selection.
- Updated `scripts/ui/wardrobe_scene.gd` to delegate setup/interaction/hud responsibilities to the new adapters.
- Adjusted adapter field typing in `scripts/ui/wardrobe_scene.gd` to avoid headless class resolution errors.
- Tests: `GODOT_TEST_HOME="$PWD/.godot_test_home_persist" task tests` (CA certificates warning on macOS, all tests passed).

## Step 2 — Slot selection simplification
- Simplified slot scoring in `scripts/ui/wardrobe_interaction_adapter.gd` to avoid temporary dictionaries.
- Tests: `GODOT_TEST_HOME="$PWD/.godot_test_home_persist" task tests` (CA certificates warning on macOS, all tests passed).

## Step 3 — Step 3 setup helpers
- Split `scripts/ui/wardrobe_step3_setup.gd` into desk/client helper methods with a demo-client factory.
- Tests: `GODOT_TEST_HOME="$PWD/.godot_test_home_persist" task tests` (CA certificates warning on macOS, all tests passed).

## Step 4 — InteractionEngine validation helper
- Read tick once in `scripts/domain/interaction/interaction_engine.gd` and centralized validation into `_validate_request`.
- Tests: `GODOT_TEST_HOME="$PWD/.godot_test_home_persist" task tests` (CA certificates warning on macOS, all tests passed).

## Step 5 — Desk event handler table
- Replaced `match` dispatch with a handler table in `scripts/ui/wardrobe_interaction_events.gd`.
- Tests: `GODOT_TEST_HOME="$PWD/.godot_test_home_persist" task tests` (CA certificates warning on macOS, all tests passed).

## Meta — Test workflow alignment
- Updated `AGENTS.md` to require `GODOT_TEST_HOME="$PWD/.godot_test_home_persist" task tests`.
- Aligned verification commands in `docs/notes/2025-12-23_wardrobe-refactor-plan.md`.

## Step 6 — Notes naming policy
- Updated `AGENTS.md` to require all auxiliary notes (analysis/summary/changelog/checklist/etc.) to use `docs/notes/YYYY-MM-DD_<type>_<slug>.md`.
- Tests: `GODOT_TEST_HOME="$PWD/.godot_test_home_persist" task tests` (CA certificates warning on macOS, all tests passed).

## Step 7 — Interaction context object
- Added `scripts/ui/wardrobe_interaction_context.gd` to group dependencies for `WardrobeInteractionAdapter`.
- Updated `scripts/ui/wardrobe_scene.gd` and `scripts/ui/wardrobe_interaction_adapter.gd` to use the context object.
- Resolved headless parse errors by removing brittle class-typed references in adapter setup.
- Tests: `GODOT_TEST_HOME="$PWD/.godot_test_home_persist" task tests` (CA certificates warning on macOS, all tests passed).

## Step 8 — Interaction logger adapter
- Added `scripts/ui/wardrobe_interaction_logger.gd` and wired it through the interaction context.
- Moved interaction logging from `WardrobeInteractionAdapter` into the logger.
- Tests: `GODOT_TEST_HOME="$PWD/.godot_test_home_persist" task tests` (CA certificates warning on macOS, all tests passed).

## Step 9 — Taskfile test output filter
- Updated `task tests` to write raw logs to `reports/test_run_<timestamp>.log` and print only `ERROR/WARN` + exit code.
- Added `task check-only` for lightweight script parsing.
- Tests: `GODOT_TEST_HOME="$PWD/.godot_test_home_persist" task tests` (CA certificates warning on macOS, all tests passed).

## Step 10 — Unhandled desk-event policy
- Added `unhandled` policy handling to `scripts/ui/wardrobe_interaction_events.gd` with warn/debug/ignore options.
- Tests: `GODOT_TEST_HOME="$PWD/.godot_test_home_persist" task tests` (CA certificates warning on macOS, all tests passed).

## Step 11 — ShiftLog sink for interaction logger
- Wired `scripts/ui/wardrobe_interaction_logger.gd` to `WardrobeShiftLog` and added interaction event payloads.
- Added `desk_event_unhandled_policy` export to `scripts/ui/wardrobe_scene.gd` and applied it during setup.
- Tests: `GODOT_TEST_HOME="$PWD/.godot_test_home_persist" task tests` (CA certificates warning on macOS, all tests passed).
