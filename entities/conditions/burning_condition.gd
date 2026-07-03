class_name BurningCondition
extends Condition


@onready var burning_scene = preload("res://world/conditions/burning/burning.tscn")

var burn_duration: float = 9.0

var _burn_elapsed: float = 0.0


##
func activate(cell: GridCell) -> ConditionView:
	if not _is_active:
		super.activate(cell)
		_burn_elapsed = 0.0

		var fire = burning_scene.instantiate() as BurningView
		_scene = fire

		return _scene
	return null


## While active, replenish heat and track elapsed time
func tick(delta: float, _entity: Entity, _ambient: Ambient) -> void:
	if not _is_active:
		return
	_burn_elapsed += delta
	if _burn_elapsed >= burn_duration:
		return
	var thermal := _entity.properties["thermal"] as ThermalEnergy
	var adj := StatAdjustment.new()
	adj.source = "burning"
	adj.adjustment_type = "value"
	adj.adjustment_value = 0.8
	thermal.add_adjustment(adj)


## Checks whether the condition should be activated
func check_activation(_entity: Entity, _ambient: Ambient) -> bool:
	if not is_possible:
		return false

	var thermal = _entity.properties["thermal"] as ThermalEnergy
	var temp = thermal.get_temperature(_ambient)
	if temp > _entity.substance.burning_temperature:
		return true

	return false


##
func check_deactiviation(_entity: Entity, _ambient: Ambient) -> bool:
	if not is_possible:
		return false

	if _is_active:
		if _burn_elapsed >= burn_duration:
			return true
		var thermal = _entity.properties["thermal"] as ThermalEnergy
		var temp = thermal.get_temperature(_ambient)
		if temp < 0.1:
			return true

	return false
