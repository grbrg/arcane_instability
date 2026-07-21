class_name SpellMarker
extends Node3D



@onready var mesh = $MeshInstance3D

## Alpha for the translucent marker disc; independent of whatever alpha the
## player's tint color carries (player body colors are opaque).
const MARKER_ALPHA := 0.498

# Own material per marker (not the shared surface_material_override sub-resource --
# that's shared across every SpellMarker instance since it's not resource_local_to_scene,
# so mutating it in place would recolor every player's marker at once).
var _material: StandardMaterial3D


func set_color(color: Color) -> void:
	if not mesh:
		return
	if not _material:
		_material = StandardMaterial3D.new()
		_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		# Transparent materials default to no depth write, so without this a toon-shaded
		# opaque surface behind the marker (whose relight pass re-samples the screen and
		# overwrites it) can draw after the marker and stomp it. Writing depth makes the
		# depth test correctly reject that regardless of draw order.
		_material.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_ALWAYS
		mesh.material_override = _material
	_material.albedo_color = Color(color.r, color.g, color.b, MARKER_ALPHA)

