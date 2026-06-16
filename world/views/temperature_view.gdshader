shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_disabled, unshaded;

instance uniform float temperature : hint_range(0.0, 1.0) = 0.0;
instance uniform float time_offset = 0.0;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

void vertex() {
	// Blend vertices toward sphere to round the box corners
	VERTEX = mix(VERTEX, normalize(VERTEX) * 0.5, 0.4);
}

void fragment() {
	float distortion = temperature * 0.007;
	float t = TIME + time_offset;

	float nx = sin(UV.y * 15.0 + t * 5.0)
	         + sin(UV.y * 31.0 + t * 8.6 + UV.x * 8.0) * 0.3;
	float ny = cos(UV.x * 13.0 + t * 3.8) * 0.4;

	vec4 distorted = texture(SCREEN_TEXTURE, SCREEN_UV + vec2(nx, ny) * distortion);

	ALBEDO = mix(distorted.rgb, vec3(1.0, 0.1, 0.05), temperature * 0.15);
	ALPHA = temperature * 0.5;
}
