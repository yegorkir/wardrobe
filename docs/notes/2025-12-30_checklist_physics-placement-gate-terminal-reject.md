# Checklist: Physics placement gate + terminal reject

- [x] Review analysis and confirm scope for R1/R5/R2/R2.5 refactor.
- [x] Add SSOT layer/mask/group configuration and update runtime adapters to consume it.
- [x] Normalize `ItemNode` geometry API (AABB, bottom Y, snap) and align usage across adapters.
- [x] Implement floor-only pass-through and explicit reject-fall state in `ItemNode`.
- [x] Add `SurfaceRegistry` autoload and wire shelf/floor registration and cleanup.
- [x] Refactor overlap resolution to use `PhysicsPlacementGate` decisions (ALLOW/ALLOW_NUDGE/REJECT).
- [x] Make reject terminal by triggering pass-through fall until floor and skipping overlap while falling.
- [x] Enforce stable immunity by removing neighbor impulses during overlap nudges.
- [x] Update drag/drop floor selection to use registry and bottom-Y-based thresholds.
- [x] Sync collision layers/masks in relevant prefabs/scenes with SSOT.
- [x] Add integration tests for layers and geometry contracts.
- [x] Centralize SurfaceRegistry access via a single helper and remove direct `/root` lookups.
- [x] Introduce `WardrobeSurface2D` base contract and update shelf/floor adapters + registry types.
- [x] Add ItemNode surface ownership helpers to remove items without group scans.
- [x] Align pass-through restore threshold with floor contact (bottom Y + epsilon).
- [x] Run `GODOT_TEST_HOME="$PWD/.godot_test_home_persist" task tests`.
- [x] Launch Godot with `"$GODOT_BIN" --path .`.
