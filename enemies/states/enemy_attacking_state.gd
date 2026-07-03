class_name EnemyAttackingState
extends EnemyState


var _timer: float = 0.0



func _init(e: Enemy) -> void:
	super._init(e)
	name = "attacking"


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
		enemy.change_state(enemy.recovering_state)
