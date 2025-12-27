# Analysis and plan: wardrobe refactor

## Context and goal
Goal: reduce responsibility and coupling in `scripts/ui/wardrobe_scene.gd`, simplify Step3 setup, remove command-reading duplication in domain logic, and make desk-event routing extensible. Changes must follow SimulationCore-first and clean layering (domain/app vs adapters/UI).

## Current state and issues
1) `scripts/ui/wardrobe_scene.gd`
- Script does node collection, state init (slots/desks/queue), adapter setup, input handling, event application, logging, HUD, and debug validation.
- Heavy responsibility in `_ready()/_finish_ready_setup()`, `_setup_adapters()`, `_perform_interact()`, `_find_best_slot()` and event handlers.

2) `scripts/ui/wardrobe_step3_setup.gd`
- `initialize_step3()` calls a chain where `_setup_step3_desks_and_clients()` mixes desk state creation, client generation, queue assignment, and domain event application.
- Duplicate client/item creation logic.

3) `scripts/domain/interaction/interaction_engine.gd`
- `_process_with_storage()` repeats tick reads and rejection creation.
- Slot/payload validation is scattered across branches.

4) `scripts/ui/wardrobe_interaction_events.gd`
- `apply_desk_events()` uses a growing `match` for manual routing.

## Requirements and constraints (architecture)
- Domain/app must not depend on UI/Node.
- UI is adapters and presentation only.
- No new rules in `scripts/sim/**`.
- Clean architecture: small components, clear contracts, minimal coupling.

## Solution design (high level)
### 1) WardrobeScene: split into adapters
Create 2-3 focused UI adapters:
- InteractionAdapter: build command, execute, apply events, logging.
- WorldSetupAdapter: collect slots/desks, register storage, run Step3, reset world.
- HudAdapter: RunManager wiring and HUD updates.

WardrobeScene becomes an orchestrator: create/configure adapters and forward calls.

### 2) Step3Setup: split into pure helpers
`WardrobeStep3SetupAdapter` into:
- `_build_desk_states()` -> returns desk_state array + lookups.
- `_build_clients()` -> returns clients dict + client_ids array.
- `_assign_clients_to_desks()` -> only queue + desk system assignment.
- `_make_demo_client(index, color)` -> factory for coat/ticket/client.

### 3) InteractionEngine: reduce duplication
- Read `tick` once in `_process_with_storage()`.
- Extract a single validation helper returning `InteractionResult` or `null`.
- Pass `tick` to `_execute_*` and `_reject_with_event`.

### 4) InteractionEvents adapter: handler table
Replace `match` with `Dictionary[StringName, Callable]`:
- `handlers[event_type] = Callable(self, "_apply_desk_consumed")`
- Unknown events handled in one place (ignore or log).

## Architecture (layers and dependencies)
**Domain (`scripts/domain/**`)**
- `interaction_engine.gd`: domain logic only, no Node/SceneTree/Autoload.

**App (`scripts/app/**`)**
- `interaction_service.gd`, `desk_service_point_system.gd`, `client_queue_system.gd`.

**UI/Adapters (`scripts/ui/**`, `scripts/wardrobe/**`)**
- New adapters: `wardrobe_interaction_adapter.gd`, `wardrobe_world_setup_adapter.gd`, `wardrobe_hud_adapter.gd`.
- `wardrobe_scene.gd` orchestrates.

## Proposed file changes
### Modify
- `scripts/ui/wardrobe_scene.gd`: move logic to adapters; simplify `_find_best_slot()` (no `score` dictionary).
- `scripts/ui/wardrobe_step3_setup.gd`: split `_setup_step3_desks_and_clients()`; add client factory.
- `scripts/domain/interaction/interaction_engine.gd`: single tick read + validation helper.
- `scripts/ui/wardrobe_interaction_events.gd`: handler dictionary.

### Add
- `scripts/ui/wardrobe_interaction_adapter.gd`
- `scripts/ui/wardrobe_world_setup_adapter.gd`
- `scripts/ui/wardrobe_hud_adapter.gd`

## Module/class design
### WardrobeInteractionAdapter (RefCounted)
- Fields: `interaction_service`, `event_adapter`, `interaction_events`, `desk_event_dispatcher`, `item_visuals`, storage/slot lookup, player.
- API:
	- `configure(context)`
	- `perform_interact()`
	- `build_interaction_command(slot)`
	- `execute_interaction(command)`
	- `apply_interaction_events(events)`
	- `log_interaction(result, slot)`

### WardrobeWorldSetupAdapter (RefCounted)
- Fields: `slots`, `slot_lookup`, `desk_nodes`, `storage_state`, `step3_setup`.
- API:
	- `collect_slots()`, `collect_desks()`
	- `reset_storage_state()` + `register_storage_slots()`
	- `reset_world()` / `initialize_world()`

### WardrobeHudAdapter (RefCounted)
- Fields: `run_manager`, label references, connection state.
- API:
	- `setup_hud()` / `teardown_hud()`
	- `on_hud_updated(snapshot)`

## Tests to review/update
- `tests/functional/wardrobe_scene_test.gd`
- `tests/functional/skeleton_validation.gd`
- `tests/unit/interaction_engine_test.gd`

## Implementation plan (steps)
1) Add HUD/WorldSetup/Interaction adapters and migrate logic from `wardrobe_scene.gd`.
2) Simplify `_find_best_slot()` (or move into InteractionAdapter).
3) Split `wardrobe_step3_setup.gd` into smaller helpers + client factory.
4) Refactor `interaction_engine.gd` (single tick + validation helper).
5) Refactor `wardrobe_interaction_events.gd` to handler table.
6) Update tests listed above and run GdUnit4.

## Verification commands
- `GODOT_TEST_HOME="$PWD/.godot_test_home_persist" task tests`
