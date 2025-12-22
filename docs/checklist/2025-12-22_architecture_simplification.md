# Checklist: Architecture simplification (P0.1+)

## P0.1 — InteractionService extraction
- [x] Identify affected components and tests.
- [x] Extract interaction state/logic into `scripts/app/interaction/interaction_service.gd`.
- [x] Update `scripts/ui/wardrobe_scene.gd` to use the service.
- [x] Add unit tests for the service.
- [x] Run `task tests` and address failures (warnings observed, no failures).
- [x] Run `task build-all` for full verification (exports completed with Godot warnings).
- [ ] Commit with an appropriate message.
