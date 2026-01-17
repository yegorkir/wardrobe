# 2026-01-17 — Bugfix Plan: Flow Director Timer Scaling

## Problem
The `ClientFlowService` reduces the `_spawn_cooldown` only during metric ticks (every 0.2s), but subtracts only a single frame `delta` (approx. 0.016s). This causes the cooldown to run ~12x slower than real time (2s becomes ~25s).

## Goal
Ensure the spawn cooldown timer runs in real-time regardless of the metric sampling frequency.

## Proposed Changes

### 1. `scripts/app/clients/client_flow_service.gd`
*   Move `_spawn_cooldown` reduction to the very beginning of `tick(delta)` to ensure it updates every frame.
*   Decouple cooldown from the `_should_skip_tick(delta)` guard.
*   Modify the logic so snapshots are still built periodically (useful for DebugLog), but the director decision logic is only executed if `_spawn_cooldown <= 0.0`.

### 2. Logic Refactor (Pseudocode)
```gdscript
func tick(delta: float) -> void:
    # 1. Update cooldown timer every frame (real-time)
    if _spawn_cooldown > 0.0:
        _spawn_cooldown -= delta

    # 2. Guard for periodic metric collection
    if _should_skip_tick(delta):
        return

    # 3. Collect snapshot (available for UI/Debug even if on cooldown)
    var snapshot = _get_snapshot.call()
    _last_snapshot = snapshot

    # 4. Process spawn decisions only if timer reached zero
    if _spawn_cooldown <= 0.0:
        _process_director_logic(snapshot)
```

## Verification
*   Run `task tests` to ensure `ClientFlowService` still respects intervals.
*   Add/Update unit test `test_spawn_cooldown_blocks_requests` to verify real-time subtraction (e.g., `tick(2.0)` should clear a 2.0s cooldown in one go).
