class_name CastProjectile
extends Node3D

@export var move_speed := 7.5

const ARRIVAL_THRESHOLD := 0.3

const _BOUNCE_DIRS: Array[Vector3i] = [
	Vector3i( 1, 0,  0), Vector3i(-1, 0,  0),
	Vector3i( 0, 0,  1), Vector3i( 0, 0, -1),
	Vector3i( 1, 0,  1), Vector3i( 1, 0, -1),
	Vector3i(-1, 0,  1), Vector3i(-1, 0, -1),
]

var _cast: Cast
var _target_position: Vector3
var _world_simulation: WorldSimulation
var _arrived: bool = false
var _last_radiated_cell: Vector3i = Vector3i.MIN
var _affected_cells: Dictionary = {}
var _is_shard: bool = false


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
	_last_radiated_cell = current_cell
	if _affected_cells.has(current_cell):
		return
	if current_cell == _cast.player_cell:
		return
	if _world_simulation.get_cell(current_cell) == null:
		return
	_affected_cells[current_cell] = true
	var is_beam := _cast.area_modifier != null \
		and _cast.area_modifier.target_area == AreaModifier.TargetArea.BEAM
	var radiate_strength := _cast.strength if is_beam else (_cast.strength / 2)
	_cast.apply_to_cell(_world_simulation, current_cell, radiate_strength)
	if is_beam:
		_world_simulation.force_tick()


func _arrive() -> void:
	_arrived = true
	if _is_shard:
		var grid := _world_simulation.grid
		var cell := grid.local_to_map(grid.to_local(global_position))
		cell.y = _cast.resolve_cell.y
		if cell != _cast.player_cell:
			_cast.apply_to_cell(_world_simulation, cell, _cast.strength)
	else:
		_cast.resolve(_world_simulation)
		_spawn_bounce_shards()
	_world_simulation.force_tick()
	queue_free()


func _spawn_bounce_shards() -> void:
	if _cast.extension_modifier == null:
		return
	if _cast.extension_modifier.extension != ExtensionModifier.Extension.BOUNCING:
		return
	var shard_scene := load("res://spells/cast_projectile.tscn") as PackedScene
	var grid := _world_simulation.grid
	var origin_cell := _cast.resolve_cell
	for dir in _BOUNCE_DIRS:
		if randf() > 0.75:
			continue
		var dist := randi_range(1, 2)
		var target_cell: Vector3i = origin_cell + dir * dist
		var target_world: Vector3 = grid.to_global(grid.map_to_local(target_cell))
		target_world.y = global_position.y
		var shard := shard_scene.instantiate() as CastProjectile
		shard._is_shard = true
		get_parent().add_child(shard)
		shard.global_position = global_position
		shard.setup(_cast, target_world, _world_simulation)
