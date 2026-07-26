class_name CastProjectile
extends Node3D

@export var move_speed := 7.5

const _BOUNCE_DIRS: Array[Vector3i] = [
	Vector3i( 1, 0,  0), Vector3i(-1, 0,  0),
	Vector3i( 0, 0,  1), Vector3i( 0, 0, -1),
	Vector3i( 1, 0,  1), Vector3i( 1, 0, -1),
	Vector3i(-1, 0,  1), Vector3i(-1, 0, -1),
]

var _cast: Cast
var _velocity: Vector3
var _lifetime: float = 0.0
var _world_simulation: WorldSimulation
var _arrived: bool = false
var _last_radiated_cell: Vector3i = Vector3i.MIN
var _affected_cells: Dictionary = {}
var _is_shard: bool = false
var _final_cell: Vector3i

@onready var _sound: AudioStreamPlayer3D = $Sound


func _ready() -> void:
	_sound.finished.connect(_sound.play)
	_sound.play()


func setup(cast: Cast, target: Vector3, world_sim: WorldSimulation) -> void:
	_cast = cast
	_world_simulation = world_sim
	var grid := world_sim.grid
	_final_cell = grid.local_to_map(grid.to_local(target))
	_final_cell.y = cast.resolve_cell.y
	var to_target := target - global_position
	var dist := to_target.length()
	_velocity = to_target.normalized() * move_speed
	# Aim at the target cell for as long as covering that distance would take;
	# once the timer runs out the projectile dies wherever it actually ended up,
	# which lets impulses or collisions carry it off its original line.
	_lifetime = dist / maxf(move_speed, 0.001)


func _process(delta: float) -> void:
	if _arrived:
		return
	var step := minf(delta, _lifetime)
	global_position += _velocity * step
	_lifetime -= step
	if _lifetime <= 0.0:
		_arrive()
		return
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
	# The destination cell gets its own full-strength hit on arrival (see _arrive);
	# radiating into it here as well would double-apply the effect there.
	if current_cell == _final_cell:
		return
	if _world_simulation.get_cell(current_cell) == null:
		return
	_affected_cells[current_cell] = true
	_cast.apply_to_cell(_world_simulation, current_cell, _cast.strength / 2)


func _arrive() -> void:
	_arrived = true
	var grid := _world_simulation.grid
	var current_cell := grid.local_to_map(grid.to_local(global_position))
	current_cell.y = _cast.resolve_cell.y
	if _is_shard:
		if current_cell != _cast.player_cell:
			_cast.apply_to_cell(_world_simulation, current_cell, _cast.strength)
	else:
		_cast.resolve_cell = current_cell
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
