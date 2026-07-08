class_name StructureCast
extends Cast


func _init() -> void:
	axis = Cast.Axis.STRUCTURE
	speed = 4.0
	distance_modifier = DistanceModifier.new()
	distance_modifier.distance = DistanceModifier.Distance.SHORT


func apply_to_cell(world_simulation: WorldSimulation, cell: Vector3i, strength: float) -> void:
	var adj := StatAdjustment.new()
	adj.source = "player"
	adj.adjustment_type = "value"
	adj.adjustment_value = strength
	world_simulation.add_effect(cell, "structure", adj)
