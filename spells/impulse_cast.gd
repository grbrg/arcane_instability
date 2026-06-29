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
	adj.direction = Vector2(_cast_dir.x, _cast_dir.z).normalized()
	world_simulation.add_effect(_resolve_cell, "impulse", adj)
