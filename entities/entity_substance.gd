class_name EntitySubstance
extends Node



# Temperature attributes
@export var heat_capacity: float = 0.9 # percentage of heat that can be stored
@export var heat_conductivity: float = 0.9 # how fast does thermal energy pass to neighbours
@export var heat_decay: float = 0.1 # how fast does thermal energy decay




##
func create_thermal_property() -> ThermalEnergy:
	var prop = ThermalEnergy.new(0.0, heat_capacity, heat_conductivity, heat_decay)
	return prop