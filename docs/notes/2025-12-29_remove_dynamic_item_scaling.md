# Remove dynamic item scaling

## Summary
- Removed runtime scale resets/animations for items so they keep their scene-defined scale while being reparented.
- Left static scales in scenes intact.

## Files touched
- `scripts/wardrobe/cursor_hand.gd`
- `scripts/wardrobe/item_node.gd`
- `scripts/wardrobe/slot.gd`
- `scripts/ui/shelf_surface_adapter.gd`
- `scripts/ui/floor_zone_adapter.gd`

## References
- https://docs.godotengine.org/en/4.5/classes/class_node2d.html

## Tests
- Not run (pending `task tests`).
