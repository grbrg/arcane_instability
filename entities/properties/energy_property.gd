class_name EnergyProperty
extends EntityProperty
# Base class for all energy channels (Thermal, Electrical, Arcane, ...).
# All channels share identical simulation mechanics: value decays toward 0,
# conductivity drives factor toward 1.0, and changed value triggers diffusion.


func tick(delta: float, _ambient: Ambient) -> void:
	var adjs = get_adjustments_of_type("value")
	var _decay: float = get_decay()
	var _cond: float = get_conductivity()
	for adj in adjs:
		adj.adjustment_value = lerp(adj.adjustment_value, 0.0, 1.0 - pow(1.0 - _decay, delta))
		if abs(adj.adjustment_value) < 0.01:
			adj.adjustment_value = 0.0

		adj.adjustment_factor = lerp(adj.adjustment_factor, 1.0, 1.0 - pow(1.0 - _cond, delta))
		if abs(1.0 - adj.adjustment_factor) < 0.01:
			adj.adjustment_factor = 1.0

		if adj.adjustment_factor == 1.0 and adj.adjustment_value == 0.0:
			remove_adjustment(adj)
