class_name Spell
extends Node




@export var speed: float = 5.0
@export var max_dist: float = 10.0

var marker: Node3D = null

var is_active: bool:
	get: return _active

var _active: bool = false
var _dist: float = 0.0


func activate_marker(origin: Vector3, _dir: Vector3) -> void:
	_active = true
	_dist = 0.0
	marker.visible = true
	marker.global_position = origin


func deactivate_marker(world_simulation: WorldSimulation, cell_index: Vector3i) -> void:
	if not _active:
		return
	_active = false
	marker.visible = false
	_on_cast(world_simulation, cell_index)


func process(delta: float, origin: Vector3, dir: Vector3) -> void:
	_dist = minf(_dist + speed * delta, max_dist)
	marker.global_position = origin + dir * _dist


func _on_cast(world_simulation: WorldSimulation, cell_index: Vector3i) -> void:
	pass
