class_name PlayerController
extends Node

const STICK_DEADZONE := 0.2
const TRIGGER_DEADZONE := 0.5

@export var move_speed: float = 5.0
@export var acceleration: float = 15.0
@export var turn_speed: float = 10.0

var _move_dir: Vector3 = Vector3.ZERO
var _aim_dir: Vector3 = Vector3.ZERO
var _last_move_dir: Vector3 = Vector3.FORWARD
var _jump_requested: bool = false
var _player: Player


func _init(_p: Player) -> void:
	_player = _p


func set_move_input(dir: Vector3) -> void:
	_move_dir = dir


func set_aim_input(dir: Vector3) -> void:
	_aim_dir = dir


func request_jump() -> void:
	_jump_requested = true


func get_facing_dir() -> Vector3:
	if _aim_dir != Vector3.ZERO:
		return _aim_dir
	return _last_move_dir


func handle_joypad_button(_event: InputEventJoypadButton) -> void:
	pass


func poll_joypad(_device_id: int, _camera: Camera3D) -> void:
	pass


func physics_process(delta: float, has_active_spell: bool) -> void:
	_handle_jump()
	_apply_movement(delta)
	_player.move_and_slide()
	_update_rotation(delta, has_active_spell)


func _handle_jump() -> void:
	if _jump_requested:
		_player.try_jump()
	_jump_requested = false


func _apply_movement(delta: float) -> void:
	var target := _move_dir * move_speed
	_player.velocity.x = move_toward(_player.velocity.x, target.x, acceleration * delta)
	_player.velocity.z = move_toward(_player.velocity.z, target.z, acceleration * delta)


func _update_rotation(delta: float, has_active_spell: bool) -> void:
	var target_dir := Vector3.ZERO
	if _aim_dir != Vector3.ZERO:
		target_dir = _aim_dir
	elif not has_active_spell and _move_dir != Vector3.ZERO:
		target_dir = _move_dir
	if target_dir != Vector3.ZERO:
		_last_move_dir = _last_move_dir.lerp(target_dir.normalized(), turn_speed * delta).normalized()
	_player.rotation.y = atan2(_last_move_dir.x, _last_move_dir.z)
