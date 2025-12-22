# Checklist: Wardrobe refactor (adapters)

## Step 1 — Adapter extraction (HUD/World/Interaction)
- [x] Add HUD adapter for RunManager/HUD wiring.
- [x] Add WorldSetup adapter for slot/desk collection and Step 3 context wiring.
- [x] Add Interaction adapter for command execution + event handling.
- [x] Update `scripts/ui/wardrobe_scene.gd` to delegate responsibilities.
- [x] Run `GODOT_TEST_HOME="$PWD/.godot_test_home_persist" task tests` and address failures (CA certificates warning on macOS, all tests passed).

## Step 2 — Slot selection simplification
- [x] Simplify slot scoring in `scripts/ui/wardrobe_interaction_adapter.gd` to avoid temporary dictionaries.
- [x] Run `GODOT_TEST_HOME="$PWD/.godot_test_home_persist" task tests` and address failures (CA certificates warning on macOS, all tests passed).

## Step 3 — Step 3 setup helpers
- [x] Split `scripts/ui/wardrobe_step3_setup.gd` into helper methods and a demo-client factory.
- [x] Run `GODOT_TEST_HOME="$PWD/.godot_test_home_persist" task tests` and address failures (CA certificates warning on macOS, all tests passed).

## Step 4 — InteractionEngine validation helper
- [x] Read tick once and centralize validation in `scripts/domain/interaction/interaction_engine.gd`.
- [x] Run `GODOT_TEST_HOME="$PWD/.godot_test_home_persist" task tests` and address failures (CA certificates warning on macOS, all tests passed).

## Step 5 — Desk event handler table
- [x] Replace `match` dispatch with a handler table in `scripts/ui/wardrobe_interaction_events.gd`.
- [x] Run `GODOT_TEST_HOME="$PWD/.godot_test_home_persist" task tests` and address failures (CA certificates warning on macOS, all tests passed).

## Meta — Test workflow alignment
- [x] Update `AGENTS.md` to require Taskfile test runs with `GODOT_TEST_HOME`.
- [x] Align verification commands in `docs/notes/2025-12-23_wardrobe-refactor-plan.md`.

## Step 6 — Notes naming policy
- [x] Update `AGENTS.md` to require `docs/notes/YYYY-MM-DD_<type>_<slug>.md` for auxiliary notes.
- [x] Run `GODOT_TEST_HOME="$PWD/.godot_test_home_persist" task tests` and address failures (CA certificates warning on macOS, all tests passed).

## Step 7 — Interaction context object
- [x] Add `scripts/ui/wardrobe_interaction_context.gd` and wire it into `WardrobeInteractionAdapter`.
- [x] Update `scripts/ui/wardrobe_scene.gd` to populate the context.
- [x] Resolve headless parse errors related to typed context usage.
- [x] Run `GODOT_TEST_HOME="$PWD/.godot_test_home_persist" task tests` and address failures (CA certificates warning on macOS, all tests passed).

## Step 8 — Interaction logger adapter
- [x] Add `scripts/ui/wardrobe_interaction_logger.gd` and wire it through the interaction context.
- [x] Move interaction logging out of `WardrobeInteractionAdapter`.
- [x] Run `GODOT_TEST_HOME="$PWD/.godot_test_home_persist" task tests` and address failures (CA certificates warning on macOS, all tests passed).

## Step 9 — Taskfile test output filter
- [x] Update `task tests` to write raw logs and filter console output.
- [x] Add `task check-only`.
- [x] Run `GODOT_TEST_HOME="$PWD/.godot_test_home_persist" task tests` and address failures (CA certificates warning on macOS, all tests passed).

## Step 10 — Unhandled desk-event policy
- [x] Add unhandled desk-event policy handling to `scripts/ui/wardrobe_interaction_events.gd`.
- [x] Run `GODOT_TEST_HOME="$PWD/.godot_test_home_persist" task tests` and address failures (CA certificates warning on macOS, all tests passed).

## Step 11 — ShiftLog sink for interaction logger
- [x] Wire `scripts/ui/wardrobe_interaction_logger.gd` to `WardrobeShiftLog` with payloads.
- [x] Add `desk_event_unhandled_policy` export in `scripts/ui/wardrobe_scene.gd`.
- [x] Run `GODOT_TEST_HOME="$PWD/.godot_test_home_persist" task tests` and address failures (CA certificates warning on macOS, all tests passed).
