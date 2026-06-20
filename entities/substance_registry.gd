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

	# Requires two thermal_bloom hits within ~1-2 seconds to ignite.
	# entity.tick() decays heat before check_activation runs, so decay and
	# capacity must be tuned against post-decay values:
	#   one cast post-decay:       0.5 * 0.9 = 0.45  <  0.65  → no fire
	#   two casts within ~1s:      1.0 * 0.9 = 0.90  >  0.65  → fire
	#   two casts ~1-2s apart:    0.75 * 0.9 = 0.675 >  0.65  → fire
	#   two casts 2s+ apart:     0.625 * 0.9 = 0.56  <  0.65  → no fire
	var kindling = Substance.new()
	kindling.thermal_capacity = 0.9
	kindling.thermal_conductivity = 0.05
	kindling.thermal_decay = 0.5
	kindling.burning_temperature = 0.65
	_substances["kindling"] = kindling


##
func get_substance(type: String) -> Substance:
	if type in _substances:
		return _substances[type].duplicate()
	return null

