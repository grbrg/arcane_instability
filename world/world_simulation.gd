class_name WorldSimulation
extends Node3D



@export var grid: GridMap
@export var camera: Camera3D


@onready var disc = preload("res://levels/experimental/dummy_disc.tscn")


##
func _unhandled_input(event: InputEvent) -> void:

	# handle mouse events
	if event is InputEventMouseButton:
		var mouse_pos = get_viewport().get_mouse_position()
		var target = Helper3D.get_object_at(camera, mouse_pos)
		if target:
			var grid_index = grid.local_to_map(target.position)
			Log.d("Click at " + str(target.position) + " -> Index:" + str(grid_index))

			var marker = disc.instantiate()
			self.add_child(marker)
			marker.position = grid.map_to_local(grid_index)
