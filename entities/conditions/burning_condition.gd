class_name BurningCondition
extends Condition


@onready var burning_scene = preload("res://world/conditions/burning/burning.tscn")


##
func activate(cell: GridCell) -> ConditionView:
	super.activate(cell)

	var fire = burning_scene.instantiate() as BurningView
	_scene = fire

	return _scene


## Checks whether the condition should be activated
func check_activation(_entity: Entity, _ambient: Ambient) -> bool:
	if not is_possible:
		return false

	var thermal = _entity.properties["thermal"] as ThermalEnergy
	var temp = thermal.get_temperature(_ambient)
	if temp > 0.6:
		return true

	return false


##
func check_deactiviation(_entity: Entity, _ambient: Ambient) -> bool:
	if not is_possible:
		return false
	
	if _is_active:
		var thermal = _entity.properties["thermal"] as ThermalEnergy
		var temp = thermal.get_temperature(_ambient)
		if temp < 0.1:
			return true

	return false

