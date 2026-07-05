class_name ImpulseCast
extends Cast


func _init() -> void:
	axis = Cast.Axis.IMPULSE
	speed = 6.0
	distance_modifier = DistanceModifier.new()
	distance_modifier.distance = DistanceModifier.Distance.MIDDLE


func resolve(world_simulation: WorldSimulation) -> void:
	var adj := StatAdjustment.new()
	adj.source = "player"
	adj.adjustment_type = "value"
	adj.direction = Vector2(_cast_dir.x, _cast_dir.z).normalized()
	world_simulation.add_effect(_resolve_cell, "impulse", adj)
