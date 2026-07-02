class_name EnemyWanderingState
extends EnemyState


var _wander_target: Vector3



func _init(e: Enemy) -> void:
	super._init(e)
	name = "wandering"


func on_enter_state() -> void:
	_pick_wander_target()


func on_process(_delta: float) -> void:
	if enemy.nav_agent.is_navigation_finished():
		enemy.change_state(enemy.idle_state)


func on_physics_process(_delta: float) -> void:
	enemy.navigate_toward(_wander_target)


func _pick_wander_target() -> void:
	var angle := randf() * TAU
	var dist := randf() * enemy.wander_radius
	_wander_target = enemy.origin_position + Vector3(
		cos(angle) * dist,
		0.0,
		sin(angle) * dist
	)
	enemy.nav_agent.target_position = _wander_target
