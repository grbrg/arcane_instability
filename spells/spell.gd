class_name Spell
extends Node




@export var speed: float = 5.0
@export var max_dist: float = 10.0

# marker (set from the player)
var marker: Node3D = null

var is_active: bool:
	get: return _active

var _active: bool = false
var _dist: float = 0.0
var _cast_dir: Vector3 = Vector3.FORWARD
var _manual_dist: bool = false

# where the spells resolves
var _resolve_cell: Vector3i


func activate_marker(origin: Vector3, dir: Vector3) -> void:
	_active = true
	_dist = 0.0
	_cast_dir = dir
	_manual_dist = false
	marker.visible = true
	marker.global_position = origin
	marker.rotation.y = atan2(_cast_dir.x, _cast_dir.z)


func deactivate_marker(world_simulation: WorldSimulation, cell_index: Vector3i) -> void:
	if not _active:
		return
	_active = false
	marker.visible = false
	_on_cast(world_simulation, cell_index)


func redirect(dir: Vector3, magnitude: float = -1.0) -> void:
	if not _active or dir == Vector3.ZERO:
		return
	_cast_dir = dir
	if magnitude >= 0.0:
		_dist = magnitude * max_dist
		_manual_dist = true


func process(delta: float, origin: Vector3, _dir: Vector3) -> void:
	if not _manual_dist:
		_dist = minf(_dist + speed * delta, max_dist)
	marker.global_position = origin + _cast_dir * _dist
	marker.rotation.y = atan2(_cast_dir.x, _cast_dir.z)


##
func _on_cast(world_simulation: WorldSimulation, cell_index: Vector3i) -> void:
	_resolve_cell = cell_index
	world_simulation.add_spell_to_be_resolved(self)


## To be overwritten
func resolve(world_simulation: WorldSimulation) -> void:
	pass
