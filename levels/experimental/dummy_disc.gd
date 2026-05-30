class_name DummyDisc
extends Node3D


@onready var mesh = $MeshInstance3D


func set_alpha(alpha: float) -> void:
	var material := mesh.get_active_material(0) as StandardMaterial3D
	material.albedo_color.a = alpha

