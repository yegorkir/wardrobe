# Analysis: Finish shift win counters (Iteration 4.1)

## Summary

The shift win condition must be purely counter-based: `checkin_done` and `checkout_done` must reach configured thresholds with no dependency on scene cleanliness or visibility. The existing domain/app structure already contains counters and a win policy, but the event sources, dedup rules, and config boundary need to be made explicit and robust.

## Scope and goals

- Make shift completion depend only on `checkin_done` and `checkout_done` vs `target_checkin`/`target_checkout`.
- Ensure counters increment once per qualifying domain event.
- Preserve fail logic and UI flow; only remove non-throughput gating from completion.

## Current state (observed)

- `RunState` stores `target_checkin`, `target_checkout`, `checkin_done`, `checkout_done`.
- `ShiftWinPolicy` is already counter-based.
- `ShiftService` uses `_try_finish_shift_success()` when counters update or targets configure.
- `workdesk_scene.gd` emits `register_checkin_completed()` and `register_checkout_completed()`.
- There is no explicit dedup at the domain level; increments are raw.
- `EVENT_CLIENT_COMPLETED` already carries `client_id` in its payload, but the bridge drops it.

## Requirements and invariants

- Counters are monotonic (never decrease).
- Each domain event increments exactly once (dedup in domain).
- Completion condition is pure: `(checkin_done >= target_checkin) && (checkout_done >= target_checkout)`.
- Completion must be independent of scene clutter, active nodes, or UI state.
- Config thresholds must be injected into the app/domain, not parsed in domain.
- `content/waves` is the authoritative source of thresholds.

## Architecture options

### Option A (minimal change, extend current flow)

- Keep `RunState` and `ShiftWinPolicy`.
- Add dedup sets to `RunState` or `ShiftService`.
- Ensure event entry points take `client_id` (or token) for dedup.
- Validate that all shift completion paths rely on `ShiftWinPolicy` only.

Pros:
- Minimal refactor, uses existing classes.
- Low risk to unrelated systems.

Cons:
- Requires careful audit of UI event sources and end-shift paths.

### Option B (new domain event aggregator)

- Introduce a dedicated domain component to track checkin/checkout completion by client/token.
- `ShiftService` delegates counter updates to this component.

Pros:
- Clear boundary and easier testing.

Cons:
- More structural change; may be unnecessary for 4.1.

**Recommendation**: Option A, with explicit dedup and boundary clarity.

## Proposed solution design

1. **Event entry points**
   - Add `register_checkin_completed(client_id)` and `register_checkout_completed(client_id)` at app/domain boundary.
   - Require adapters (scenes) to supply `client_id` and call these methods exactly once per domain event.
   - Treat `EVENT_CLIENT_COMPLETED` as the "client left scene" trigger for checkout.

2. **Dedup in domain**
   - Store `completed_checkins` and `completed_checkouts` as `Dictionary` keys or `Array[StringName]` with explicit checks.
   - Increment counters only when a new id is recorded.

3. **Config boundary**
   - Ensure `configure_shift_targets` is called from a single infrastructure source (`content/waves`).
   - Avoid pulling config in domain classes.

4. **Shift completion**
   - Use existing `ShiftWinPolicy` and `_try_finish_shift_success()`; ensure no extra gating on scene state.
   - `ShiftWon` should trigger summary flow; the scene should not force success separately.

## Modules and responsibilities

- `scripts/domain/run/run_state.gd`
  - Own counters, thresholds, dedup collections.
  - Expose `register_checkin_completed(client_id)` / `register_checkout_completed(client_id)`.

- `scripts/app/shift/shift_service.gd`
  - Entry point for adapters.
  - Apply domain events and re-evaluate win condition.

- `scripts/app/shift/shift_win_policy.gd`
  - Pure counter/threshold check only.

- `scripts/ui/workdesk_scene.gd`
  - Emits domain events when ticket transfer and checkout completion are confirmed.
  - Should not contain win logic or counter logic beyond emitting events.

- `scripts/autoload/bases/run_manager_base.gd`
  - Routes adapter calls to `ShiftService`.

## Data flow (proposed)

1. Adapter detects domain event (ticket taken, checkout completed).
2. Adapter calls `RunManagerBase.register_checkin_completed(client_id)` or `register_checkout_completed(client_id)`.
3. `ShiftService` forwards to `RunState` with dedup; counters update.
4. `ShiftWinPolicy` evaluates; on success, `ShiftWon` logged and signaled.
5. UI/summary reacts to `ShiftWon` and shows summary.

## Test plan (must exist before implementation)

- Audit existing tests for shift counters and win condition.
- Add unit tests for:
  - dedup behavior,
  - counter increments,
  - win condition when both thresholds are met.
- Add a lightweight integration scenario: counters reach thresholds while clutter remains.

## Risks and mitigations

- **Double counting** from repeated UI signals -> mitigate with domain dedup.
- **Hidden completion paths** (manual end, wave fail) -> audit to ensure no conflict with win condition.
- **Config drift** -> ensure a single config source and verify in tests.

## Open questions

1. Confirm where `content/waves` thresholds are loaded and how they reach `configure_shift_targets`.
2. Verify `client_id` availability for check-in (`EVENT_CLIENT_PHASE_CHANGED`) and ensure it is threaded through the bridge.
