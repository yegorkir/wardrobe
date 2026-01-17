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
- Provide a reliable count of free hooks for coats (capacity-based gating for new clients).
- Provide queue size counts, including split by check-in vs check-out intent.
- Provide count of tickets currently on hand (likely to avoid spawning when a ticket is being handled).
- Define who consumes these metrics and how often the counting runs, to decide when to spawn new clients.

## Open questions (must resolve before implementation)
- What qualifies as a “free hook”? Only hook-board slots, or do cabinet slots count? Should tray slots count?
- Is “tickets on hand” strictly the single cursor hand item, or should tickets on trays/shelves also count?
- Spawn rule: do we spawn based on minimum free hooks, queue length thresholds, or target balance between check-in/out?
- Client definitions: should new clients use `ContentDB` (wave list) or a new infinite pool config?
- Spawn pacing: fixed interval, adaptive (based on capacity), or event-driven (on item placed/removed)?

## Proposed solution design
Introduce a small app-layer service that builds a “client flow snapshot” from domain state and drives spawn decisions on a fixed tick. UI adapters expose minimal read-only data needed for the snapshot.

### Data snapshot (new value object)
`ClientFlowSnapshot` (domain/app value object, RefCounted) with:
- `free_hook_count: int`
- `queue_total: int`
- `queue_checkin: int`
- `queue_checkout: int`
- `tickets_in_hand: int` (0 or 1 for now)
- `active_clients: int` (already tracked in `RunState`)

### Metric sources
- Queue counts: `ClientQueueState.get_checkin_count()`, `get_checkout_count()`.
- Free hooks: count empty slots in `WardrobeStorageState` filtered to “hook slots”.
- Tickets in hand: `WardrobeInteractionService.get_hand_item()` and check `ItemInstance.kind == ItemInstance.KIND_TICKET`.

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

### Spawn orchestration
New app service `ClientSpawnService` (or `ClientFlowService`) with:
- `tick(delta: float)` called from `WorkdeskScene._process()` (adapter) or `ShiftService.tick()`.
- `configure(get_snapshot: Callable, spawn_client: Callable, config: RefCounted)`.
- Applies spawn rules based on snapshot + config, then enqueues/spawns new clients.

### Spawn rules (initial suggestions)
- Require `free_hook_count >= min_free_hooks` (config).
- Keep `queue_total <= max_queue_size` (config).
- Maintain `queue_checkin : queue_checkout` ratio based on `ShiftService.get_queue_mix_snapshot()` or a new policy.
- Optional: avoid spawn when `tickets_in_hand > 0` to reduce confusion.

### Placement of new clients
- Construction should move from `WardrobeStep3SetupAdapter._build_clients()` to an app-layer factory:
  - `ClientFactory` in `scripts/app/clients/` builds `ClientState` + item instances via `ContentDB`.
  - UI adapter remains responsible for creating visuals and placing items, but app owns client state.

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
- Unit tests for `ClientFlowService.should_spawn()` with snapshots covering:
  - no free hooks
  - queue full
  - ticket in hand
  - target mix constraints
- Unit test for hook slot filtering (if implemented in app layer).
- Integration test: spawn loop increases queue when free hooks are available.

## Risks
- Slot classification drift if relying on naming only; prefer metadata or group tagging.
- Infinite flow can starve checkout if queue mix policy isn’t applied consistently.
- Over-frequent spawn tick may oscillate if capacity changes rapidly.

## References
- Godot Node `_process(delta)` for cadence and tick integration: https://docs.godotengine.org/en/4.5/classes/class_node.html#class-node-method-process
- Godot Timer for throttled polling if needed: https://docs.godotengine.org/en/4.5/classes/class_timer.html
