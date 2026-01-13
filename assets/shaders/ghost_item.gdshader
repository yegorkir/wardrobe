shader_type canvas_item;

uniform float transparency : hint_range(0.0,
 1.0) = 1.0;
uniform float glow_power : hint_range(0.0, 8.0) = 0.0;
uniform vec4 glow_color : source_color = vec4(0.5, 0.8, 1.0, 1.0);

void fragment() {
	vec4 tex_color = texture(TEXTURE, UV);
	
	// Apply base transparency
	tex_color.a *= transparency;
	
	// Additive glow
	// Only add glow where there is existing alpha to avoid glowing empty space
	vec3 glow = glow_color.rgb * glow_power * tex_color.a;
	tex_color.rgb += glow;
	
	// Preserve original modulation (COLOR) from Sprite2D
	COLOR = tex_color * COLOR;
}
