shader_type canvas_item;

uniform vec4 color : source_color = vec4(0.96, 0.98, 1.0, 0.5);
uniform float intensity_y : hint_range(0.1, 5.0) = 2.0; // Sharpness of vertical gap (curtains)
uniform float min_brightness : hint_range(0.0, 1.0) = 0.1; // Brightness before the final drop-off
uniform float fade_end : hint_range(0.0, 1.0) = 0.9; // Point where linear fade ends and cubic drop starts

void fragment() {
    // Horizontal: Window Light (Left to Right)
    float x = UV.x;
    float alpha_x = 0.0;
    
    if (x < fade_end) {
        // Linear fade from 1.0 to min_brightness
        float t = x / fade_end;
        alpha_x = mix(1.0, min_brightness, t);
    } else {
        // Cubic fade from min_brightness to 0.0 over the last section
        float t = (x - fade_end) / (1.0 - fade_end);
        // Cubic ease-out (1 - t^3) or smoothstep could work.
        // User asked for cubic.
        alpha_x = min_brightness * (1.0 - t * t * t);
    }

    // Vertical: Fade out towards curtains (top and bottom), strongest in middle
    float dist_y = abs(UV.y - 0.5) * 0.8;
    float alpha_y = pow(clamp(1.0 - dist_y, 0.0, 1.0), intensity_y);

    COLOR = color;
    COLOR.a *= alpha_x * alpha_y;
}
