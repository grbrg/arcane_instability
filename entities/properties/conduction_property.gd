class_name ConductionProperty
extends EntityProperty
# Conduction axis: how well this entity transmits energy and impulse.
# Static value defined by the material; adjustable via StatAdjustments.


func _init(base: float) -> void:
	super(base, 1.0, 0.0, 0.0)
