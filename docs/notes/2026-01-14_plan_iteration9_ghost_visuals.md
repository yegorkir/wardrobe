# Iteration 9 — Plan: Ghost Visuals (Shader)

## Steps
1. **Create Shader**
   - File: `assets/shaders/ghost_item.gdshader`
   - Uniforms: `transparency`, `glow_power`, `glow_color`.
   - Logic: Modulate alpha, Additive glow.

2. **Update ItemNode**
   - Load shader resource.
   - Add `set_ghost_appearance(is_in_light: bool, dark_alpha: float)`.
   - Logic:
     - Check if material is assigned. If not, create new `ShaderMaterial` with the shader.
     - Tween `shader_parameter/transparency` and `shader_parameter/glow_power`.
     - Handle non-ghost reset (clear material).

3. **Update WorkdeskScene**
   - In `_tick_exposure` loop:
     - Identify ghost items (using `_get_item_archetype`).
     - Calculate `is_in_light`.
     - Call `item_node.set_ghost_appearance(is_in_light, arch.ghost_dark_alpha)`.

4. **Verify**
   - Run game.
   - Wait for ghost client (or spawn ghost item).
   - Toggle curtains.
   - Verify smooth transition between "faded" and "glowing".

## Technical Details
- **Glow Color:** Cyan `Color(0.5, 0.8, 1.0)` looks ghostly.
- **Transition Time:** 0.3s for smooth feel.
