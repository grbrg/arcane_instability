class_name EnergyProperty
extends EntityProperty
# Base class for all energy channels (Thermal, Electrical, Arcane, ...).
# All channels share identical simulation mechanics: value decays toward 0,
# conductivity drives factor toward 1.0, and changed value triggers diffusion.


## The portion of this channel's value that contributes to stress damage
## (see Character.take_stress / WorldObject._apply_energy_stress). Negative
## values (e.g. cold) never damage.
func get_damage_value() -> float:
	return maxf(0.0, get_value())


## Multiplier applied to the diffused amount in WorldObject.diffuse_to_neighbours(), on top
## of conductivity. Kept separate from conductivity because conductivity also drives this
## property's own adjustment_factor decay in tick() below, where values above 1.0 break the
## pow(1.0 - cond, delta) curve.
func get_diffusion_rate() -> float:
	return 1.0


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
