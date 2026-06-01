class_name ThermalEnergy
extends EntityProperty




##
func get_temperature(ambient: Ambient) -> float:
	return ambient.temperature + (get_value() * capacity)


##
func tick(delta: float, _ambient: Ambient) -> void:
	# Reduce the adjustments based on the substance's heat conductivity?
	var adjs = get_adjustments_of_type("value")
	for adj in adjs:
		# Move the stored energy towards 0.0 so the temperature settles back to
		# ambient.temperature (temperature == ambient + value * capacity).
		# Conductivity drives the decay: higher conductivity equalises faster.
		var new_val = lerp(adj.adjustment_value, 0.0, 1.0 - pow(1.0 - get_decay(), delta))
		
		# a part of the heat diffuses to its neighbours
		property_value_changed.emit(self, new_val * get_conductivity())

		adj.adjustment_value = new_val

		if abs(adj.adjustment_value) < 0.01:
			adj.adjustment_value = 0.0

		Log.v("Thermal energy: " + str(adj.adjustment_value))


		# make it move towards 1.0
		adj.adjustment_factor = lerp(adj.adjustment_factor, 1.0, 1.0 - pow(1.0 - get_conductivity(), delta))
		if abs(1.0 - adj.adjustment_factor) < 0.01:
			adj.adjustment_factor = 1.0
		
		# we no longer have an effect, remove it
		if adj.adjustment_factor == 1.0 and adj.adjustment_value == 0.0:
			remove_adjustment(adj)
