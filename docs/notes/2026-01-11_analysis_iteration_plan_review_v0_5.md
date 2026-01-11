# Analysis: Iteration plan review v0.5

## Summary

The review is mostly aligned with the current codebase and canon. The main gaps are still the legacy wave timer, the lack of N_checkin/N_checkout config targets (still derived from total_clients), and the absence of a Service Desk surface table. Iteration 0 in the review effectively maps to the original Iteration 4.1 plus cleanup tasks; win counters are now mostly complete, but target source-of-truth still needs work.

## Current snapshot (verified)

- Win counters + targets exist in domain/app (`scripts/domain/run/run_state.gd`, `scripts/app/shift/shift_win_policy.gd`).
- Queue mix policy exists (`scripts/app/queue/queue_mix_policy.gd`) and should be tuned, not rebuilt.
- Swap disabled globally (`scripts/app/interaction/pick_put_swap_resolver.gd`).
- Checkin/checkout counters now use `client_id` dedup and are wired through the desk events bridge.
- Legacy wave timer logic still exists in `scripts/ui/workdesk_scene.gd`.
- Targets are still configured from total_clients in `scripts/ui/workdesk_scene.gd`.
- `content/waves/wave_1.json` currently lacks N_checkin/N_checkout fields.

## Iteration mapping (review vs original plan)

- Review Iteration 0 == original Iteration 4.1 (win counters) + cleanup:
  - Remove wave timer.
  - Configure N_checkin/N_checkout from config (not total_clients).
  - Strengthen win tests.

## Requirements distilled from the review

- Remove wave timer and wave-fail logic entirely.
- Win condition is counter-based only (already done), but targets must be config-driven.
- Add Service Desk surface table before playtest.
- Maintain architecture boundaries: domain owns rules, UI adapts.

## Architecture (system design)

### Core boundaries (keep as-is)

- Domain/app: rules, counters, outcomes.
- UI/adapters: scene signals, drag-drop, visuals.
- Autoloads: config/content loading.

### Targets configuration (N_checkin/N_checkout)

Options:

1. **Wave config fields** (recommended)
   - Add `target_checkin`/`target_checkout` to `content/waves/*.json`.
   - ContentDB remains the source of truth; app layer receives numbers via adapter.

2. **Shift config file**
   - Introduce a shift config JSON and map it in a new ContentDB category.
   - Use when wave definitions should remain pure composition lists.

3. **Scene export defaults** (temporary only)
   - Exported ints in `workdesk_scene.gd` for quick playtest.
   - Must be replaced with data-driven config later.

### Service Desk surface table

We need a surface-based interaction that fits current adapter patterns.

Options:

1. **New DeskSurfaceAdapter (recommended)**
   - Extend `WardrobeSurface2D` like `ShelfSurfaceAdapter`.
   - Register with `SurfaceRegistry` and participate in surface detection.
   - Use `ItemNode.place_item` semantics to allow free placement.

2. **Repurpose ShelfSurfaceAdapter**
   - Configure a shelf surface to behave like a desk surface.
   - Lower effort but mixes semantics (desk is not a shelf).

3. **New surface system layer**
   - Generalize surface handling to support multiple surface kinds.
   - More flexible, but higher refactor cost.

Recommendation: Option 1 to keep roles clear and minimize refactor risk.

### Item scaling by depth

- Scaling should remain in UI/adapters (`ItemNode` or a visuals adapter).
- A surface can provide a scale hint; item visuals apply it.
- Keep scaling logic isolated so it does not leak into domain rules.

## Module and class design (future-facing)

- `scripts/wardrobe/surface/desk_surface_adapter.gd` (new)
  - Extend `WardrobeSurface2D`.
  - Implement drop bounds, surface placement, registration.
- `scripts/ui/workdesk_scene.gd`
  - Remove wave timer.
  - Inject N_checkin/N_checkout from config.
- `scripts/ui/wardrobe_item_visuals.gd` (or `ItemNode`)
  - Apply surface-driven scale factor.

## Tests (research + gaps)

- Existing tests:
  - `tests/unit/shift_service_win_test.gd` covers win logic and dedup.
- Missing tests to add:
  - Config-driven targets (verify configured N_checkin/N_checkout in app).
  - Surface desk placement rules (lightweight adapter-level test or scripted scenario).

## Risks

- Removing wave timer may expose hidden dependencies on `_wave_time_left` UI labels.
- If N_checkin/N_checkout are not tied to config, win conditions remain inconsistent.
- Desk surface changes can destabilize drag-drop if not isolated to adapters.

## Open questions

- Should N_checkin/N_checkout live in wave JSON or a separate shift config?
- Do we want a temporary default (6/4) only for playtest, or data-driven only?

## References

- Area2D class (for surface drop bounds): https://docs.godotengine.org/en/4.5/classes/class_area2d.html
- CollisionShape2D class: https://docs.godotengine.org/en/4.5/classes/class_collisionshape2d.html
- Node2D class (for scaling via surface depth): https://docs.godotengine.org/en/4.5/classes/class_node2d.html
