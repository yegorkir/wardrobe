# 2025-12-29 — Checklist: Step 6.1 physics shelves (No-SU)

## Scope
- [x] Add physics tick adapter and scene wiring.
- [x] Convert ItemNode to RigidBody2D with CoG/material/drag/settle.
- [x] Replace SU shelf/floor placement with physics surfaces and checks.
- [x] Rewire drag/drop to enqueue stability checks (no SU math).
- [x] Add UX feedback for stability (CoG/line/warning).
- [x] Remove SU artifacts from wardrobe adapters; keep HANG/LAY validation.
- [x] Fix cursor-hand type inference for warning state.
- [x] Run tests via Taskfile and record results.
- [x] Run build-all via Taskfile and record results.
- [x] Fix physics tick node lookup by marking scene node unique.
- [x] Fix unused class variable warning in workdesk scene.
- [x] Fix wake-up state change during physics flush.
- [x] Add debug logs for shelf/floor placement and physics stability checks.
- [x] Resolve physics tick type inference errors.
- [x] Add per-item collision/wake logging.
- [x] Avoid freezing on overlap and add overlap resolution impulses.
- [x] Add settle grace frames and state gating after drop.
- [x] Resolve surface bounds via collider chain for torque logic.
