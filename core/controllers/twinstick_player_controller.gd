class_name TwinstickPlayerController
extends PlayerController

var _trigger_pressed := false


func handle_joypad_button(event: InputEventJoypadButton) -> void:
	if event.is_pressed():
		match event.button_index:
			JOY_BUTTON_LEFT_SHOULDER: _player.request_spell(0)
			JOY_BUTTON_RIGHT_SHOULDER: _player.request_spell(1)
	else:
		match event.button_index:
			JOY_BUTTON_LEFT_SHOULDER: _player.release_spell(0)
			JOY_BUTTON_RIGHT_SHOULDER: _player.release_spell(1)


func poll_joypad(device_id: int, camera: Camera3D) -> void:
	_update_aim(device_id, camera)
	_update_left_trigger(device_id)


func _update_aim(device_id: int, camera: Camera3D) -> void:
	var raw := Vector2(
		Input.get_joy_axis(device_id, JOY_AXIS_RIGHT_X),
		Input.get_joy_axis(device_id, JOY_AXIS_RIGHT_Y)
	)
	var aim_dir := Vector3.ZERO
	var magnitude := 0.0
	if raw.length() > STICK_DEADZONE:
		var basis := camera.global_transform.basis
		var cam_forward := -Vector3(basis.z.x, 0.0, basis.z.z).normalized()
		var cam_right := Vector3(basis.x.x, 0.0, basis.x.z).normalized()
		aim_dir = (cam_right * raw.x - cam_forward * raw.y).normalized()
		magnitude = clampf((raw.length() - STICK_DEADZONE) / (1.0 - STICK_DEADZONE), 0.0, 1.0)
	set_aim_input(aim_dir)
	if aim_dir != Vector3.ZERO:
		_player.redirect_active_spell(aim_dir, magnitude)


func _update_left_trigger(device_id: int) -> void:
	var pressed := Input.get_joy_axis(device_id, JOY_AXIS_TRIGGER_LEFT) > TRIGGER_DEADZONE
	if pressed and not _trigger_pressed:
		_player.request_spell(2)
	elif not pressed and _trigger_pressed:
		_player.release_spell(2)
	_trigger_pressed = pressed
