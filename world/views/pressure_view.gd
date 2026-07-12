class_name PressureView
extends EntityPropertyView

@onready var mesh = $MeshInstance3D

const MAGNIFICATION := 2.5


func _ready() -> void:
	mesh.set_instance_shader_parameter("time_offset", randf() * 100.0)


func update(_ambient: Ambient) -> void:
	if my_property:
		var val := clampf(my_property.get_value() * MAGNIFICATION, 0.0, 1.0)
		mesh.set_instance_shader_parameter("pressure", val)
