# 2025-12-28 — Step 6.1: Surface placement + Floor (implementation notes)

## Scope
- Implemented surface shelf placement with strict interval validation.
- Added FloorZone drop path with deterministic scatter and clamped bounds.
- Extended drag-and-drop to pick/drop shelf/floor items without touching slot logic.

## Design notes
- Shelf placement uses fixed-point sub-units (UNIT_SCALE=1000) and integer pixel mapping from the DropArea rect.
- Item sizing is a UI-level lookup (item_type -> size_units) with a safe default.
- Surface pick uses point queries against ItemNode PickArea (collision layer 1) and filters to shelf/floor adapters only.
- Floor scatter is deterministic from item_id hash to keep runs reproducible.

## Scene setup
- WorkdeskScene now has one ShelfSurface and one FloorZone inside StorageHall.
- Shelf length and floor bounds are edited via CollisionShape2D size; key behavior values are exported on adapters.

## References
- https://docs.godotengine.org/en/4.5/classes/class_physicsdirectspacestate2d.html#class-physicsdirectspacestate2d-method-intersect-point
- https://docs.godotengine.org/en/4.5/classes/class_node.html#class-node-method-reparent
- https://docs.godotengine.org/en/4.5/classes/class_tween.html
