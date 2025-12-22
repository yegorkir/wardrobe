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
- [ ] Commit with an appropriate message.
