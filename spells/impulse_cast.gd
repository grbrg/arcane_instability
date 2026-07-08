class_name ImpulseCast
extends Cast


func _init() -> void:
	axis = Cast.Axis.IMPULSE
	speed = 6.0
	distance_modifier = DistanceModifier.new()
	distance_modifier.distance = DistanceModifier.Distance.MIDDLE


func apply_to_cell(world_simulation: WorldSimulation, cell: Vector3i, strength: float) -> void:
	var adj := StatAdjustment.new()
	adj.source = "player"
	adj.adjustment_type = "value"
	adj.adjustment_value = strength
	adj.direction = Vector2(_cast_dir.x, _cast_dir.z).normalized()
	world_simulation.add_effect(cell, "impulse", adj)
