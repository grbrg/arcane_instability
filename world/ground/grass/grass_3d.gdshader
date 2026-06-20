shader_type spatial;
render_mode cull_disabled;

uniform vec3 color : source_color;
uniform vec3 color2 : source_color;
uniform sampler2D noise;
uniform float noiseScale = 20.0;
uniform float windStrength = 0.5;
uniform float windSpeed = 1.2;
uniform vec2 windDirection = vec2(1.0, 0.3);

varying vec3 worldPos;

void vertex() {
	worldPos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;

	// UV.y = 1 at tip, 0 at base — tip sways, base stays anchored
	float tipFactor = UV.y;
	vec2 dir = normalize(windDirection);
	float phase = dot(worldPos.xz, dir) * 0.4 + TIME * windSpeed;
	float sway = (sin(phase) + 0.3 * sin(phase * 2.7 + 1.0)) * windStrength * tipFactor;

	VERTEX.x += dir.x * sway;
	VERTEX.z += dir.y * sway;
}

void fragment() {
	vec3 noiseLevel = texture(noise, worldPos.xz / noiseScale).rgb;
	ALBEDO = mix(color, color2, 1.0- UV.y) * mix(color, color2, noiseLevel.r);
	if (!FRONT_FACING) {
		NORMAL = -NORMAL;
	}
}