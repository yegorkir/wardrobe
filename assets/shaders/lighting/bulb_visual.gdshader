shader_type canvas_item;

uniform vec4 color : source_color = vec4(1.0, 1.0, 0.6, 1.0);
uniform float glow_strength : hint_range(0.0, 1.0) = 0.2;

void fragment() {
    vec2 center = vec2(0.5, 0.5);
    float dist = distance(UV, center) * 2.0;
    
    // Hard circle for the bulb
    float core = step(dist, 0.8);
    
    // Soft glow around
    float glow = 1.0 - clamp(dist, 0.0, 1.0);
    glow = pow(glow, 2.0) * glow_strength;
    
    float alpha = max(core, glow);
    
    COLOR = color;
    COLOR.a *= alpha;
}
