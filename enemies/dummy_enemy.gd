class_name DummyEnemy
extends Enemy


@export var spin_speed: float = 720.0

var _is_attacking: bool = false


func begin_attack() -> void:
	_is_attacking = true


func end_attack() -> void:
	_is_attacking = false


func _physics_process(delta: float) -> void:
	super(delta)
	if _is_attacking:
		rotate_y(deg_to_rad(spin_speed) * delta)
