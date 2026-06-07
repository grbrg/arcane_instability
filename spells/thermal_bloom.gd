class_name ThermalBloom
extends Spell


func _init() -> void:
	speed = 4.0
	max_dist = 8.0


func _on_cast(_target: Vector3) -> void:
	pass # TODO: apply heat/burning at target position
