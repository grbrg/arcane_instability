shader_type spatial;

uniform vec4 kindling_color_light : source_color = vec4(0.62, 0.45, 0.22, 1.0);
uniform vec4 kindling_color_dark : source_color = vec4(0.28, 0.18, 0.08, 1.0);
uniform vec4 ember_color : source_color = vec4(0.90, 0.35, 0.05, 1.0);

uniform float detail_scale : hint_range(0.2, 5.0) = 0.8;
uniform float ember_speed : hint_range(0.0, 5.0) = 0.8;
uniform float ember_intensity : hint_range(0.0, 1.0) = 0.18;
uniform float cell_height : hint_range(0.01, 1.0) = 0.1;

varying vec3 world_position;

vec2 hash2(vec2 p) {
	p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)));
	return fract(sin(p) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	float a = hash2(i).x;
	float b = hash2(i + vec2(1.0, 0.0)).x;
	float c = hash2(i + vec2(0.0, 1.0)).x;
	float d = hash2(i + vec2(1.0, 1.0)).x;
	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	v += 0.500 * noise(p);
	v += 0.250 * noise(p * 2.1 + vec2(1.7, 3.3));
	v += 0.125 * noise(p * 4.3 + vec2(4.1, 1.9));
	v += 0.063 * noise(p * 8.9 + vec2(2.3, 5.1));
	v += 0.031 * noise(p * 18.1 + vec2(6.7, 0.9));
	return v;
}

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec3 world_pos = world_position;
	vec3 world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);

	float up_amount = dot(world_normal, vec3(0.0, 1.0, 0.0));
	float top_mask = smoothstep(0.3, 0.7, up_amount);

	// XZ world-space UVs — continuous across all cell borders
	vec2 uv = world_pos.xz / detail_scale;

	float fibre       = fbm(uv);
	float fibre_fine  = noise(uv * 5.5 + vec2(2.3, 0.7));
	float fibre_micro = noise(uv * 13.0 + vec2(0.9, 3.1));
	float fibre_lines = noise(vec2(uv.x * 14.0, uv.y * 2.5));

	float base = fibre * 0.4 + fibre_fine * 0.3 + fibre_micro * 0.15 + fibre_lines * 0.15;

	vec3 kindling_col = mix(kindling_color_dark.rgb, kindling_color_light.rgb, base);

	float t     = TIME * ember_speed;
	float ember = noise(uv * 3.0 + vec2(t * 0.4, t * 0.3));
	ember      *= noise(uv * 6.0 - vec2(t * 0.2, t * 0.5));
	float glow  = ember * (1.0 - base) * ember_intensity;
	kindling_col = mix(kindling_col, ember_color.rgb, glow);

	// --- Side color: same XZ pattern, fades to dark compressed wood at bottom ---
	// At height_factor=1 the side matches the top face — no seam.
	float height_factor = clamp(world_pos.y / cell_height, 0.0, 1.0);
	float hf2 = height_factor * height_factor;
	vec3 side_col = mix(kindling_color_dark.rgb * 0.3, kindling_col, hf2);

	vec3 final_color = mix(side_col, kindling_col, top_mask);

	// Force side normals to point upward in view space — eliminates lighting seams
	vec3 view_up = normalize(mat3(VIEW_MATRIX) * vec3(0.0, 1.0, 0.0));
	NORMAL = normalize(mix(view_up, NORMAL, top_mask));

	ALBEDO = final_color;
	ROUGHNESS = 0.94;
	SPECULAR = 0.02;
	EMISSION = ember_color.rgb * glow * top_mask * 0.5;
}
