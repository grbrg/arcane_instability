shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_disabled, unshaded;

instance uniform float pressure : hint_range(0.0, 1.0) = 0.0;
instance uniform float time_offset = 0.0;

vec2 hash2(vec2 p) {
	p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)));
	return fract(sin(p) * 43758.5453);
}

// Returns approximate distance to the nearest Voronoi cell boundary.
// Value is ~0 at edges and larger away from them — ideal for crack shapes.
float voronoi_edge(vec2 uv) {
	vec2 i = floor(uv);
	vec2 f = fract(uv);
	float d0 = 8.0;
	float d1 = 8.0;
	vec2 r0 = vec2(0.0);
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 g = vec2(float(x), float(y));
			vec2 o = hash2(i + g);
			vec2 r = g + o - f;
			float d = dot(r, r);
			if (d < d0) { d1 = d0; d0 = d; r0 = r; }
			else if (d < d1) { d1 = d; }
		}
	}
	return sqrt(d1) - sqrt(d0);
}

void fragment() {
	// Two crack layers at different scales for detail variety
	float e1 = voronoi_edge(UV * 3.5 + time_offset * 0.002);
	float e2 = voronoi_edge(UV * 7.0 + vec2(time_offset * 0.003 + 5.3, 2.7));

	float c1 = 1.0 - smoothstep(0.0, 0.12, e1);
	float c2 = (1.0 - smoothstep(0.0, 0.07, e2)) * 0.75;
	float crack = max(c1, c2);

	ALBEDO = vec3(0.04, 0.02, 0.0);
	ALPHA = crack * pressure * 0.9;
}
