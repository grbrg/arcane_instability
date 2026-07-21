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

	# Toon-shade every mesh in the level (ground, walls, world objects, player, enemies)
	# except property views, which are tagged to opt out -- see toon_relight.gd. Also
	# catches meshes spawned later (players, enemies, projectiles).
	ToonRelight.apply_to_subtree(self)
	get_tree().node_added.connect(ToonRelight.apply_to_node)

	player_spawner.spawn_all_players()


func _on_player_spawned(player: Player) -> void:
	if not player in players:
		players.append(player)
		camera.add_follow_target(player)
		world_simulation.register_character(player)


func _on_enemy_spawned(enemy: Enemy) -> void:
	if not enemy in enemies:
		enemies.append(enemy)
		world_simulation.register_character(enemy)