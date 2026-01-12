# Bugfix Note: Iteration 6 Light Zones

## Summary
Light zone queries and light-visual toggles failed in Workdesk scenes because the adapter's zone NodePaths pointed at non-existent children instead of sibling nodes.

## Root cause
`LightZonesAdapter` lives under `StorageHall`, but the exported NodePaths in `WorkdeskScene.tscn` and `WorkdeskScene_Debug.tscn` used `CurtainZone` / `BulbRow*Zone` without `..`. The adapter therefore resolved paths to child nodes under itself, got `null`, and cached empty base rects. This made `is_item_in_light()` return false and prevented light visuals from updating.

## Fix
- Updated the scene NodePaths to `../CurtainZone`, `../BulbRow0Zone`, and `../BulbRow1Zone`.
- Added an integration test that loads `WorkdeskScene.tscn`, opens the curtain fully, and verifies that an item placed at the curtain zone center is detected as lit.

## References
- NodePath (Godot 4.5): https://docs.godotengine.org/en/4.5/classes/class_nodepath.html
- Node.get_node (Godot 4.5): https://docs.godotengine.org/en/4.5/classes/class_node.html#class-node-method-get-node
