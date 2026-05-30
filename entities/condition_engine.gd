class_name ConditionEngine
extends Node


func tick(delta: float, cell: GridCell) -> void:

	for c in cell.conditions:
		c.check_activation()
		c.check_deactiviation()