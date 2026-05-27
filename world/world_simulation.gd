class_name WorldSimulation
extends Node3D


@export var camera: Camera3D
@export var grid: GridMap

@onready var disc = preload("res://levels/experimental/dummy_disc.tscn")



##
func add_effect(grid_index: Vector3i) -> void:
	var marker = disc.instantiate()
	self.add_child(marker)
	marker.position = grid.map_to_local(grid_index)


##
func get_grid_index(pos: Vector2) -> Vector3i:
	var target = Helper3D.get_object_at(camera, pos)
	if target:
		var grid_index = grid.local_to_map(target.position)
		return grid_index

	return Vector3i.MIN
