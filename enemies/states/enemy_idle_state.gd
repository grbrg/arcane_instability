class_name EnemyIdleState
extends EnemyState


var idle_duration: float = 2.0

var _timer: float = 0.0


func _init(e: Enemy) -> void:
	super._init(e)
	name = "idle"


func on_enter_state() -> void:
	_timer = 0.0
	enemy.velocity.x = 0.0
	enemy.velocity.z = 0.0


func on_process(delta: float) -> void:
	_timer += delta
	if _timer >= idle_duration:
		enemy.change_state(enemy.wandering_state)
