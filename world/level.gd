class_name Level
extends Node3D


@export var players: Array[Player]

@export var grid: GridMap

@export var world_simulation: WorldSimulation

@export var camera: IsometricCamera3D



func _ready() -> void:
	camera.follow_targets = players
