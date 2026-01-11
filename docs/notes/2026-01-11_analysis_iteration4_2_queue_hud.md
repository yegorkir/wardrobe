# Analysis: Iteration 4.2 Queue HUD

## Goal
Create a top horizontal queue HUD strip (Workdesk only) that renders upcoming clients and shift KPIs as a read-only projection of app/domain state, with deterministic updates and a single presenter boundary.

## Scope
- New queue HUD UI (top strip, full width) for Workdesk.
- Presenter/controller that maps app/domain state into a stable HUD view-model.
- Data contract for queue slice + KPI counters + service indicators.
- Optional dev/preview injection for the HUD.

## Non-goals
- No gameplay logic changes in UI.
- No new queue rules, patience logic, or win rules.
- No refactors of core queue/desk systems beyond exposing read-only snapshots.

## Current architecture touchpoints
- `scripts/ui/wardrobe_hud_adapter.gd` displays `ShiftHudSnapshot` from `RunManagerBase`.
- `scripts/app/shift/shift_service.gd` owns `ShiftHudSnapshot` and emits `hud_updated`.
- Queue order lives in `scripts/domain/clients/client_queue_state.gd` with snapshot helpers.
- Client metadata exists in `scripts/domain/clients/client_state.gd` (archetype/color).

## Requirements summary (Iteration 4.2)
- Top HUD strip with three zones: queue preview (left), KPI progress (middle/right), service indicators (right), no patience in HUD.
- 4-8 portraits in exact queue order, no text labels.
- Deterministic animation triggers: append (slide-in), pop into service (remove), patience-zero (flash red then remove if still queued).
- Single presenter/controller for state -> HUD; view does not query scene tree.
- Provide a fake-data preview mode and tests around presenter mapping/diff logic.
- KPI display is remaining counts only: `remaining_checkin = N_checkin - checkin_done`, `remaining_checkout = N_checkout - checkout_done`.

## Clean architecture design
### Layering
- Domain: keep queue rules and event schema in `scripts/domain/**` only.
- App: build a read-only DTO for UI and a presenter that maps state -> DTO.
- UI: render DTO, handle animations, no state decisions.

### Data contract (app-level DTO)
Introduce a queue HUD snapshot class in app layer, e.g. `scripts/app/queue/queue_hud_snapshot.gd` (RefCounted) with:
- `upcoming_clients: Array[QueueHudClientVM]` (ordered, already sliced to max visible).
- `remaining_checkin: int`, `remaining_checkout: int`.
- (optional) `checkin_done: int`, `checkout_done: int`, `N_checkin: int`, `N_checkout: int` if needed for internal calculations or debug.
- `strike_count: int` (and any existing non-patience indicators).

`QueueHudClientVM` (app-level) should include:
- `client_id: StringName`
- `portrait_key: StringName`
- `tiny_props: Array[StringName]` (optional, empty by default)
- `status: StringName` (Queued/LeavingRed/EnteringService) if needed for animation hints.

### Presenter options
1) **QueueHudPresenter** (app) called by `ShiftService` on relevant events/ticks to emit `queue_hud_updated`.
2) **QueueHudService** (app) owned by `ShiftService` or `RunManagerBase`, exposing `get_queue_hud_snapshot()` and signal.
3) **UI adapter computes diff** using snapshot-only (no explicit events), animates by comparing `client_id` lists.

Preferred: option 1 or 2 to keep UI minimal and to centralize diff logic for deterministic animations (testable without scenes).

### UI adapter
- `scripts/ui/queue_hud_adapter.gd` (RefCounted) binds to `RunManagerBase` or `ShiftService` queue HUD signal.
- The HUD scene node script reads a `QueueHudSnapshot` and renders child controls.
- Animations use UI Tweens/AnimationPlayer (presentation-only).

## Test plan (to be implemented later)
- Presenter unit tests: queue slice order, client_id diffing, KPI fields.
- Determinism: same state sequence produces same diff outputs.
- Minimal scene integration test: feed fake snapshot and ensure HUD node count updates.

## Client config storage (content)
Define client configuration in `res://content/**` JSON (e.g., `content/clients.json`), with a stable `client_def_id` and visual fields:
- `client_def_id` (StringName-compatible ID, stable content key)
- `portrait_key` (Texture lookup key)
- `tiny_props` (array of icon keys)
- optional archetype/color metadata for future logic

Waves should reference `client_def_id` (not `client_id`), and runtime should generate a unique `client_id` per instance while retaining `client_def_id` on `ClientState` for HUD lookup.

## Risks and mitigations
- **Data source ambiguity**: queue snapshot may exist in multiple systems (desk/queue). Mitigate by defining a single app-level provider and documenting it.
- **Asset key uncertainty**: portrait/archetype IDs may not map to textures yet; use placeholders + fallback texture.
- **Animation determinism**: ensure diff logic is keyed solely by `client_id`, not node order traversal.

## Open questions
1) Confirm how and where to expose the preview/dev mode (editor-only vs. debug toggle).
2) Confirm texture lookup location (autoload ContentDB or local map in UI).

## References
- Control (layout, anchors, mouse_filter): https://docs.godotengine.org/en/4.5/classes/class_control.html
- CanvasLayer (HUD layering): https://docs.godotengine.org/en/4.5/classes/class_canvaslayer.html
- HBoxContainer (queue strip layout): https://docs.godotengine.org/en/4.5/classes/class_hboxcontainer.html
- TextureRect (portrait icons): https://docs.godotengine.org/en/4.5/classes/class_texturerect.html
- Tween (UI-only animations): https://docs.godotengine.org/en/4.5/classes/class_tween.html
