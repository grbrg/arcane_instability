class_name Condition
extends Node


## the type of condition
var type: String

## flag whether this condition can be triggered at all
var is_possible: bool = false

## flag whether this condition os currently active
var is_active: bool = false:
	get:
		return is_active
	set(value):
		is_active = value
		# TODO: trigger animation etc.?



## Checks whether the condition should be activated
func check_activation() -> bool:
	if not is_possible:
		return false

	return false


func check_deactiviation() -> bool:
	if not is_possible:
		return false

	return false

