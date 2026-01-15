# Analysis: Refactoring for Horizontal Mobile Layout (1920x1080)

## Context
The project is currently set up for a Portrait HD layout (720x1280). The goal is to refactor the main scene (`WorkdeskScene`) and project settings to support a Landscape Full HD layout (1920x1080) typical of mobile devices.

## Current State
*   **Resolution**: 720x1280.
*   **Main Scene**: `scenes/screens/WorkdeskScene.tscn`.
*   **Layout**: Vertical stack.
    *   Top: `StorageHall` (Cabinets, Lights).
    *   Bottom: `ServiceZone` (Desks) and `FloorZone` (Full-width surface).
*   **Dependencies**:
    *   Scene nodes use absolute `Vector2` positions suited for 720px width.
    *   Collision shapes for `FloorZone` and `LightZones` are sized for 720px width.

## Proposed Landscape Layout (1920x1080)
To utilize the landscape aspect ratio effectively, a **Split-Panel Layout** is recommended:

*   **Left Panel (Storage Area)**:
    *   Contains the `StorageHall` and `CabinetsGrid` (now a separate prefab `scenes/prefabs/CabinetsGrid.tscn`).
    *   The 3x2 cabinet grid fits comfortably on the left side.
    *   Light sources (Curtain, Bulbs) move with this group.

*   **Right Panel (Service Area)**:
    *   Contains the `ServiceZone` (Desks).
    *   The `FloorZone` (acting as the service counter) will be positioned here, likely at the bottom of the right panel or spanning the lower section.

*   **UI/HUD**:
    *   `QueueHudView`: Needs to be centered or moved to the Service side.
    *   `EndShiftButton`: Remains anchored bottom-right.
    *   `LightControls`: Needs checking (slider for curtains).

## Required Changes

### 1. Project Settings
*   Update `window/size/viewport_width` to `1920`.
*   Update `window/size/viewport_height` to `1080`.

### 2. Scene Refactoring (`WorkdeskScene.tscn`)
*   **StorageHall**:
    *   Move to approx. `(400, 100)` (Centered in left half).
    *   Ensure `CabinetsGrid`, `BulbsColumn`, `CurtainRig` move relatively or are re-anchored.
*   **Light Zones**:
    *   Reposition `BulbRow0Zone`, `BulbRow1Zone` to match new bulb positions.
    *   Verify `CurtainRig` coverage.
*   **ServiceZone**:
    *   Move to approx. `(1100, 400)` (Right half).
    *   Align `Desk_A` and `Desk_B`.
*   **FloorZone**:
    *   Resize collision shapes (`SurfaceBody`, `DropArea`) to cover the "Service Counter" area (e.g., width ~900px on the right).
    *   Ensure distinct "Floor" vs "Counter" if needed (currently `FloorZone1` and `FloorZone2` act as surfaces).

### 3. Logic & Scripts
*   **Coordinate Checks**: Scripts generally use global coordinates, so moving nodes should work as long as collision shapes are updated.
*   **`CursorHand`**: Logic is screen-independent (mouse follower).
*   **`FloorZoneAdapter`**: Logic adapts to collision shape size.

## Potential Problem Areas (Risks)
1.  **Visual Gaps**: Moving objects apart might leave empty "voids" in the background. We may need a background sprite or color rect to fill the space.
2.  **Interaction Zones**: If collision shapes are not perfectly aligned with visuals after the move, drag-and-drop might feel "off".
    *   **CRITICAL**: The **Service Desk** (Right Panel) is currently outside the `StorageHall` light zones. This means it is effectively "in darkness".
    *   **Ghost Softlock**: Ghost items cannot be picked up in darkness. If a Ghost item is placed on the Service Desk (e.g., during Check-in), it will be **stuck** and cannot be moved to storage.
    *   **Fix Required**: Add a permanent "Service Light" zone or extend the existing zones to cover the desk.
3.  **UI Scaling**: HUD elements might look small or misplaced on 1920 width if they don't have correct anchors.
4.  **Shader Coordinates**: `bulb_visual.gdshader` uses screen UVs? (Unlikely, usually local UVs, but worth verifying visual artifacts).
5.  **Camera**: The project seems to use a fixed viewport. If a Camera2D is introduced later, this layout needs to hold.

## Plan
1.  **Backup**: Ensure git status is clean.
2.  **Settings**: Update `project.godot` resolution.
3.  **Layout**:
    *   Open `WorkdeskScene.tscn` (via `godot_tools` or logically editing).
    *   Reposition `StorageHall` nodes.
    *   Reposition `ServiceZone` nodes.
    *   Resize/Reposition `FloorZone` collision shapes.
4.  **Verification**:
    *   Run scene.
    *   Check drag-and-drop boundaries.
    *   Check light zone overlaps.
