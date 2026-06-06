class_name Substance
extends Node



@export_category("Thermal")
@export var thermal_capacity: float = 0.9 # percentage of heat that can be stored
@export var thermal_conductivity: float = 0.9 # how fast does thermal energy pass to neighbours
@export var thermal_decay: float = 0.1 # how fast does thermal energy decay
@export var burning_temperature: float = 999999.9


## List of substances this substance can morph into (water -> steam or ice)
var _successor_substances = []


##
func create_properties() -> Dictionary:
	var properties = {}

	properties["thermal"] = ThermalEnergy.new(0.0, thermal_capacity, thermal_conductivity, thermal_decay)
	
	return properties