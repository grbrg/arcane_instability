shader_type spatial;

// Inverted-hull ink outline, chained after toon_relight.gdshader via next_pass (see
// toon_relight.gd). Renders only back faces of the same mesh, expanded slightly along
// their normals; depth test keeps this hidden except at the silhouette edge, where it
// pokes out from behind the front-facing surface as a thin dark border.
render_mode unshaded, cull_front, depth_draw_opaque;

uniform float outline_width : hint_range(0.0, 0.05) = 0.012;
uniform vec4 outline_color : source_color = vec4(0.02, 0.02, 0.05, 1.0);

void vertex() {
	VERTEX += NORMAL * outline_width;
}

void fragment() {
	ALBEDO = outline_color.rgb;
}
