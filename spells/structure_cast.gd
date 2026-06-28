class_name StructureCast
extends Cast


func _init() -> void:
	axis = Cast.Axis.STRUCTURE
	speed = 4.0
	max_dist = 6.0


func resolve(world_simulation: WorldSimulation) -> void:
	var adj := StatAdjustment.new()
	adj.source = "player"
	adj.adjustment_type = "value"
	adj.adjustment_value = 1.0
	world_simulation.add_effect(_resolve_cell, "structure", adj)
