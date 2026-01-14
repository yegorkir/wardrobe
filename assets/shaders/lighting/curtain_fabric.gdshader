shader_type canvas_item;

uniform vec4 base_color : source_color = vec4(0.56, 0.08, 0.14, 1.0);
uniform float fold_strength : hint_range(0.0, 1.0) = 0.05;
uniform float fold_frequency : hint_range(1.0, 20.0) = 3.0;

void fragment() {
    float fold = sin(UV.y * 3.14159 * fold_frequency) * 0.5 + 0.5;
    vec3 col = base_color.rgb * (1.0 - fold * fold_strength);
    COLOR = vec4(col, base_color.a);
}
