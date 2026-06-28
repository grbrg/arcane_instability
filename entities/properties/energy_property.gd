class_name EnergyProperty
extends EntityProperty
# Base class for all energy channels (Thermal, Electrical, Arcane, ...).
# All channels share identical simulation mechanics: value decays toward 0,
# conductivity drives factor toward 1.0, and changed value triggers diffusion.


func tick(delta: float, _ambient: Ambient) -> void:
	var adjs = get_adjustments_of_type("value")
	for adj in adjs:
		var new_val = lerp(adj.adjustment_value, 0.0, 1.0 - pow(1.0 - get_decay(), delta))

		# Emit before applying new value so neighbours receive current state
		property_value_changed.emit(self)

		adj.adjustment_value = new_val

		if abs(adj.adjustment_value) < 0.01:
			adj.adjustment_value = 0.0

		adj.adjustment_factor = lerp(adj.adjustment_factor, 1.0, 1.0 - pow(1.0 - get_conductivity(), delta))
		if abs(1.0 - adj.adjustment_factor) < 0.01:
			adj.adjustment_factor = 1.0

		if adj.adjustment_factor == 1.0 and adj.adjustment_value == 0.0:
			remove_adjustment(adj)
