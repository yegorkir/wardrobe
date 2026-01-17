# Changelog - Iteration 10 MVP rescope

## 1) Domain/app event and service point flow
- Added deliver attempt/result event constants and payload keys in `scripts/domain/events/event_schema.gd`.
- Rewrote `scripts/app/desk/desk_service_point_system.gd` to drive tray placement, deliver validation, and accept/reject outcomes.
- Simplified reject policy in `scripts/app/desk/reject_consequence_policy.gd` to remove drop-to-floor, leaving patience penalties only.
- Reworked `scripts/app/desk/desk_reject_outcome_system.gd` to apply patience penalties from deliver reject events.

## 2) Drag/drop return-to-origin and slot reservation
- Added reservation support to `scripts/wardrobe/slot.gd` to block placements while returning to origin.
- Added return-to-origin tween and pickable gating in `scripts/wardrobe/item_node.gd`.
- Reworked `scripts/ui/wardrobe_dragdrop_adapter.gd` for origin tracking, reservation lifecycle, deliver attempts, and return-to-origin handling.

## 3) Ticket rack + tray layout
- Added ticket rack controller and deterministic jitter logic in `scripts/wardrobe/ticket_rack.gd`.
- Added client drop zone behavior in `scripts/wardrobe/client_drop_zone.gd`.
- Added ticket rack scene `scenes/TicketRack.tscn` with 7 slots.
- Added service point layout scene `scenes/prefabs/DeskServicePointLayout_Workdesk.tscn` with tray slots + drop zone.
- Updated `scripts/wardrobe/desk_service_point.gd` to inject layout scenes and validate tray/dropzone structure.
- Updated `scripts/ui/workdesk_scene.gd` to spawn the ticket rack and wire new context fields.
- Updated `scripts/ui/wardrobe_world_setup_adapter.gd` and `scripts/ui/wardrobe_step3_setup.gd` for ticket rack seeding and tray slot registration.
 - Removed TicketRack scene/controller and related adapters; ticket rack functionality dropped (later cleanup).

## 4) Event adapters and dispatcher
- Updated `scripts/ui/wardrobe_interaction_events.gd` to recognize deliver attempt/result events and spawn tray items by slot id.
- Updated `scripts/ui/desk_event_dispatcher.gd` to route deliver attempts and apply reject outcomes.

## 5) Tests
- Replaced `tests/unit/desk_service_point_system_test.gd` to cover new deliver/tray rules.
- Replaced `tests/unit/desk_reject_outcome_system_test.gd` to validate patience penalty application.

## 6) Iteration 10 fixes: hook tickets + layout fallback
- Updated `scripts/ui/wardrobe_step3_setup.gd` to seed one ticket per hook SlotA and stop pre-filling the ticket rack.
- Added hook ticket slot discovery in `scripts/ui/wardrobe_world_setup_adapter.gd` and wired it into step3 setup context.
- Added fallback tray slot/drop zone positioning and slot visuals in `scripts/wardrobe/desk_service_point.gd` when layout scenes miss transforms.
- Added ticket rack default layout/slot visuals in `scripts/wardrobe/ticket_rack.gd` to recover from empty scene transforms.
- Hardened `scripts/ui/workdesk_scene.gd` ticket rack spawn to use either controller child or root.
- Removed runtime hook board spawn in `scripts/ui/workdesk_scene.gd` to avoid duplicate hook visuals.
- Switched ticket seeding to cabinets grid slots (both SlotA/SlotB) via new cabinet slot discovery in `scripts/ui/wardrobe_world_setup_adapter.gd`.
- Added `get_ticket_slots()` on `scripts/wardrobe/cabinets_grid.gd` and runtime script wiring in `scripts/ui/workdesk_scene.gd`.
- Added a retry pass to collect desk layouts in `scripts/ui/workdesk_scene.gd` when tray slots are not ready yet.
- Added fallback tray slot/drop zone discovery in `scripts/wardrobe/desk_service_point.gd` for scenes missing scripts.
- Relaxed fallback to reapply scripts when tray/drop nodes exist but are not typed as `WardrobeSlot`/`ClientDropZone`.
- Adjusted drop zone lookup in `scripts/wardrobe/desk_service_point.gd` to search within the layout subtree.
- Added `@tool` to `scripts/wardrobe/client_drop_zone.gd` so its collision shape is created in the editor.
- Moved desk layout instancing responsibility to `scripts/ui/workdesk_scene.gd` via `ensure_layout_instanced()`.
- Removed `layout_scene` export from `scripts/wardrobe/desk_service_point.gd` and instantiate layouts from `scripts/ui/workdesk_scene.gd` instead.
- Added explicit `LayoutRoot/DeskLayout` nodes under `Desk_A`/`Desk_B` in `scenes/screens/WorkdeskScene.tscn` for manual editing.
- Added layout adapter script `scripts/wardrobe/desk_layout.gd` and desk lookup via `layout_adapter_path` in `scripts/wardrobe/desk_service_point.gd`.
- Ensure tray slot ids are namespaced by desk when layout nodes use default TraySlot_* names.
- Added debug logs in `scripts/ui/workdesk_scene.gd` to report tray/drop zone discovery and desk assignment state.
- Adjusted `scripts/wardrobe/desk_service_point.gd` to respect `layout_root_path` before creating a LayoutRoot fallback.
- Updated `scenes/screens/WorkdeskScene.tscn` to point desk layout adapters at `ClientDropZone/DeskLayout`.
- Fixed `scenes/prefabs/DeskService_ClientDropZone.tscn` to use the real `scripts/wardrobe/desk_layout.gd` adapter script instead of an empty placeholder.
- Added tray placement debug logs in `scripts/app/desk/desk_service_point_system.gd` to trace spawn decisions and slot registration.
- Added storage `put` failure logs in `scripts/domain/storage/wardrobe_storage_state.gd` to report missing/blocked slots.
- Added storage slot registration logs in `scripts/app/interaction/interaction_service.gd` and `scripts/ui/wardrobe_world_setup_adapter.gd` to confirm tray slots are registered.
- Added slot collection logs in `scripts/ui/wardrobe_world_setup_adapter.gd` to verify tray slots are discovered before registration.
- Included desk tray slots in `scripts/ui/wardrobe_world_setup_adapter.gd` slot collection so they register in storage.
- Added desk collection/logging in `scripts/ui/wardrobe_world_setup_adapter.gd` to trace desk/tray discovery order.
- Swapped desk/slot collection order in `scripts/ui/workdesk_scene.gd` so tray slots are discovered before storage registration.
- Ensure `scripts/ui/wardrobe_world_setup_adapter.gd` collects desks when slot collection runs first, so tray slots are registered.
- Hardened `scripts/wardrobe/slot.gd` to create/find ItemAnchor when missing to avoid null crashes during tray spawns.
- Removed unused DeskSlot node from `scenes/prefabs/DeskServicePoint_Workdesk.tscn`.
- Added delivery attempt/result logs in `scripts/ui/wardrobe_dragdrop_adapter.gd` to debug ticket handoff.
- Added auto-sizing to `scripts/wardrobe/client_drop_zone.gd` based on a Sprite2D's rect and connected it in `scenes/prefabs/DeskService_ClientDropZone.tscn` for desk sprites.
- Docs: https://docs.godotengine.org/en/4.5/classes/class_sprite2d.html#class-sprite2d-method-get-rect
- Added temporary debug draw for client drop zones and enabled it in `scenes/prefabs/DeskService_ClientDropZone.tscn`.
- Raised debug draw z-index for client drop zones to make the overlay visible.
- Added client highlight shader `shaders/client_highlight.gdshader` and material hookup in `scenes/prefabs/DeskServicePoint_Workdesk.tscn`.
- Added desk drop highlight control in `scripts/wardrobe/desk_service_point.gd` and hover-driven toggles in `scripts/ui/wardrobe_dragdrop_adapter.gd`.
- Routed drop zone highlight through `service_point_node` on `scripts/wardrobe/client_drop_zone.gd` to avoid mixing desk state vs node references.
- Made desk highlight materials local per instance in `scripts/wardrobe/desk_service_point.gd` so only the hovered client highlights.
