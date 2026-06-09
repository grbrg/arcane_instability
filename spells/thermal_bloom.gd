class_name ThermalBloom
extends Spell


func _init() -> void:
	speed = 4.0
	max_dist = 8.0


func _on_cast(world_simulation: WorldSimulation, cell_index: Vector3i) -> void:
	var adj = StatAdjustment.new()
	adj.source = "debug" + str(Time.get_ticks_msec())
	adj.adjustment_type = "value" # we adjust the value directly
	adj.adjustment_value = 1.0
	world_simulation.add_effect(cell_index, adj)
