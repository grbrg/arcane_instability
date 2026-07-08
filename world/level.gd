class_name Level
extends Node3D


@export var player_spawner: PlayerSpawner

@export var enemy_spawner: EnemySpawner

@export var grid: GridMap

@export var world_simulation: WorldSimulation

@export var camera: IsometricCamera3D


var players: Array[Player]

var enemies: Array[Enemy]



func _ready() -> void:
	player_spawner.player_spawned.connect(_on_player_spawned)
	enemy_spawner.enemy_spawned.connect(_on_enemy_spawned)

	player_spawner.spawn_all_players()


func _on_player_spawned(player: Player) -> void:
	if not player in players:
		players.append(player)
		camera.follow_targets.append(player)
		world_simulation.register_character(player)


func _on_enemy_spawned(enemy: Enemy) -> void:
	if not enemy in enemies:
		enemies.append(enemy)
		world_simulation.register_character(enemy)