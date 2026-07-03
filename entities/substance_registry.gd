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
	gras.thermal_decay = 0.05
	gras.burning_temperature = 0.2
	_substances["grass"] = gras

	# Requires two thermal_bloom hits within ~1-2 seconds to ignite.
	# entity.tick() decays heat before check_activation runs, so decay and
	# capacity must be tuned against post-decay values (decay=0.05):
	#   one cast post-decay:       0.475 * 0.9 = 0.4275  <  0.65  → no fire
	#   two casts within ~1s:      0.95  * 0.9 = 0.855   >  0.65  → fire
	#   two casts ~1-2s apart:     0.9   * 0.9 = 0.81    >  0.65  → fire
	#   two casts 2s+ apart:       0.85  * 0.9 = 0.765   >  0.65  → fire (long window)
	var kindling = Substance.new()
	kindling.thermal_capacity = 0.9
	kindling.thermal_conductivity = 0.05
	kindling.thermal_decay = 0.05
	kindling.burning_temperature = 0.65
	_substances["kindling"] = kindling


##
func get_substance(type: String) -> Substance:
	if type in _substances:
		return _substances[type].duplicate()
	return null

