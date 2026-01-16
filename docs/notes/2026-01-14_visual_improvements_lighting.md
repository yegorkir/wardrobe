# Visual Improvements: Lighting (2026-01-14)

## Goal
Enhance the visual quality of curtains and lamps (bulbs) using shaders and improved light rendering, responding to the need for "prettier" light.

## Changes

### Assets
Created new shaders in `assets/shaders/lighting/`:
- `light_beam.gdshader`: Simulates a "Window Light" beam originating from the left (window). Fades linearly from 100% to 10% across 90% of the width, then drops cubically to 0%. Vertical fade preserves the "gap between curtains" look.
- `bulb_glow.gdshader`: Simulates a radial light glow with soft falloff. Used for bulb light zones.
- `bulb_visual.gdshader`: Renders a glowing circle with a solid core and soft halo. Used for the bulb source visual.
- `curtain_fabric.gdshader`: Adds vertical folds/noise to curtain segments to simulate fabric texture.

### Scenes Modified
- **`scenes/prefabs/lighting/CurtainRig.tscn`**:
  - `CurtainZone/CollisionShape2D/LightVisual`: Applied `light_beam.gdshader`.
  - **Tweak:** Set Color to `Color(0.96, 0.98, 1.0, 0.5)` (Daylight Cool White).
- **`scenes/prefabs/lighting/CurtainStrip.tscn`**:
  - `Segment1`..`Segment12`: Applied `curtain_fabric.gdshader` with `base_color` matching the original segment color.
- **`scenes/screens/WorkdeskScene.tscn`**:
  - `StorageHall/BulbsColumn/BulbRow0/Visual` & `BulbRow1/Visual`: Applied `bulb_visual.gdshader`.
  - **Tweak:** Set Color to `Color(1.0, 0.8, 0.4, 1.0)` (Incandescent Warm Yellow).
  - `StorageHall/BulbRow0Zone` & `BulbRow1Zone` (`LightVisual`): Applied `bulb_glow.gdshader`.
  - **Tweak:** Set Color to `Color(1.0, 0.8, 0.45, 0.35)` (Matching Warm Glow).

## Implementation Details
- The changes were applied programmatically via a temporary tool script to adhere to the "no hand-edit .tscn" policy.
- `BulbLightAdapter` continues to control the bulb state via `modulate`, which interacts correctly with the shaders (dimming them when off).
