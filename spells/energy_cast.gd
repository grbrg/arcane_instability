class_name EnergyCast
extends Cast


func _init() -> void:
	axis = Cast.Axis.ENERGY
	speed = 4.0
	energy_type_modifier = EnergyTypeModifier.new()
	energy_type_modifier.type = EnergyTypeModifier.Type.THERMAL
	distance_modifier = DistanceModifier.new()
	distance_modifier.distance = DistanceModifier.Distance.AROUND_PLAYER
	area_modifier = AreaModifier.new()
	area_modifier.target_area = AreaModifier.TargetArea.POINT


func apply_to_cell(world_simulation: WorldSimulation, cell: Vector3i, strength: float) -> void:
	var adj := StatAdjustment.new()
	adj.source = "player"
	adj.adjustment_type = "value"
	adj.adjustment_value = strength
	world_simulation.add_effect(cell, _energy_type(), adj)


func _energy_type() -> String:
	if energy_type_modifier != null:
		return energy_type_modifier.get_energy_type()
	return "thermal"
