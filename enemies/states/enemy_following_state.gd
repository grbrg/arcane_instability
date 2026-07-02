class_name EnemyFollowingState
extends EnemyState


func _init(e: Enemy) -> void:
	super._init(e)
	name = "following"


func on_process(_delta: float) -> void:
	if enemy.target_player == null:
		enemy.change_state(enemy.idle_state)
		return
	if enemy.can_attack and enemy.distance_to_player() <= enemy.attack_range:
		enemy.change_state(enemy.attacking_state)


func on_physics_process(_delta: float) -> void:
	if enemy.target_player == null:
		return
	enemy.navigate_toward(enemy.target_player.global_position)
