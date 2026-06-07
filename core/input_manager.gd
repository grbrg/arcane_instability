class_name InputManager
extends Node


@export var world_simulation: WorldSimulation

@export var player: Player
@export var camera: Camera3D


func _physics_process(_delta: float) -> void:
	if not player:
		return

	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var move_dir := Vector3.ZERO
	if input != Vector2.ZERO and camera:
		var basis := camera.global_transform.basis
		var cam_forward := -Vector3(basis.z.x, 0.0, basis.z.z).normalized()
		var cam_right := Vector3(basis.x.x, 0.0, basis.x.z).normalized()
		move_dir = (cam_right * input.x - cam_forward * input.y).normalized()

	player.set_move_input(move_dir)
	if Input.is_action_just_pressed("jump"):
		player.request_jump()


func _unhandled_input(event: InputEvent) -> void:
	pass




func _debug_input(event: InputEvent) -> void:
	# handle mouse events
	if event is InputEventMouseButton and event.is_pressed():
		var mouse_pos = get_viewport().get_mouse_position()
		if world_simulation:
			var grid_index = world_simulation.get_grid_index(mouse_pos)
			if grid_index != Vector3i.MIN:
				if event.button_index == MOUSE_BUTTON_LEFT:
					var adj = StatAdjustment.new()
					adj.source = "debug" + str(Time.get_ticks_msec())
					adj.adjustment_type = "value" # we adjust the value directly
					adj.adjustment_value = 1.0				
					world_simulation.add_effect(grid_index, adj)
				if event.button_index == MOUSE_BUTTON_RIGHT:
					var adj = StatAdjustment.new()
					adj.source = "debug" + str(Time.get_ticks_msec())
					adj.adjustment_type = "value" # we adjust the value directly
					adj.adjustment_value = -1.0				
					world_simulation.add_effect(grid_index, adj)