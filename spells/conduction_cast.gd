class_name ConductionCast
extends Cast


func _init() -> void:
	axis = Cast.Axis.CONDUCTION
	speed = 4.0
	distance_modifier = DistanceModifier.new()
	distance_modifier.distance = DistanceModifier.Distance.MIDDLE


func resolve(world_simulation: WorldSimulation) -> void:
	var adj := StatAdjustment.new()
	adj.source = "player"
	adj.adjustment_type = "value"
	adj.adjustment_value = 1.0
	world_simulation.add_effect(_resolve_cell, "conduction", adj)
