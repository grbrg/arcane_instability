#class_name SubstanceRegistry
extends Node




const FLOAT_MAX = 999999.9

var _substances = {}



##
func _init() -> void:

	var water = Substance.new()
	water.thermal_capacity = 0.99
	water.thermal_conductivity = 0.1
	water.burning_temperature = FLOAT_MAX
	_substances["water"] = water

	var copper = Substance.new()
	copper.thermal_capacity = 0.25
	copper.thermal_conductivity = 0.2
	copper.burning_temperature = FLOAT_MAX
	_substances["copper"] = copper

	var gras = Substance.new()
	gras.thermal_capacity = 0.25
	gras.thermal_conductivity = 0.2
	gras.burning_temperature = 0.2
	_substances["gras"] = gras


##
func get_substance(type: String) -> Substance:
	if type in _substances:
		return _substances[type].duplicate()
	return null

