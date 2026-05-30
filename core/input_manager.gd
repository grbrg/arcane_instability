extends Node


@export var world_simulation: WorldSimulation



##
func _unhandled_input(event: InputEvent) -> void:

	# handle mouse events
	if event is InputEventMouseButton and event.is_pressed():
		var mouse_pos = get_viewport().get_mouse_position()
		if world_simulation:
			var grid_index = world_simulation.get_grid_index(mouse_pos)
			if grid_index != Vector3i.MIN:
				var adj = StatAdjustment.new()
				adj.source = "debug"
				adj.adjustment_type = "spell"
				adj.adjustment_value = 1.0				
				world_simulation.add_effect(grid_index, adj)
