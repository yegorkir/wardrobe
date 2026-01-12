# Iteration 6 (6A/6B) — Plan: Light zones + controls

## Goals
- Implement light zones in StorageHall via explicit rectangular zones.
- Provide deterministic queries: `IsItemInLight`, `WhichLightSourcesAffect`.
- Add controls: curtain open ratio via HSlider, bulb toggle per row.
- Add placeholder curtain visuals (accordion) with 6 segments each.
- Emit ShiftLog events for light changes.

## Non-goals
- No light effects on gameplay yet.
- No ServiceZone light queries.
- No grid math beyond explicit zones.

## Plan steps
1) **Create light service (app layer)**
   - Add `LightService` (RefCounted) to hold source state.
   - APIs:
     - `set_curtain_open_ratio(ratio: float)`
     - `toggle_bulb(row_index: int)`
     - `get_source_states()` for adapters
   - Emit ShiftLog events:
     - `LIGHT_ADJUSTED` (curtain)
     - `LIGHT_TOGGLED` (bulb)
   - Accept a log `Callable` (align with existing `ShiftLog.record` wiring).

2) **Add scene zones**
   - In `WorkdeskScene` StorageHall, add:
     - `CurtainZone` (Area2D + RectangleShape2D)
     - `BulbRow0Zone` (Area2D + RectangleShape2D)
     - `BulbRow1Zone` (Area2D + RectangleShape2D)
   - Position and size them manually to match cabinets.

3) **LightZonesAdapter**
   - Read zones and compute Rect2 in global space.
   - Active zones:
     - Curtain zone height scaled by `open_ratio`.
     - Bulb zones active only when bulb is on.
   - Query methods:
     - `is_item_in_light(item: ItemNode) -> bool` (check `item.global_position` inside zone Rect2)
     - `which_sources_affect(item: ItemNode) -> Array[StringName]`
   - Skip checks when item is dragging.
   - Add `ItemNode.is_dragging()` accessor if missing.

4) **Curtain control and visuals**
   - Add HSlider to WorkdeskScene HUDLayer.
   - `CurtainLightAdapter` listens to slider value and calls `LightService`.
   - Build accordion visuals:
     - Two curtain nodes, 6 rectangles each.
     - Move vertically in opposite directions based on open ratio.

5) **Bulb control and visuals**
   - Add bulb nodes in `BulbsColumn` with `BulbLightAdapter`.
   - Click toggles bulb state and updates LightService.
   - Visual on/off state (simple color/alpha change).

6) **Logging**
   - Wire LightService to ShiftLog (through existing logger in WorkdeskScene).
   - Emit `LIGHT_ADJUSTED` and `LIGHT_TOGGLED` events with payloads.
   - Add event constants to `EventSchema`.

7) **Tests**
   - Unit tests for LightService state changes and log payloads.
   - Integration test with minimal scene zones + test item for overlap correctness.

## Risks & mitigations
- **Zone sizing correctness**: Keep zones as explicit rectangles for easy manual adjustments.
- **Drag detection**: Use ItemNode drag flag; verify behavior during drag.
- **Curtain visuals**: Keep placeholder visuals isolated to adapters.

## Verification
- Run canonical tests:
  - `GODOT_TEST_HOME="$PWD/.godot_test_home_persist" task tests`
- Launch Godot once:
  - `"$GODOT_BIN" --path .`
