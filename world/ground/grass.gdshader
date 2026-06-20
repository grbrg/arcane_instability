shader_type spatial;

uniform sampler2D base_texture : source_color, hint_default_white;
uniform vec4 dirt_color : source_color = vec4(0.32, 0.20, 0.11, 1.0);

uniform float wind_speed : hint_range(0.0, 5.0) = 1.2;
uniform float wind_strength : hint_range(0.0, 1.0) = 0.9;
uniform vec2 wind_dir = vec2(1.0, 0.6);
uniform float grass_scale : hint_range(0.2, 10.0) = 2.5;
uniform float cell_height : hint_range(0.01, 1.0) = 0.1;

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
	v += 0.250 * noise(p * 2.1);
	v += 0.125 * noise(p * 4.3);
	v += 0.063 * noise(p * 8.7);
	v += 0.031 * noise(p * 17.5);
	return v;
}

void vertex() {
	vec3 world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec2 uv = world_pos.xz / grass_scale;
	float t = TIME * wind_speed;
	vec2 wind_offset = normalize(wind_dir) * t * 0.12;

	float wave = noise(uv * 1.5 + wind_offset);
	wave += 0.5 * noise(uv * 3.0 + wind_offset * 1.4 + vec2(1.5, 2.3));
	wave /= 1.5;

	// Only displace upper vertices so the base stays planted
	float tip_weight = clamp(VERTEX.y / cell_height, 0.0, 1.0);
	tip_weight = tip_weight * tip_weight;

	vec2 dir = normalize(wind_dir);
	float strength = wave * wind_strength * 0.3 * tip_weight;
	VERTEX.x += dir.x * strength;
	VERTEX.z += dir.y * strength;
}

void fragment() {
	vec3 world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);

	float up_amount = dot(world_normal, vec3(0.0, 1.0, 0.0));
	float grass_mask = smoothstep(0.3, 0.7, up_amount);

	// XZ world-space UVs — continuous across all cell borders
	vec2 uv = world_pos.xz / grass_scale;
	float t = TIME * wind_speed;
	vec2 wind_offset = normalize(wind_dir) * t * 0.12;

	float patch      = fbm(uv * 0.5);
	float clump      = noise(uv * 2.3 + vec2(3.7, 1.2));
	float fine_clump = noise(uv * 5.7 + vec2(1.3, 4.2));
	float wind_wave  = noise(uv * 1.5 + wind_offset);
	wind_wave       += 0.5 * noise(uv * 3.0 + wind_offset * 1.4 + vec2(1.5, 2.3));
	wind_wave       /= 1.5;

	float brightness = patch * 0.32 + clump * 0.28 + fine_clump * 0.15 + wind_wave * wind_strength * 0.25;
	brightness = clamp(brightness, 0.0, 1.0);

	vec3 grass_col = texture(base_texture, fract(uv)).rgb;
	grass_col *= mix(0.75, 1.25, brightness);

	float fine  = noise(uv * 11.0 + wind_offset * 0.5);
	float micro = noise(uv * 23.0 + wind_offset * 0.3 + vec2(2.1, 5.4));
	grass_col *= mix(0.84, 1.0, fine * 0.55 + micro * 0.45);

	// --- Side color: same XZ pattern, fades to soil at the bottom ---
	// height_factor=1 at top of side face, 0 at bottom.
	// At height_factor=1 the side color matches the top face exactly — no seam.
	float height_factor = clamp(world_pos.y / cell_height, 0.0, 1.0);
	float hf2 = height_factor * height_factor;
	vec3 side_col = mix(dirt_color.rgb * 0.25, grass_col, hf2);

	vec3 final_color = mix(side_col, grass_col, grass_mask);

	// Force side face normals to point upward in view space.
	// This makes sides receive identical lighting to the top face,
	// eliminating the lighting discontinuity that reveals cell borders.
	vec3 view_up = normalize(mat3(VIEW_MATRIX) * vec3(0.0, 1.0, 0.0));
	NORMAL = normalize(mix(view_up, NORMAL, grass_mask));

	ALBEDO = final_color;
	ROUGHNESS = 0.92;
	SPECULAR = mix(0.02, 0.06, grass_mask * wind_wave);
}
