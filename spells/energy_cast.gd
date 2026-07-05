class_name EnergyCast
extends Cast


func _init() -> void:
	axis = Cast.Axis.ENERGY
	speed = 4.0
	energy_type_modifier = EnergyTypeModifier.new()
	energy_type_modifier.type = EnergyTypeModifier.Type.THERMAL
	distance_modifier = DistanceModifier.new()
	distance_modifier.distance = DistanceModifier.Distance.SHORT


func resolve(world_simulation: WorldSimulation) -> void:
	var adj := StatAdjustment.new()
	adj.source = "player"
	adj.adjustment_type = "value"
	adj.adjustment_value = 1.0
	world_simulation.add_effect(_resolve_cell, _energy_type(), adj)


func _energy_type() -> String:
	if energy_type_modifier != null:
		return energy_type_modifier.get_energy_type()
	return "thermal"
