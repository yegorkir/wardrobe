# Plan: Iteration 4.2 Queue HUD

## Plan overview
Deliver a top queue HUD strip (Workdesk only) as a read-only UI projection of app/domain state, using a single presenter/controller boundary and deterministic updates. This plan follows clean architecture: domain -> app DTO/presenter -> UI adapter/view.

## Steps
1) **Confirm requirements and assets**
- Confirm Workdesk-only placement.
- Confirm KPI format: remaining check-in (`N_checkin - checkin_done`) and remaining check-out (`N_checkout - checkout_done`).
- Decide portrait lookup source and fallback texture.

2) **Define app-level DTOs**
- Add `QueueHudSnapshot` (RefCounted) and `QueueHudClientVM` in `scripts/app/queue/` or `scripts/app/hud/`.
- Include `remaining_checkin` and `remaining_checkout` fields (and optional raw totals if needed for debug).
- Ensure all public fields are typed and snapshots return copies where needed.

3) **Presenter/controller in app layer**
- Create a presenter that maps queue state + client states + shift counters into `QueueHudSnapshot`.
- Presenter should expose:
  - `build_snapshot(...) -> QueueHudSnapshot`
  - `diff_snapshots(prev, next) -> QueueHudDiff` (optional but recommended for deterministic animations).
- Keep diff keyed on `client_id` to avoid scene traversal.

4) **RunManager/ShiftService wiring**
- Add a new signal (e.g., `queue_hud_updated`) and a getter for the snapshot.
- Emit updates on queue-changing events and relevant shift KPI updates.
- Ensure HUD updates remain read-only and do not mutate gameplay state.

5) **UI scene + view script**
- Create a top `CanvasLayer` HUD strip in the relevant scene(s).
- Implement a `QueueHudView` script that receives `QueueHudSnapshot` and updates:
  - portrait list (4-8, ordered, clipped)
  - remaining KPI labels
  - service indicators (strikes, other existing flags)
- Animations: append slide-in, pop removal, patience-zero flash red.

6) **HUD adapter**
- Add `QueueHudAdapter` (RefCounted) in `scripts/ui/` to bind signals to the view.
- Keep adapter as the sole UI↔app coupling point.

7) **Fake data / preview mode**
- Implement a dev-only injector to push fake snapshots into the view.
- Provide a few canned states (empty, full, mixed archetypes) and scripted transitions.

8) **Tests**
- Unit tests for presenter mapping and diff logic (GdUnit4) in `tests/unit/` or `tests/ui/`.
- Lightweight view test: confirm that applying a snapshot updates visible portrait count.

9) **Docs updates**
- Update relevant design docs if contracts change (e.g., HUD DTO schema).
- Note the presenter boundary and DTOs for future UI work.

10) **Content client definitions**
- Add a client config JSON in `content/` (e.g., `content/clients.json`) with `client_def_id`, `portrait_key`, `tiny_props`.
- Update wave config to reference `client_def_id` for spawning.

## Test command (canonical)
GODOT_TEST_HOME="$PWD/.godot_test_home_persist" task tests

## Runtime check (canonical)
"$GODOT_BIN" --path .
