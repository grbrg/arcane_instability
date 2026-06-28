class_name ImpulseCast
extends Cast


func _init() -> void:
	axis = Cast.Axis.IMPULSE
	speed = 6.0
	max_dist = 8.0


func resolve(world_simulation: WorldSimulation) -> void:
	var adj := StatAdjustment.new()
	adj.source = "player"
	adj.adjustment_type = "value"
	adj.adjustment_value = 1.0
	world_simulation.add_effect(_resolve_cell, "impulse", adj)
