class_name SpellMarker
extends Node3D



@onready var mesh = $MeshInstance3D



func set_color(color: Color) -> void:
	if mesh:
		var material := mesh.get_active_material(0) as StandardMaterial3D
		material.albedo_color = color

