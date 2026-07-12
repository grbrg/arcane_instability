class_name TwinstickPlayerController
extends PlayerController

func uses_cast_marker() -> bool:
	return false


func snaps_cast_to_distance() -> bool:
	return true


var _l1_pressed := false
var _l2_pressed := false
var _r1_pressed := false
var _r2_pressed := false


func poll_joypad(device_id: int, camera: Camera3D) -> void:
	_update_aim(device_id, camera)
	_update_cast_inputs(device_id)


func _update_aim(device_id: int, camera: Camera3D) -> void:
	var raw := Vector2(
		Input.get_joy_axis(device_id, JOY_AXIS_RIGHT_X),
		Input.get_joy_axis(device_id, JOY_AXIS_RIGHT_Y)
	)
	var aim_dir := Vector3.ZERO
	if raw.length() > STICK_DEADZONE:
		var basis := camera.global_transform.basis
		var cam_forward := -Vector3(basis.z.x, 0.0, basis.z.z).normalized()
		var cam_right := Vector3(basis.x.x, 0.0, basis.x.z).normalized()
		aim_dir = (cam_right * raw.x - cam_forward * raw.y).normalized()
	set_aim_input(aim_dir)


func _update_cast_inputs(device_id: int) -> void:
	var r2 := Input.get_joy_axis(device_id, JOY_AXIS_TRIGGER_RIGHT) > TRIGGER_DEADZONE
	var r1 := Input.is_joy_button_pressed(device_id, JOY_BUTTON_RIGHT_SHOULDER)
	var l2 := Input.get_joy_axis(device_id, JOY_AXIS_TRIGGER_LEFT) > TRIGGER_DEADZONE
	var l1 := Input.is_joy_button_pressed(device_id, JOY_BUTTON_LEFT_SHOULDER)

	if r2 != _r2_pressed:
		if r2: _player.request_cast(Player.SLOT_ENERGY)
		else:  _player.release_cast(Player.SLOT_ENERGY)
	if r1 != _r1_pressed:
		if r1: _player.request_cast(Player.SLOT_PRESSURE)
		else:  _player.release_cast(Player.SLOT_PRESSURE)
	if l2 != _l2_pressed:
		if l2: _player.request_cast(Player.SLOT_STRUCTURE)
		else:  _player.release_cast(Player.SLOT_STRUCTURE)
	if l1 != _l1_pressed:
		if l1: _player.request_cast(Player.SLOT_CONDUCTION)
		else:  _player.release_cast(Player.SLOT_CONDUCTION)

	_r2_pressed = r2
	_r1_pressed = r1
	_l2_pressed = l2
	_l1_pressed = l1
