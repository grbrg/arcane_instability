class_name ThermalEnergy
extends EnergyProperty


func get_temperature(ambient: Ambient) -> float:
	return ambient.temperature + (get_value() * capacity)
