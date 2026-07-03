class_name Level
extends Node3D


@export var players: Array[Player]

@export var enemies: Array[Enemy]

@export var grid: GridMap

@export var world_simulation: WorldSimulation

@export var camera: IsometricCamera3D



func _ready() -> void:
	camera.follow_targets = players
	for player in players:
		world_simulation.register_character(player)
	for enemy in enemies:
		world_simulation.register_character(enemy)
