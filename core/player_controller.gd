class_name PlayerController
extends Node

@export var move_speed: float = 5.0
@export var acceleration: float = 15.0
@export var turn_speed: float = 10.0

var _move_dir: Vector3 = Vector3.ZERO
var _last_move_dir: Vector3 = Vector3.FORWARD
var _jump_requested: bool = false
var _character: Character


func _ready() -> void:
	_character = get_parent() as Character


func set_move_input(dir: Vector3) -> void:
	_move_dir = dir


func request_jump() -> void:
	_jump_requested = true


func get_facing_dir() -> Vector3:
	return _last_move_dir


func physics_process(delta: float, has_active_spell: bool) -> void:
	_handle_jump()
	_apply_movement(delta)
	_character.move_and_slide()
	_update_rotation(delta, has_active_spell)


func _handle_jump() -> void:
	if _jump_requested and _character.is_on_floor():
		_character.try_jump()
	_jump_requested = false


func _apply_movement(delta: float) -> void:
	var target := _move_dir * move_speed
	_character.velocity.x = move_toward(_character.velocity.x, target.x, acceleration * delta)
	_character.velocity.z = move_toward(_character.velocity.z, target.z, acceleration * delta)


func _update_rotation(delta: float, has_active_spell: bool) -> void:
	if not has_active_spell and _move_dir != Vector3.ZERO:
		_last_move_dir = _last_move_dir.lerp(_move_dir.normalized(), turn_speed * delta).normalized()
	_character.rotation.y = atan2(_last_move_dir.x, _last_move_dir.z)
