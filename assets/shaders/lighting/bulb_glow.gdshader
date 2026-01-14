shader_type canvas_item;

uniform vec4 color : source_color = vec4(1.0, 1.0, 0.8, 0.3);
uniform float falloff_power : hint_range(0.1, 5.0) = 2.0;

void fragment() {
    vec2 center = vec2(0.5, 0.5);
    float dist = distance(UV, center) * 2.0; // 0 at center, 1 at edge
    float alpha = 1.0 - clamp(dist, 0.0, 1.0);
    alpha = pow(alpha, falloff_power);
    
    COLOR = color;
    COLOR.a *= alpha;
}
