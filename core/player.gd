class_name Player
extends Character

@export var move_speed: float = 5.0
@export var acceleration: float = 15.0
#@export var jump_velocity: float = 5.0



var _move_dir: Vector3 = Vector3.ZERO
var _jump_requested: bool = false




func set_move_input(dir: Vector3) -> void:
	_move_dir = dir


func request_jump() -> void:
	_jump_requested = true


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		#velocity.y -= _gravity * delta
		apply_gravity(delta)

	if _jump_requested and is_on_floor():
		#velocity.y = jump_velocity
		try_jump()
	_jump_requested = false

	var target := _move_dir * move_speed
	velocity.x = move_toward(velocity.x, target.x, acceleration * delta)
	velocity.z = move_toward(velocity.z, target.z, acceleration * delta)

	move_and_slide()
