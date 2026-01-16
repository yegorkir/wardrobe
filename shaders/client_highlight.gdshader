shader_type canvas_item;

uniform float highlight_strength : hint_range(0.0, 1.0) = 0.0;
uniform float outline_size : hint_range(0.5, 6.0) = 2.0;
uniform vec4 highlight_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
	vec4 base_color = texture(TEXTURE, UV) * COLOR;
	float alpha = base_color.a;
	vec2 pixel = TEXTURE_PIXEL_SIZE * outline_size;
	float max_alpha = alpha;
	max_alpha = max(max_alpha, texture(TEXTURE, UV + vec2(pixel.x, 0.0)).a);
	max_alpha = max(max_alpha, texture(TEXTURE, UV + vec2(-pixel.x, 0.0)).a);
	max_alpha = max(max_alpha, texture(TEXTURE, UV + vec2(0.0, pixel.y)).a);
	max_alpha = max(max_alpha, texture(TEXTURE, UV + vec2(0.0, -pixel.y)).a);
	float edge = clamp(max_alpha - alpha, 0.0, 1.0);
	vec4 outline = highlight_color;
	outline.a *= edge * highlight_strength;
	COLOR = base_color + outline * (1.0 - alpha);
	if (highlight_strength <= 0.001) {
		COLOR = base_color;
	}
}
