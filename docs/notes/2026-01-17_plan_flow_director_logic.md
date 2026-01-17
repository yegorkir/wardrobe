# 2026-01-17 — Plan: Client Flow Director (Utility AI)

## Goal
Implement a decision-making logic ("Flow Director") within `ClientFlowService` that uses `ClientFlowSnapshot` metrics to decide **when** and **what** to spawn. This replaces server/static wave definitions with a local infinite rule-based system.

## Concept: Utility AI / Rule-based Director
The director runs on every `tick()`. It checks hard constraints first, then soft rules (heuristics) to determine spawn probability and client type.

### Algorithm
1.  **Cooldown Check**: Ensure minimum time passed since last spawn (`config.spawn_cooldown_range`).
2.  **Hard Constraints (Gatekeepers)**:
    *   **Capacity**: `free_hooks > 0` (derived from `total_hook_slots - client_items_on_scene`).
    *   **Queue**: `queue_total < config.max_queue_size`.
    *   **Active**: `active_clients < config.max_active_clients` (optional, to limit desk load).
    *   *If any fail -> No Spawn.*
3.  **Soft Rules (Decision)**:
    *   **Queue Pressure**: If `queue_total` is low, spawn probability is high.
    *   **Type Balance**: Calculate current ratio of `checkin` vs `checkout`.
        *   If `checkin` is dominant -> prefer `checkout` (return client).
        *   If `checkout` is dominant -> prefer `checkin` (new client).
4.  **Action**:
    *   Emit signal `request_spawn(spawn_request)`.
    *   `spawn_request` contains: `client_type` (CHECKIN | CHECKOUT).
    *   Reset cooldown with a random value from range.

## Implementation Steps

### 1. Update `ClientFlowConfig`
Add tuning parameters:
```gdscript
var min_free_hooks: int = 1
var max_queue_size: int = 5
var spawn_cooldown_range: Vector2 = Vector2(2.0, 4.0)
var target_checkout_ratio: float = 0.5  # 50% check-in / 50% check-out target
```

### 2. Implement Director Logic in `ClientFlowService`
*   Add internal `_cooldown_timer: float`.
*   Add `tick(delta)` logic:
    *   Decrement timer.
    *   If timer <= 0, evaluate snapshot.
    *   If spawn criteria met -> emit `request_spawn`.
    *   Reset timer using `randf_range`.

### 3. Define `ClientSpawnRequest` (Value Object)
Simple RefCounted carrying the decision:
*   `type`: enum/int (CHECKIN, CHECKOUT).

### 4. Wire up in `WorkdeskScene`
*   Connect `request_spawn` signal.
*   For now: **Log the request** via `DebugLog` (Factories are next task).

### 5. Tests
*   **Unit Tests**:
    *   Test hard constraints (no spawn if queue full).
    *   Test cooldown reset.
    *   Test ratio balancing logic (mock snapshot to force check-in vs check-out).

## Risks
*   **Oscillation**: Rapid switching between types if ratio is too strict. *Mitigation: Use probabilistic weight instead of hard switch.*
*   **Starvation**: If checkout clients can't spawn (no tickets taken), system might stall. *Constraint: Can only spawn checkout if `tickets_taken > 0`.*

## Next Steps (after this plan)
*   Implement `ClientFactory` to actually handle the spawn request.
