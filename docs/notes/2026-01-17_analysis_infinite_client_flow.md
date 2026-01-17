# 2026-01-17 — Analysis: infinite client flow metrics + spawn loop

## Goal
Plan how to support infinite client flow by tracking:
- free hooks for coat placement
- queue size (total + split: check-in vs check-out)
- tickets currently in hand
- cadence and ownership for spawn counting

This analysis stays within the repo architecture: domain/app logic owns truth; UI adapters provide state snapshots.

## Current system map (facts)
- Queue truth: `ClientQueueState` splits check-in and check-out queues (`get_checkin_count()`, `get_checkout_count()`).
- Run progress/targets: `RunState` via `ShiftService.get_queue_mix_snapshot()` supplies `need_in`, `need_out`, `outstanding`, etc.
- Storage truth: `WardrobeStorageState` stores slot items by slot id, and is driven by UI adapters via `WardrobeWorldSetupAdapter.register_storage_slots()`.
- Hand item truth: `WardrobeInteractionService` tracks a single `hand_item` (ItemInstance) used by drag/drop.
- Workdesk loop: `WorkdeskScene._process()` ticks queue system and patience, which is a natural entry point for a spawn tick.

## Requirements distilled from request
- Track two capacity metrics instead of a single “free hooks” value:
  - total hooks in cabinet slots on the scene
  - total client items currently on the scene
- Track queue size counts, including split by check-in vs check-out intent.
- Track “tickets taken from the scene” as `total_tickets - tickets_on_scene` (approximate but acceptable for now).
- Only build the metrics “machine” now; do not implement spawn decisions yet.

## Decisions from user
- Hooks count = cabinet slots on the scene (not tray slots); compute as total hooks count.
- Free capacity is derived later as `total_hooks - client_items_on_scene` (store both metrics).
- Tickets taken metric = `total_tickets - tickets_on_scene` (approximate for now).
- Do not implement spawn decisions yet; only collect metrics and provide a decision input surface.
- Clients/items will come from `res://content` later; spawning logic is out of scope.

## Proposed solution design
Introduce a small app-layer service that builds a “client flow snapshot” from domain state and drives spawn decisions on a fixed tick. UI adapters expose minimal read-only data needed for the snapshot.

### Data snapshot (new value object)
`ClientFlowSnapshot` (domain/app value object, RefCounted) with:
- `total_hook_slots: int`
- `client_items_on_scene: int`
- `queue_total: int`
- `queue_checkin: int`
- `queue_checkout: int`
- `tickets_on_scene: int`
- `tickets_taken: int` (computed as `total_tickets - tickets_on_scene`)
- `active_clients: int` (already tracked in `RunState`)

### Metric sources
- Queue counts: `ClientQueueState.get_checkin_count()`, `get_checkout_count()`.
- Total hook slots: cabinet slots discovered via `WardrobeWorldSetupAdapter.get_cabinet_ticket_slots()` (or a dedicated hook-slot collector).
- Client items on scene: count of `ItemNode` that belong to clients (filter by `ItemInstance.kind` and/or client registry).
- Tickets on scene: count of ticket items among spawned items.
- Total tickets: can be derived from initial ticket seeding count (Step 3 setup) or tracked in `RunState`.

### Hook slot filtering (options)
Option A (naming convention): treat slots with ids beginning with `Hook_` or `HookBoard_` and ending in `_SlotA/_SlotB` as hook slots. Exclude `Cab_` and tray slots.
- Pros: no new scene metadata.
- Cons: relies on naming conventions and can drift.

Option B (slot metadata): add an exported slot kind in `WardrobeSlot` (e.g., `@export var slot_kind := SLOT_KIND_STORAGE_HOOK`) and populate in scenes.
- Pros: explicit, robust.
- Cons: requires updating scenes.

Option C (group-based): add hook slots to a dedicated group (e.g., `wardrobe_hook_slots`).
- Pros: avoids naming reliance.
- Cons: requires scene edits.

### Metrics orchestration
New app service `ClientFlowService` with:
- `tick(delta: float)` called from `WorkdeskScene._process()` (adapter) or `ShiftService.tick()`.
- `configure(get_snapshot: Callable, publish_snapshot: Callable, config: RefCounted)`.
- Does not spawn; only produces snapshots to drive future decisions.

### Spawn rules (deferred)
No spawn rules now; keep the service focused on producing metrics only.

### Placement of new clients (deferred)
Spawning and client construction are deferred; focus on metrics only.

## Architecture options
1) **App-centric flow service (recommended)**
   - New `ClientFlowService` in `scripts/app/clients/`.
   - Consumes domain state via adapter snapshot; no direct Node access.
   - Adapter (WorkdeskScene) triggers `tick()`.

2) **ShiftService extension**
   - Embed flow logic into `ShiftService` with a new `tick_clients()`.
   - Pros: already central for run stats.
   - Cons: `ShiftService` currently has no direct access to storage/hand state; requires adapter-provided callbacks.

3) **UI-driven flow**
   - Keep logic inside `WorkdeskScene` or a UI adapter.
   - Not recommended: violates app/domain ownership and makes tests harder.

## Modules/classes design (proposed)
- `scripts/app/clients/client_flow_snapshot.gd` (RefCounted)
- `scripts/app/clients/client_flow_service.gd`
  - `configure(get_snapshot: Callable, enqueue_client: Callable, config: RefCounted)`
  - `tick(delta: float)`
  - `should_spawn(snapshot) -> bool` (pure)
- `scripts/app/clients/client_flow_config.gd` (RefCounted)
  - `min_free_hooks`, `max_queue_size`, `spawn_interval_sec`, `max_active_clients` etc.
- `scripts/app/clients/client_factory.gd`
  - `build_client(def_id: StringName, index: int) -> ClientState`

Adapters:
- `WorkdeskScene` (or `WardrobeWorldSetupAdapter`) exposes `get_hook_slots()` and `get_hand_item_kind()` for snapshot building.
- `DeskEventDispatcher` or `DeskServicePointSystem` handles actual queue enqueue + desk assignment.

## Tests to add
- Unit tests for snapshot building (hook count, ticket count, queue split).
- Integration test: metrics update when items are added/removed from the scene.

## Risks
- Slot classification drift if relying on naming only; prefer metadata or group tagging.
- Tickets taken metric is approximate while “total tickets” tracking is implicit.

## References
- Godot Node `_process(delta)` for cadence and tick integration: https://docs.godotengine.org/en/4.5/classes/class_node.html#class-node-method-process
- Godot Timer for throttled polling if needed: https://docs.godotengine.org/en/4.5/classes/class_timer.html
