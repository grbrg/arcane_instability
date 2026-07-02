class_name EnemyAttackingState
extends EnemyState


var _timer: float = 0.0


func on_enter_state() -> void:
	_timer = 0.0
	enemy.velocity.x = 0.0
	enemy.velocity.z = 0.0
	enemy.begin_attack()


func on_process(delta: float) -> void:
	_timer += delta
	if _timer >= enemy.attack_duration:
		enemy.end_attack()
		enemy.can_attack = false
		enemy.attack_cooldown_timer = enemy.attack_cooldown_duration
		if enemy.target_player != null:
			enemy.change_state(enemy.following_state)
		else:
			enemy.change_state(enemy.idle_state)
