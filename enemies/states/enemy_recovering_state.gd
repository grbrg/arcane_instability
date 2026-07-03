class_name EnemyRecoveringState
extends EnemyState


func _init(e: Enemy) -> void:
	super._init(e)
	name = "recovering"


func on_enter_state() -> void:
	enemy.velocity.x = 0.0
	enemy.velocity.z = 0.0


func on_process(_delta: float) -> void:
	if enemy.can_attack:
		if enemy.target_player != null and enemy.distance_to_player() <= enemy.attack_range:
			enemy.change_state(enemy.attacking_state)
		elif enemy.target_player != null:
			enemy.change_state(enemy.following_state)
		else:
			enemy.change_state(enemy.idle_state)
