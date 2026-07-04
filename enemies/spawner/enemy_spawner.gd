class_name EnemySpawner
extends Node3D


signal enemy_spawned(enemey: Enemy)
signal enemy_died
signal wave_started(wave_number: int)
signal all_waves_completed()


@export var enemy_scene: PackedScene
@export var level: Level
@export var world_simulation: WorldSimulation
@export var number_of_enemies_per_wave: int = 1
@export var number_of_waves: float = INF


var _current_wave: int = 0
var _living_enemies: int = 0


func _ready() -> void:
	if level == null:
		level = get_parent() as Level
	if world_simulation == null and level:
		world_simulation = level.world_simulation
	_start_next_wave.call_deferred()


func _start_next_wave() -> void:
	if _current_wave >= number_of_waves:
		all_waves_completed.emit()
		return
	_current_wave += 1
	wave_started.emit(_current_wave)
	for i in number_of_enemies_per_wave:
		_spawn_enemy()


func _spawn_enemy() -> void:
	if not enemy_scene:
		return
	var enemy: Enemy = enemy_scene.instantiate()
	_living_enemies += 1
	enemy.ready.connect(func():
		enemy.health.died.connect(func(): _on_enemy_died(enemy))
		enemy.level = level
		if world_simulation:
			world_simulation.register_character(enemy)
	)
	get_parent().add_child(enemy)
	enemy.global_position = global_position

	enemy_spawned.emit(enemy)


func _on_enemy_died(enemy: Enemy) -> void:
	enemy_died.emit()
	enemy.queue_free()
	_living_enemies -= 1
	if _living_enemies <= 0:
		_start_next_wave()
