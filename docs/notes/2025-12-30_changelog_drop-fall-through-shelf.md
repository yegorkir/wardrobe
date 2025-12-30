# 2025-12-30 — Changelog: Drop fall-through shelf

- Added pass-through state to `ItemNode` so drops can temporarily disable collisions and restore them after crossing a target Y (`scripts/wardrobe/item_node.gd`).
- Switched item collision defaults to shared constants to keep drag/restore behavior consistent with pass-through restoration (`scripts/wardrobe/item_node.gd`).
- Exposed shelf drop bounds in world space to support "released above shelf" detection (`scripts/ui/shelf_surface_adapter.gd`).
- Routed floor drops through `drop_item_with_fall` and attached pass-through logic when the cursor is above a shelf drop rect (`scripts/ui/wardrobe_dragdrop_adapter.gd`).
- Expanded pass-through detection to use shelf surface bounds with item half-width padding so side drops above a shelf still fall through (`scripts/ui/wardrobe_dragdrop_adapter.gd`).
- Replaced shelf-based pass-through checks with floor-targeted pass-through: any drop-to-floor disables collisions until the floor Y, avoiding all shelves/objects regardless of lateral impulse (`scripts/ui/wardrobe_dragdrop_adapter.gd`).
- Increased the pick-area size while pass-through is active so players can rescue falling items more easily (`scripts/wardrobe/item_node.gd`).
- When releasing an item above a hook that cannot accept it, force a drop-to-floor instead of leaving it attached to the cursor (`scripts/ui/wardrobe_dragdrop_adapter.gd`).
- Made the floor drop helper non-teleporting by delegating to the fall-based path (`scripts/ui/floor_zone_adapter.gd`).
- Documented the behavior and the Godot 4.5 physics references used for collision layering (`docs/notes/2025-12-30_drop-fall-through-shelf.md`).
