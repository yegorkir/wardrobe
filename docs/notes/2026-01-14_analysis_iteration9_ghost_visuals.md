# Iteration 9 — Analysis: Ghost Visuals (Shader)

## Goal
Visual feedback for ghost items based on light state:
- **In Darkness:** Item becomes semi-transparent (ghostly fade).
- **In Light:** Item glows (additive "charged" effect).

## Solution: Custom Shader (`ghost_item.gdshader`)
We will replace standard `modulate` manipulation with a dedicated ShaderMaterial for ghost items.

### Shader Logic
Parameters:
- `uniform float transparency`: 0.0 to 1.0 (controls visibility in dark).
- `uniform float glow_power`: 0.0 to 1.0 (controls additive glow intensity).
- `uniform vec4 glow_color`: Color of the glow (e.g., cyan/white).

### Behavior in `ItemNode`
- `ItemNode` needs a method `update_ghost_state(is_ghost: bool, is_in_light: bool, dark_alpha: float)`.
- If `is_ghost`:
  - Assign `ShaderMaterial` if not present.
  - Tween shader parameters:
    - **Dark:** `transparency` -> `dark_alpha`, `glow_power` -> `0.0`.
    - **Light:** `transparency` -> `1.0`, `glow_power` -> `0.5` (pulsing?).
- If not `is_ghost`:
  - Remove/disable shader.

### Architecture
- **Shader Asset:** `res://assets/shaders/ghost_item.gdshader`.
- **ItemNode:** Handles the logic of applying the material and tweening uniforms.
- **WorkdeskScene:** Calls `update_ghost_state` during the exposure tick loop (where it already calculates light).

## Risks
- **Material Override:** `ItemNode` uses `modulate` for color. Shader must assume `COLOR` input or multiply by `COLOR`. Standard `sprite` shader does this.
- **Batching:** Unique materials per item break batching, but we have few items, so acceptable.
- **Conflict with Burn:** Vampire burn uses `_burn_overlay`. Ghost shader should affect the base sprite. They can coexist.

## Plan
1. Create `assets/shaders/ghost_item.gdshader`.
2. Update `ItemNode`:
   - Add `_ghost_material: ShaderMaterial`.
   - Implement `set_ghost_appearance(is_in_light, dark_alpha)`.
   - Use Tweens for smooth transitions.
3. Update `WorkdeskScene`:
   - In `_tick_exposure`, call `item_node.set_ghost_appearance(...)` if archetype is ghost.
