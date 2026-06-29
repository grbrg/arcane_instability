class_name ImpulseProperty
extends EntityProperty
# Impulse axis: pressure, movement, shockwaves.
# Stored as a Vector2 whose magnitude encodes strength.
# Multiple impulses from different sources accumulate additively.


func get_vector() -> Vector2:
	var v := Vector2.ZERO
	for adj in get_adjustments_of_type("value"):
		v += adj.direction
	return v


func add_adjustment(adjustment: StatAdjustment) -> void:
	if not adjustment:
		return
	if not has_adjustment(adjustment.source):
		_adjustments.append(adjustment)
	else:
		get_adjustment_from(adjustment.source).direction += adjustment.direction


func tick(delta: float, _ambient: Ambient) -> void:
	var adjs = get_adjustments_of_type("value")
	for adj in adjs:
		adj.direction = adj.direction.lerp(Vector2.ZERO, 1.0 - pow(1.0 - get_decay(), delta))
		property_value_changed.emit(self)
		if adj.direction.length() < 0.01:
			remove_adjustment(adj)
