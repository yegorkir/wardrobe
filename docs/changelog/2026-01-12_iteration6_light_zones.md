# Changelog: Iteration 6 (Light Zones)

## [Unreleased]
### Added
- **LightService**: App-layer service for managing light source states (curtains, bulbs).
- **Light Zones**: `CurtainZone`, `BulbRow0Zone`, `BulbRow1Zone` added to `WorkdeskScene` (StorageHall).
- **LightZonesAdapter**: Determines if items are in light based on zones and source states (Pivot check). Includes `@tool` support for editor preview.
- **Curtain Controls**: Added VSlider to HUD and accordion visual placeholders.
- **Bulb Controls**: Added clickable bulbs (visual toggle) for right column rows.
- **Events**: `LIGHT_ADJUSTED` and `LIGHT_TOGGLED` events in `EventSchema` and `ShiftLog` (with console debug output).
- **Debug Draw**: Enabled real-time debug visualization of active light zones in `LightZonesAdapter` (Editor & Runtime).
- **Light Visuals**: Added `LightVisual` (ColorRect) to light zones to visually represent light ON/OFF state and area coverage in the game world (semi-transparent overlay).

### Fixed
- Synced `WorkdeskScene_Debug.tscn` with `WorkdeskScene.tscn` to prevent crashes when running via Debug menu.
- Restored missing properties in `CurtainLightAdapter` within the scene file to ensure slider connectivity.
- Corrected slider layout and visibility by switching to `VSlider`.
