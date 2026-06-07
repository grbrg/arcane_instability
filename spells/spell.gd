class_name Spell
extends Node

@export var speed: float = 5.0
@export var max_dist: float = 10.0

var action: String = ""
var marker: Node3D = null

var is_active: bool:
	get: return _active

var _active: bool = false
var _dist: float = 0.0


func try_activate(origin: Vector3, _dir: Vector3) -> bool:
	if not Input.is_action_just_pressed(action):
		return false
	_active = true
	_dist = 0.0
	marker.visible = true
	marker.global_position = origin
	return true


func process(delta: float, origin: Vector3, dir: Vector3) -> void:
	_dist = minf(_dist + speed * delta, max_dist)
	marker.global_position = origin + dir * _dist
	if Input.is_action_just_released(action):
		_active = false
		marker.visible = false
		_on_cast(marker.global_position)


func _on_cast(_target: Vector3) -> void:
	pass
