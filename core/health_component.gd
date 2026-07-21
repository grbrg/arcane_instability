class_name HealthComp
extends Node


signal integrity_changed(current: float, maximum: float)
signal died()


@export var max_integrity: float = 100.0

var integrity: float


func _ready() -> void:
	integrity = max_integrity


func take_damage(amount: float) -> void:
	if amount <= 0.0 or is_dead():
		return
	integrity = maxf(0.0, integrity - amount)
	integrity_changed.emit(integrity, max_integrity)
	if integrity <= 0.0:
		died.emit()


func is_dead() -> bool:
	return integrity <= 0.0
