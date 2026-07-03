class_name Condition
extends Node


## the type of condition
var type: String

## flag whether this condition can be triggered at all
var is_possible: bool = true

## flag whether this condition os currently active
var _is_active: bool = false

##
var _scene: ConditionView


##
func activate(_cell: GridCell) -> ConditionView:
	_is_active = true
	return null


## Checks whether the condition should be activated
func check_activation(_entity: Entity, _ambient: Ambient) -> bool:
	if not is_possible:
		return false

	return false


##
func check_deactiviation(_entity: Entity, _ambient: Ambient) -> bool:
	if not is_possible:
		return false

	return false


##
func tick(_delta: float, _entity: Entity, _ambient: Ambient) -> void:
	pass


##
func deactivate(_cell: GridCell) -> void:
	_is_active = false
	_scene.ramp_down()


##
func is_active() -> bool:
	return _is_active


