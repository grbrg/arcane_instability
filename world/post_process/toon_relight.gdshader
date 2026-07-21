shader_type spatial;

// Toon shading layered on top of an object's existing material via next_pass (see
// world/post_process/toon_relight.gd, which chains this + toon_outline.gdshader onto
// every world/player/enemy/environment mesh). It never touches the base material's
// albedo/textures/animation directly — instead it re-draws the same geometry
// immediately after the base pass and re-samples what the base pass just rendered to
// the screen at this exact pixel (hint_screen_texture, standard Godot technique for
// distortion/overlay passes — see world/views/temperature_view.gdshader), then
// applies hue-preserving luminance banding to that. depth_test still applies, so
// occluded fragments are correctly skipped.
//
// Property-view overlays (thermal/pressure/impulse) are never chained to this at all
// (see toon_relight.gd's layer-2 check), so they're excluded structurally, not by
// tuning a heuristic.
render_mode unshaded, depth_draw_never, cull_back, blend_mix;

uniform sampler2D screen_tex : hint_screen_texture, repeat_disable, filter_linear;

uniform float toon_bands : hint_range(2.0, 8.0, 1.0) = 4.0;
uniform float band_softness : hint_range(0.0, 1.0) = 0.15;
uniform vec4 shadow_tint : source_color = vec4(0.05, 0.08, 0.18, 0.35);

// Saturated/bright pixels (fire, glowing conditions) skip most of the banding and get
// a slight boost instead, so effects stay legible rather than getting crushed flat.
uniform float effect_threshold : hint_range(0.0, 1.0) = 0.35;
uniform float effect_boost : hint_range(1.0, 2.5) = 1.35;

float luminance(vec3 c) {
	return dot(c, vec3(0.299, 0.587, 0.114));
}

void fragment() {
	vec3 col = texture(screen_tex, SCREEN_UV).rgb;

	float maxc = max(col.r, max(col.g, col.b));
	float minc = min(col.r, min(col.g, col.b));
	float sat = maxc - minc;
	float overbright = max(0.0, maxc - 1.0);
	float effect_mask = smoothstep(effect_threshold, effect_threshold + 0.25, max(sat, overbright));

	float lum = luminance(col);
	float banded = floor(lum * toon_bands + 0.5) / toon_bands;
	banded = mix(banded, lum, band_softness);
	vec3 toon_col = col * (banded / max(lum, 0.0001));
	toon_col = mix(toon_col, shadow_tint.rgb, (1.0 - banded) * shadow_tint.a * (1.0 - effect_mask));

	vec3 boosted = col * effect_boost;
	vec3 result = mix(toon_col, boosted, effect_mask);

	ALBEDO = result;
	ALPHA = 1.0;
}
