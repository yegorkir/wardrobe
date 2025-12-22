# Checklist: Architecture simplification (P0.1+)

## P0.1 — InteractionService extraction
- [x] Identify affected components and tests.
- [x] Extract interaction state/logic into `scripts/app/interaction/interaction_service.gd`.
- [x] Update `scripts/ui/wardrobe_scene.gd` to use the service.
- [x] Add unit tests for the service.
- [x] Run `task tests` and address failures (warnings observed, no failures).
- [x] Run `task build-all` for full verification (exports completed with Godot warnings).
- [x] Commit with an appropriate message (`Extract interaction service`).

## P0.2 — InteractionResult value object
- [x] Create `scripts/domain/interaction/interaction_result.gd`.
- [x] Update interaction engine/service/UI to use typed results.
- [x] Update unit tests for typed results.
- [x] Run `task tests` and address failures (warnings observed, no failures).
- [ ] Run `task build-all` for full verification (failed: `Pure virtual function called!`, `web-local` exit 134).
- [x] Commit with an appropriate message (`Add interaction result value object`).

## P0.3 — Desk event split (domain vs UI)
- [x] Add `scripts/ui/desk_event_dispatcher.gd` for domain processing.
- [x] Simplify `scripts/ui/wardrobe_interaction_events.gd` to presentation-only.
- [x] Update `scripts/ui/wardrobe_scene.gd` to use dispatcher + presenter.
- [x] Run `task tests` and address failures (warnings observed, no failures).
- [x] Run `task build-all` for full verification (exports succeeded with editor settings warnings).
- [x] Commit with an appropriate message (`Split desk event dispatching`).

## P1.1 — RunState value object
- [x] Add `scripts/domain/run/run_state.gd`.
- [x] Update `scripts/app/shift/shift_service.gd` to use typed run state.
- [x] Update magic/inspection systems to accept `RunState`.
- [x] Update unit tests referencing run state.
- [x] Run `task tests` and address failures (warnings observed, no failures).
- [ ] Run `task build-all` for full verification (failed: `Pure virtual function called!`, `web-local` exit 134, editor settings save error).
- [x] Commit with an appropriate message (`Add RunState value object`).

## P1.2 — Event schema unification
- [x] Add `scripts/domain/events/event_schema.gd`.
- [x] Update interaction/desk systems and UI adapters to use unified schema constants.
- [x] Remove `scripts/domain/interaction/interaction_event_schema.gd`.
- [x] Run `task tests` and address failures (warnings observed, no failures).
- [x] Run `task build-all` for full verification (exports succeeded; CA cert/editor settings warnings).
- [x] Commit with an appropriate message (`Unify event schema constants`).
