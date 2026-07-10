class_name PlayerSpawner
extends Node3D

const _Registry := preload("res://core/build_registry.gd")


signal player_spawned(player: Player)
signal player_died(device_id: int)


@export var player_scene: PackedScene
@export var level: Level
@export var world_simulation: WorldSimulation
@export var number_of_players: int = 1
@export var respawn_delay: float = 10.0
@export var player_colors: Array[Color] = [Color.DARK_GREEN, Color.INDIAN_RED, Color.SKY_BLUE, Color.DEEP_PINK]


func _ready() -> void:
	if level == null:
		level = get_parent() as Level
	if world_simulation == null and level:
		world_simulation = level.world_simulation


func spawn_all_players() -> void:
	for i in number_of_players:
		_spawn_player(i)


func _spawn_player(device_id: int) -> void:
	if not player_scene:
		return
	var player: Player = player_scene.instantiate()
	player.device_id = device_id
	player.level = level
	player.ready.connect(func():
		var color: Color
		if device_id < _Registry.builds.size():
			color = _Registry.builds[device_id].get("color", Color.WHITE)
		elif device_id < player_colors.size():
			color = player_colors[device_id]
		else:
			color = Color.WHITE
		player.set_player_color(color)
		if world_simulation:
			world_simulation.register_character(player)
		if level:
			level.players.append(player)
			if level.camera:
				level.camera.follow_targets.append(player)
		player.health.died.connect(func(): _on_player_died(player, device_id))
	)
	get_parent().add_child(player)

	var spawn_pos = global_position
	spawn_pos.x += device_id * 2
	player.global_position = spawn_pos

	player_spawned.emit(player)


func _on_player_died(player: Player, device_id: int) -> void:
	player_died.emit(device_id)
	if level:
		level.players.erase(player)
		if level.camera:
			level.camera.follow_targets.erase(player)
	player.queue_free()
	get_tree().create_timer(respawn_delay).timeout.connect(func(): _spawn_player(device_id))
