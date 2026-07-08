class_name CastProjectile
extends Node3D

@export var move_speed := 7.5

const ARRIVAL_THRESHOLD := 0.3

var _cast: Cast
var _target_position: Vector3
var _world_simulation: WorldSimulation
var _arrived: bool = false
var _last_radiated_cell: Vector3i = Vector3i.MIN


func setup(cast: Cast, target: Vector3, world_sim: WorldSimulation) -> void:
	_cast = cast
	_target_position = target
	_world_simulation = world_sim


func _process(delta: float) -> void:
	if _arrived:
		return
	var to_target := _target_position - global_position
	var dist := to_target.length()
	if dist <= ARRIVAL_THRESHOLD:
		_arrive()
		return
	global_position += to_target.normalized() * minf(move_speed * delta, dist)
	_try_radiate()


func _try_radiate() -> void:
	var grid := _world_simulation.grid
	var current_cell := grid.local_to_map(grid.to_local(global_position))
	current_cell.y = _cast.resolve_cell.y
	if current_cell == _last_radiated_cell:
		return
	if _world_simulation.get_cell(current_cell) == null:
		return
	_last_radiated_cell = current_cell
	var is_beam := _cast.area_modifier != null \
		and _cast.area_modifier.target_area == AreaModifier.TargetArea.BEAM
	var radiate_strength := _cast.strength if is_beam else 0.5
	_cast.apply_to_cell(_world_simulation, current_cell, radiate_strength)


func _arrive() -> void:
	_arrived = true
	_cast.resolve(_world_simulation)
	_world_simulation.force_tick()
	queue_free()
