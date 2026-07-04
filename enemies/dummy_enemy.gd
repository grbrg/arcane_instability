class_name DummyEnemy
extends Enemy


@export var spin_speed: float = 720.0
@export var attack_heat: float = 1.0

var _is_attacking: bool = false


func begin_attack() -> void:
	_is_attacking = true
	_heat_attack_area()


func end_attack() -> void:
	_is_attacking = false


func _heat_attack_area() -> void:
	if not level or not target_player:
		return
	var sim := level.world_simulation
	var grid := sim.grid
	var player_index := grid.local_to_map(grid.to_local(target_player.global_position))
	var adj := StatAdjustment.new()
	adj.source = "enemy_attack"
	adj.adjustment_type = "value"
	adj.adjustment_value = attack_heat
	sim.add_effect(player_index, "thermal", adj)


func _physics_process(delta: float) -> void:
	super(delta)
	if _is_attacking:
		rotate_y(deg_to_rad(spin_speed) * delta)
