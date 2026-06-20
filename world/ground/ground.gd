class_name Ground
extends Node3D


@onready var mesh = $MeshInstance3D


func _ready() -> void:
	if mesh.material_override != null:
		mesh.material_override = mesh.material_override.duplicate()


##
func set_shader(shader: Shader, params: Dictionary = {}) -> void:
	var material := ShaderMaterial.new()
	material.shader = shader
	for key in params:
		material.set_shader_parameter(key, params[key])
	if mesh == null:
		await ready
	mesh.material_override = material



func set_substance(subst: String) -> void:
	var shader_name = "res://world/ground/%s.gdshader" % subst
	var shader = load(shader_name)
	if shader:
		var params := {}
		var tex = load("res://world/ground/%s.jpg" % subst)
		if tex:
			params["base_texture"] = tex
		set_shader(shader, params)
