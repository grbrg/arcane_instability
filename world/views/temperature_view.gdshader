shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_disabled, unshaded;

instance uniform float temperature : hint_range(-1.0, 1.0) = 0.0;
instance uniform float time_offset = 0.0;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

void vertex() {
	// Blend vertices toward sphere to round the box corners
	VERTEX = mix(VERTEX, normalize(VERTEX) * 0.5, 0.4);
}

void fragment() {
	float abs_temp = abs(temperature);
	float distortion = abs_temp * 0.007;

	float nx;
	float ny;
	if (temperature >= 0.0) {
		float t = TIME + time_offset;
		nx = sin(UV.y * 15.0 + t * 5.0)
		   + sin(UV.y * 31.0 + t * 8.6 + UV.x * 8.0) * 0.3;
		ny = cos(UV.x * 13.0 + t * 3.8) * 0.4;
	} else {
		// Frozen: distortion pattern is static (no TIME)
		nx = sin(UV.y * 15.0 + time_offset * 5.0)
		   + sin(UV.y * 31.0 + time_offset * 8.6 + UV.x * 8.0) * 0.3;
		ny = cos(UV.x * 13.0 + time_offset * 3.8) * 0.4;
	}

	vec4 distorted = texture(SCREEN_TEXTURE, SCREEN_UV + vec2(nx, ny) * distortion);

	float is_hot = step(0.0, temperature);
	vec3 tint = mix(vec3(0.05, 0.2, 1.0), vec3(1.0, 0.1, 0.05), is_hot);
	ALBEDO = mix(distorted.rgb, tint, abs_temp * 0.15);
	ALPHA = abs_temp * 0.5;
}
