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
	_substances["grass"] = gras

	var kindling = Substance.new()
	kindling.thermal_capacity = 0.9
	kindling.thermal_conductivity = 0.05
	kindling.burning_temperature = 0.65
	_substances["kindling"] = kindling


	var air = Substance.new()
	air.thermal_capacity = 0.05
	air.thermal_conductivity = 0.3
	air.burning_temperature = FLOAT_MAX
	air.electrical_capacity = 0.1
	air.electrical_conductivity = 0.5
	air.arcane_capacity = 0.3
	air.arcane_conductivity = 0.6
	air.pressure_conductivity = 0.92
	air.structure_value = 0.0
	air.structure_recovery = 0.0
	air.conduction_value = 0.6
	_substances["air"] = air


##
func get_substance(type: String) -> Substance:
	if type in _substances:
		return _substances[type].duplicate()
	return null

