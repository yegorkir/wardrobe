# 2026-01-17 — Checklist: reduce CabinetsGrid cabinet count

- [x] Identify cabinet nodes to remove (Cabinet_001, Cabinet_002, Cabinet_003, Cabinet_004).
- [x] Remove selected cabinet instances from `scenes/prefabs/CabinetsGrid.tscn`.
- [x] Ensure remaining cabinets preserve unique `cabinet_id` values.
- [ ] Verify slot discovery returns fewer cabinet slots at runtime.
- [ ] Run canonical tests and launch Godot once.
