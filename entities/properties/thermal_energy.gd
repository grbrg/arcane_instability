class_name ThermalEnergy
extends EntityProperty




##
func get_temperature(ambient: Ambient) -> float:
	return ambient.temperature + (get_value(base_value) * _substance.heat_capacity)


##
func tick(delta: float, _ambient: Ambient) -> void:
	# Reduce the adjustments based on the substance's heat conductivity?
	var adjs = get_adjustments_of_type("spell")
	for adj in adjs:
		# Move the stored energy towards 0.0 so the temperature settles back to
		# ambient.temperature (temperature == ambient + value * heat_capacity).
		# Conductivity drives the decay: higher conductivity equalises faster.
		var equalization = clamp(_substance.heat_conductivity, 0.0, 1.0)
		var new_val = lerp(adj.adjustment_value, 0.0, 1.0 - pow(1.0 - equalization, delta))
		
		# a part of the heat diffuses to its neighbours
		#var lost_value = adj.adjustment_value - new_val
		property_changed.emit(self, new_val * _substance.heat_conductivity)

		adj.adjustment_value = new_val

		"""
		if abs(adj.adjustment_value) < 0.01:
			adj.adjustment_value = 0.0
			Log.d("Thermal energy: reset")
		"""

		Log.v("Thermal energy: " + str(adj.adjustment_value))



		# make it move towards 1.0
		adj.adjustment_factor = lerp(adj.adjustment_factor, 1.0, 1.0 - pow(1.0 - _substance.heat_conductivity, delta))
		if abs(1.0 - adj.adjustment_factor) < 0.01:
			adj.adjustment_factor = 1.0
