class_name TemperatureView
extends EntityPropertyView


@onready var mesh = $MeshInstance3D



func _ready() -> void:
	pass


## Sets the temperature from 0 to 1 (very hot)
func set_temperature(temp: float) -> void:
	var material := mesh.get_active_material(0) as StandardMaterial3D
	material.albedo_color.a = temp


func update(ambient: Ambient) -> void:
	if my_property:
		var thermal = my_property as ThermalEnergy
		if thermal:
			var temp = thermal.get_temperature(ambient)
			set_temperature(temp)
			Log.v("Temperature: " + str(temp) + "°")
