# Checklist — 2025-12-18 Architecture Audit

- [x] Add domain storage primitives (`ItemInstance`, `WardrobeStorageState`) with slot registration and pick/put/swap invariants.
- [x] Cover storage invariants with unit tests and snapshot assertions.
- [x] Fix ItemInstance duplication/type inference and clean WardrobeStorageState snapshot warnings; rerun unit suite.
- [x] Integrate `InteractionEngine` with domain storage state, emit domain events (`item_picked`/`item_placed`/`item_swapped`/`action_rejected`) with tick + snapshots, and validate expected hand/slot ids; update unit tests.
- [x] Add event-to-signal adapter and refactor `scripts/ui/wardrobe_scene.gd` to consume domain storage state snapshots and drive visuals via event signals.
- [x] Migrate `RunManager` responsibilities into a thin `ShiftService`/SimulationCore holder.
- [x] Convert ContentDB to emit definition Resources and pass definitions into core.
- [ ] Rebuild ShiftSummary UI on ShiftLog-first data and update functional tests for the new flow.
