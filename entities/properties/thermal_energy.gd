class_name ThermalEnergy
extends EntityProperty



##
func get_temperature(ambient: Ambient) -> float:
	return ambient.temperature + (get_value(base_value) / _substance.heat_capacity)


##
func tick(delta: float, _ambient: Ambient) -> void:
	# Reduce the adjustments based on the substance's heat conductivity?
	var adjs = get_adjustments_of_type("spell")
	for adj in adjs:
		# make it move towards 0.0
		adj.adjustment_value *= pow(_substance.heat_conductivity, delta)
		if abs(adj.adjustment_value) < 0.1:
			adj.adjustment_value = 0.0
			Log.d("Thermal energy: reset")
		
		Log.d("Thermal energy: " + str(adj.adjustment_value))

		# make it move towards 1.0
		adj.adjustment_factor = lerp(adj.adjustment_factor, 1.0, 1.0 - pow(1.0 - _substance.heat_conductivity, delta))
		if abs(1.0 - adj.adjustment_factor) < 0.01:
			adj.adjustment_factor = 1.0
