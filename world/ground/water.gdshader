shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 water_color_shallow : source_color = vec4(0.18, 0.52, 0.72, 1.0);
uniform vec4 water_color_deep : source_color = vec4(0.05, 0.18, 0.38, 1.0);
uniform vec4 foam_color : source_color = vec4(0.82, 0.92, 0.98, 1.0);

uniform float wave_speed : hint_range(0.0, 5.0) = 1.4;
uniform float wave_scale : hint_range(0.2, 5.0) = 0.8;
uniform float ripple_scale : hint_range(0.2, 5.0) = 1.5;
uniform float foam_threshold : hint_range(0.0, 1.0) = 0.72;
uniform float roughness_water : hint_range(0.0, 1.0) = 0.08;
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

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec3 world_pos = world_position;
	vec3 world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);

	float up_amount = dot(world_normal, vec3(0.0, 1.0, 0.0));
	float water_mask = smoothstep(0.4, 0.8, up_amount);

	float t = TIME * wave_speed;
	vec2 uv = world_pos.xz / wave_scale;

	float wave_a = noise(uv + vec2(t * 0.30,  t * 0.20));
	float wave_b = noise(uv * 1.3 + vec2(-t * 0.25, t * 0.35) + vec2(3.7, 1.2));
	float waves  = (wave_a + wave_b) * 0.5;

	vec2 uv_ripple = world_pos.xz / ripple_scale;
	float ripple  = noise(uv_ripple + vec2(t * 0.5, -t * 0.3));
	ripple       += 0.5  * noise(uv_ripple * 2.1 + vec2(-t * 0.4, t * 0.6));
	ripple       += 0.25 * noise(uv_ripple * 4.3 + vec2(t * 0.35, -t * 0.55));
	ripple       /= 1.75;

	float micro = noise(uv_ripple * 9.0 + vec2(t * 0.8, t * 0.6));

	float depth = mix(waves, ripple, 0.4);
	vec3 water_col = mix(water_color_deep.rgb, water_color_shallow.rgb, depth);

	float foam = smoothstep(foam_threshold, 1.0, waves + ripple * 0.4);
	water_col = mix(water_col, foam_color.rgb, foam * 0.6);
	water_col += (noise(uv_ripple * 4.5 + vec2(t * 0.7, t * 0.5)) * 0.04 + micro * 0.025) * (1.0 - foam);

	// --- Side color: same XZ pattern, fades to deep/dark at bottom ---
	// height_factor=1 at top of side → matches top face, no seam.
	float height_factor = clamp(world_pos.y / cell_height, 0.0, 1.0);
	float hf2 = height_factor * height_factor;
	vec3 side_col = mix(water_color_deep.rgb * 0.2, water_col, hf2);

	vec3 final_color = mix(side_col, water_col, water_mask);

	// Force side normals to point upward in view space — eliminates lighting seams
	vec3 view_up = normalize(mat3(VIEW_MATRIX) * vec3(0.0, 1.0, 0.0));
	NORMAL = normalize(mix(view_up, NORMAL, water_mask));

	// Perturb top-face normals for wave specular
	if (water_mask > 0.5) {
		float nx = noise(uv + vec2(t * 0.3, 0.0) + vec2(0.1, 0.0)) - noise(uv + vec2(t * 0.3, 0.0) - vec2(0.1, 0.0));
		float nz = noise(uv + vec2(0.0, t * 0.25) + vec2(0.0, 0.1)) - noise(uv + vec2(0.0, t * 0.25) - vec2(0.0, 0.1));
		NORMAL = normalize(NORMAL + vec3(nx, 0.0, nz) * 0.35 * water_mask);
	}

	ALBEDO = final_color;
	ROUGHNESS = mix(0.9, roughness_water, water_mask);
	SPECULAR = mix(0.05, 0.9, water_mask);
	METALLIC = mix(0.0, 0.1, water_mask);
}
