class_name TemperatureView
extends EntityPropertyView


@onready var mesh = $MeshInstance3D


var _magnification = 1.0 / 1.5


func _ready() -> void:
	mesh.set_instance_shader_parameter("time_offset", randf() * 100.0)


## Sets the temperature from 0 to 1 (very hot)
func set_temperature(temp: float) -> void:
	mesh.set_instance_shader_parameter("temperature", clampf(temp * _magnification, -1.0, 1.0))


func update(_ambient: Ambient) -> void:
	if my_property:
		var thermal = my_property as ThermalEnergy
		if thermal:
			var value = thermal.get_value()
			set_temperature(value)
			Log.v("Thermal energy: " + str(value))
