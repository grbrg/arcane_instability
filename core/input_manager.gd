class_name InputManager
extends Node

# Joypad button indices for the three spell slots (Square, Circle, Triangle)
const SPELL_BUTTONS := [JOY_BUTTON_X, JOY_BUTTON_B, JOY_BUTTON_Y]

@export var world_simulation: WorldSimulation
@export var level: Level
@export var camera: Camera3D



func _physics_process(_delta: float) -> void:
	for player in level.players:
		if not player:
			continue
		var input := _get_move_input(player.device_id)
		var move_dir := Vector3.ZERO
		if input != Vector2.ZERO and camera:
			var basis := camera.global_transform.basis
			var cam_forward := -Vector3(basis.z.x, 0.0, basis.z.z).normalized()
			var cam_right := Vector3(basis.x.x, 0.0, basis.x.z).normalized()
			move_dir = (cam_right * input.x - cam_forward * input.y).normalized()
		player.set_move_input(move_dir)


func _unhandled_input(event: InputEvent) -> void:
	var player := _find_player_for_event(event)
	if player:
		_handle_player_input(event, player)
	# TEMP:
	_debug_input(event)


func _get_move_input(device_id: int) -> Vector2:
	if device_id < 0:
		var x := float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A))
		var y := float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W))
		return Vector2(x, y)
	var raw := Vector2(
		Input.get_joy_axis(device_id, JOY_AXIS_LEFT_X),
		Input.get_joy_axis(device_id, JOY_AXIS_LEFT_Y)
	)
	return raw if raw.length() > 0.2 else Vector2.ZERO


func _find_player_for_event(event: InputEvent) -> Player:
	var device_id: int
	if event is InputEventKey:
		device_id = -1
	elif event is InputEventJoypadButton:
		device_id = event.device
	else:
		return null
	for p in level.players:
		if p and p.device_id == device_id:
			return p
	return null


func _handle_player_input(event: InputEvent, player: Player) -> void:
	if event is InputEventKey:
		if event.is_action_pressed("jump"):
			player.request_jump()
		for i in SPELL_BUTTONS.size():
			if event.is_action_pressed("spell%d" % (i + 1)):
				player.request_spell(i)
			elif event.is_action_released("spell%d" % (i + 1)):
				player.release_spell(i)
	elif event is InputEventJoypadButton:
		if event.is_pressed():
			match event.button_index:
				JOY_BUTTON_A:
					player.request_jump()
				JOY_BUTTON_X:
					player.request_spell(0)
				JOY_BUTTON_B:
					player.request_spell(1)
				JOY_BUTTON_Y:
					player.request_spell(2)
		else:
			match event.button_index:
				JOY_BUTTON_X:
					player.release_spell(0)
				JOY_BUTTON_B:
					player.release_spell(1)
				JOY_BUTTON_Y:
					player.release_spell(2)


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
