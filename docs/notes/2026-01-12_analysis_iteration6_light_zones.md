# Iteration 6 (6A/6B) — Analysis: Light zones + controls

## Scope
Design a light system for StorageHall only, based on explicit rectangular zones, with deterministic queries and clean adapter boundaries. Include curtain slider (open ratio) and bulb toggles, with ShiftLog events.

## Requirements (confirmed)
- Grid concept exists (3 columns x 2 rows) but we implement light strictly via explicit zones.
- Zones are explicit rectangles in the scene: `CurtainZone`, `BulbRow0Zone`, `BulbRow1Zone`.
- Light applies only in StorageHall. ServiceZone is ignored.
- Light does not apply while item is dragged. It applies during flight after drop and while resting.
- Curtains use a slider to control open ratio (0..1) and thus vertical coverage. Lamps toggle per row.
- Curtains have placeholder visuals: two "accordion" curtains made of 6 rectangles each; both move vertically in opposite directions.
- Source IDs are explicit exported fields, not node names.
- Log events: `LIGHT_ADJUSTED` for curtain ratio, `LIGHT_TOGGLED` for bulbs.

## Constraints & architecture rules
- Domain/app must not depend on Node or scene.
- UI/adapters compute overlaps and handle Node geometry.
- No scene traversal in item logic; item nodes are only read by adapters.
- Keep logic deterministic and testable; avoid implicit scene querying in core.
- Light events must be defined in `EventSchema` (e.g., `LIGHT_ADJUSTED`, `LIGHT_TOGGLED`).

## Solution design
### Core data flow
- UI defines zones as Area2D + RectangleShape2D.
- Adapters read zone Rect2 in global coordinates.
- Light state is owned by an app-level service, which drives logs.
- Queries are done via adapter: item pivot (global position) is inside active zones.

### Components
- App layer: LightService (RefCounted)
  - Stores source states for curtains and bulbs.
  - APIs to set curtain open ratio and toggle bulbs.
  - Emits events via injected log `Callable` (align with existing ShiftLog usage).
- UI/adapters:
  - LightZonesAdapter: reads zones, builds active Rect2 list per source, exposes query methods.
  - CurtainLightAdapter: connects HSlider to LightService, updates curtain visuals.
  - BulbLightAdapter: handles input, toggles bulbs, updates visuals.

### Curtain zone math
- `CurtainZone` is a base rectangle.
- `open_ratio` scales zone vertically: height = base_height * open_ratio.
- The rectangle should shrink/grow along Y. The top/bottom behavior must match curtain motion (open up/down).
- Two curtains move opposite directions with the same offset.

### Drag safety
- Item drag state is available in `ItemNode` (flag `_is_dragging` set by `enter_drag_mode()`/`exit_drag_mode()`).
- Adapter should return false for `is_item_in_light()` if dragging; add a public accessor to avoid reading private state.

## Architecture (system design)
### Modules
- `scripts/app/light/light_service.gd`
  - Purpose: store light source states, expose state changes, log events.
  - No Node dependencies.
- `scripts/ui/light/light_zones_adapter.gd`
  - Purpose: read scene zones, compute active Rect2s, answer queries.
- `scripts/wardrobe/lights/curtain_light_adapter.gd`
  - Purpose: bind HSlider to LightService, drive curtain visuals.
- `scripts/wardrobe/lights/bulb_light_adapter.gd`
  - Purpose: toggle bulb state, drive bulb visuals.
- Optional helper: `scripts/ui/light/light_zone_rect.gd` (struct-like) if needed.

### Data contracts
- `LightSourceState`
  - `source_id: StringName`
  - `type: StringName` ("curtain" | "bulb")
  - `is_on: bool` (bulb)
  - `open_ratio: float` (curtain)
  - `row_index: int` (bulb)

### Logs
- `LIGHT_ADJUSTED` payload:
  - `source_id`, `open_ratio`
- `LIGHT_TOGGLED` payload:
  - `source_id`, `is_on`, `row_index`

## Future considerations
- Curtain visuals later replaced with sprites while keeping the same adapter API.
- Zones can be resized by moving the Area2D nodes (no code changes).
- If needed, a separate domain light model can be added without breaking UI APIs.

## Tests (requirements)
- Unit tests (domain/app):
  - LightService state updates and log emission.
- Integration tests:
  - Scene-level overlap tests using minimal scene with zones and a test item.

## Engine references (Godot 4.5)
- Area2D (for zone nodes and overlaps):
  https://docs.godotengine.org/en/4.5/classes/class_area2d.html
- RectangleShape2D (zone shapes):
  https://docs.godotengine.org/en/4.5/classes/class_rectangleshape2d.html
- Control / HSlider (curtain slider):
  https://docs.godotengine.org/en/4.5/classes/class_hslider.html
- Node2D (curtain visuals and transforms):
  https://docs.godotengine.org/en/4.5/classes/class_node2d.html
