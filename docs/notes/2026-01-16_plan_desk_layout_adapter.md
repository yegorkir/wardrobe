# Plan - Desk Layout Adapter Migration

## Goal
Move desk layout responsibility into a scripted layout scene (adapter) while preserving current `ClientDropZone/CollisionShape2D` positioning set in `WorkdeskScene.tscn`.

## Constraints
- Preserve existing `CollisionShape2D` transforms (position/size) in `WorkdeskScene.tscn`.
- Keep scene edits via `godot_tools` only.
- Follow existing architecture boundaries (adapter layer for scene-facing logic).

## Steps
1) Capture the current `ClientDropZone/CollisionShape2D` transforms in `scenes/screens/WorkdeskScene.tscn` for Desk_A and Desk_B to ensure they remain unchanged after migration.
2) Create a layout adapter script (e.g., `scripts/wardrobe/desk_layout.gd`) and attach it to `scenes/prefabs/DeskServicePointLayout_Workdesk.tscn`:
   - Provide `get_tray_slots()`, `get_drop_zone()`, and `place_item(item, storage_state)` (or `get_free_tray_slot_ids`) methods.
   - Ensure it gathers tray slots and manages placement decisions internally.
3) Update `DeskServicePoint` to reference the layout adapter instance (no auto-instancing, no slot id hacks):
   - Use a NodePath or direct child lookup to find the adapter.
4) Update world setup + desk system to register tray slots from the layout adapter instead of scanning raw nodes.
5) Run diagnostics (gdscript_diag), tests, and Godot startup validation.

## Acceptance
- Client items are placed on the tray slots using the layout adapter interface.
- Collision shapes remain at the exact positions previously set in the scene.
- No runtime auto-instancing; layout is defined in the scene and editable in the editor.
