class_name WorldCursorPlayerController
extends PlayerController

@export var cursor_speed: float = 6.0
@export var max_cursor_distance: float = 6.0

var _cursor_pos: Vector3 = Vector3.ZERO
var _following_player: bool = true
var _raw_stick: Vector2 = Vector2.ZERO
var _camera: Camera3D = null
var _has_active_cast: bool = false

var _l1_pressed := false
var _l2_pressed := false
var _r1_pressed := false
var _r2_pressed := false


func handle_joypad_button(event: InputEventJoypadButton) -> void:
	if event.is_pressed():
		match event.button_index:
			JOY_BUTTON_RIGHT_STICK: _following_player = true


func poll_joypad(device_id: int, camera: Camera3D) -> void:
	_raw_stick = Vector2(
		Input.get_joy_axis(device_id, JOY_AXIS_RIGHT_X),
		Input.get_joy_axis(device_id, JOY_AXIS_RIGHT_Y)
	)
	_camera = camera
	_update_cast_inputs(device_id)


func physics_process(delta: float, has_active_cast: bool) -> void:
	_has_active_cast = has_active_cast
	_update_cursor(delta)
	super.physics_process(delta, has_active_cast)
	# Re-pin marker after move_and_slide() has moved the player (and drifted the child node)
	_cursor_pos.y = _player.global_position.y
	_player.set_cast_marker_position(_cursor_pos)


func _update_cursor(delta: float) -> void:
	var stick_active := _raw_stick.length() > STICK_DEADZONE and _camera != null

	if stick_active:
		_following_player = false
		var basis := _camera.global_transform.basis
		var cam_forward := -Vector3(basis.z.x, 0.0, basis.z.z).normalized()
		var cam_right := Vector3(basis.x.x, 0.0, basis.x.z).normalized()
		var move_dir := (cam_right * _raw_stick.x - cam_forward * _raw_stick.y).normalized()
		_cursor_pos += move_dir * cursor_speed * delta
	elif _following_player:
		_cursor_pos = _player.global_position

	_cursor_pos.y = _player.global_position.y

	var to_cursor := _cursor_pos - _player.global_position
	if to_cursor.length() > max_cursor_distance:
		if stick_active:
			to_cursor = to_cursor.normalized() * max_cursor_distance
			_cursor_pos = _player.global_position + to_cursor
		else:
			_cursor_pos = _player.global_position
			_following_player = true
			to_cursor = Vector3.ZERO

	var displaced := to_cursor.length() > 0.5
	_player.set_cast_marker_visible(displaced or _has_active_cast)
	set_aim_input(to_cursor.normalized() if displaced else Vector3.ZERO)


func _update_cast_inputs(device_id: int) -> void:
	var r2 := Input.get_joy_axis(device_id, JOY_AXIS_TRIGGER_RIGHT) > TRIGGER_DEADZONE
	var r1 := Input.is_joy_button_pressed(device_id, JOY_BUTTON_RIGHT_SHOULDER)
	var l2 := Input.get_joy_axis(device_id, JOY_AXIS_TRIGGER_LEFT) > TRIGGER_DEADZONE
	var l1 := Input.is_joy_button_pressed(device_id, JOY_BUTTON_LEFT_SHOULDER)

	if r2 != _r2_pressed:
		if r2: _player.request_cast(Player.BUTTON_R2)
		else:  _player.release_cast(Player.BUTTON_R2)
	if r1 != _r1_pressed:
		if r1: _player.request_cast(Player.BUTTON_R1)
		else:  _player.release_cast(Player.BUTTON_R1)
	if l2 != _l2_pressed:
		if l2: _player.request_cast(Player.BUTTON_L2)
		else:  _player.release_cast(Player.BUTTON_L2)
	if l1 != _l1_pressed:
		if l1: _player.request_cast(Player.BUTTON_L1)
		else:  _player.release_cast(Player.BUTTON_L1)

	_r2_pressed = r2
	_r1_pressed = r1
	_l2_pressed = l2
	_l1_pressed = l1
