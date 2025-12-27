# Changelog — 2025-12-18 Architecture Audit

## Added
- Introduced SimulationCore storage primitives: `ItemInstance` and `WardrobeStorageState` under `scripts/domain/storage/` with command-style results and slot invariants (slot existence, occupancy, missing items).
- Added snapshot support for storage state to expose immutable views of slots and items for adapters/app-layer without leaking internal collections.
- Created unit coverage (`tests/unit/domain/wardrobe_storage_state_test.gd`) for pick/put/swap flows, blocking rules, and snapshot contents to guard invariants during migration.
- Refactored `WardrobeInteractionEngine` to accept domain state (`WardrobeStorageState` + hand `ItemInstance`) and emit domain events (`item_picked`, `item_placed`, `item_swapped`, `action_rejected`) with tick and snapshot payloads instead of Node adapters.
- Added validation of expected `hand_item_id`/`slot_item_id` in interaction commands to prevent unintended mutations and surface explicit rejection events.
- Added `WardrobeInteractionEventAdapter` to convert domain interaction events into adapter signals for UI, enabling decoupled visual updates; covered by `tests/unit/interaction_event_adapter_test.gd`.
- `wardrobe_scene.gd` now owns `WardrobeStorageState`, builds `ItemInstance` for seed/ticket items, drives interactions through the domain engine, and updates SceneTree visuals via event signals instead of direct Node mutations.
- `RunManager` reduced to a thin autoload; new `ShiftService` (`scripts/app/shift/shift_service.gd`) holds shift state/HUD snapshot, orchestrates Magic/Inspection systems, and saves meta through `SaveManager`.
- `ContentDBBase` migrates JSON load to `ContentDefinition` Resources, exposing definition snapshots instead of raw Variants for archetypes/modifiers/waves/seeds.

## Changed
- Fixed self-instantiation in `ItemInstance.duplicate_instance()` to avoid class resolution errors and align with Godot 4.5 typing.
- Preloaded `ItemInstance` in `WardrobeStorageState` and simplified snapshot building to remove ternary type warnings during headless checks.
- Kept legacy Node-based target processing in `InteractionEngine` behind a dedicated path with explicit Variant typing to satisfy headless parser while migration to adapters is pending.
- Rebuilt `tests/unit/interaction_engine_test.gd` around the domain API, asserting event payloads, state transitions, and rejection handling.
- Synchronised UI flows: seeding and ticket indicators mutate domain storage state (put/pick) and keep `item_id → ItemNode` mappings consistent with core state.
- Headless class cache rebuilt after migrating autoload/service definitions to ensure class_name resolution across UI scripts and tests.

## Tests
- `./addons/gdUnit4/runtest.sh -a ./tests/unit/interaction_event_adapter_test.gd -a ./tests/unit/interaction_engine_test.gd -a ./tests/unit/domain/wardrobe_storage_state_test.gd`
