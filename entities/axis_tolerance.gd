class_name AxisTolerance
extends Resource
# Shared damage-from-stress formula, used by both Character (core/Character.gd) and WorldObject
# (world/world_object.gd) so the two don't reimplement the same math with divergent behavior.
# Covers every Cast.Axis (spells/cast.gd): the three ENERGY sub-channels (thermal/electrical/
# arcane), PRESSURE, STRUCTURE and CONDUCTION. Each axis is checked against its own tolerance
# and dealt damage independently, instead of tolerancing a combined sum — e.g. something
# resistant to heat but not electricity still takes damage from being electrified, and an
# object overloaded with conductivity doesn't hide behind spare structure budget.
#
# Structure/conduction tolerances default well above a fresh substance's resting values (see
# Substance.structure_value/conduction_value) so they're inert until an object is pushed past
# its resting state (e.g. over-repaired or over-charged) — an "instability" past the norm, not
# a constant self-damage tax.

@export_category("Energy")
@export var thermal_tolerance: float = 0.5
@export var electrical_tolerance: float = 0.5
@export var arcane_tolerance: float = 0.5
@export var thermal_damage_scale: float = 20.0
@export var electrical_damage_scale: float = 20.0
@export var arcane_damage_scale: float = 20.0

@export_category("Pressure")
@export var pressure_tolerance: float = 2.0
@export var pressure_damage_scale: float = 20.0

@export_category("Structure")
@export var structure_tolerance: float = 50.0
@export var structure_damage_scale: float = 20.0

@export_category("Conduction")
@export var conduction_tolerance: float = 1.0
@export var conduction_damage_scale: float = 20.0


func _tolerance_for(key: String) -> float:
	match key:
		"thermal": return thermal_tolerance
		"electrical": return electrical_tolerance
		"arcane": return arcane_tolerance
		"pressure": return pressure_tolerance
		"structure": return structure_tolerance
		"conduction": return conduction_tolerance
		_: return 0.0


func _damage_scale_for(key: String) -> float:
	match key:
		"thermal": return thermal_damage_scale
		"electrical": return electrical_damage_scale
		"arcane": return arcane_damage_scale
		"pressure": return pressure_damage_scale
		"structure": return structure_damage_scale
		"conduction": return conduction_damage_scale
		_: return 0.0


## Damage owed for a single axis, given its current damage-relevant value
## (see EntityProperty.get_damage_value()).
func get_channel_damage(key: String, value: float) -> float:
	return maxf(0.0, value - _tolerance_for(key)) * _damage_scale_for(key)


## Sums per-axis damage over a Dictionary of axis key -> current value, as produced by
## WorldObject.get_axis_totals(). Each axis is compared to its own tolerance before summing,
## so no axis's excess can be masked by another axis being under budget.
func compute_damage(channel_totals: Dictionary) -> float:
	var damage := 0.0
	for key in channel_totals:
		damage += get_channel_damage(key, channel_totals[key])
	return damage
