class_name StructureProperty
extends EntityProperty
# Structure axis: hardness, stability, brittleness.
# Does not spread to neighbours. Recovers toward base_value over time.

var recovery: float


func _init(base: float, _recovery: float) -> void:
	super(base, 1.0, 0.0, 0.0)
	recovery = _recovery


func tick(delta: float, _ambient: Ambient) -> void:
	var adjs = get_adjustments_of_type("value")
	for adj in adjs:
		adj.adjustment_value = lerp(adj.adjustment_value, 0.0, 1.0 - pow(1.0 - recovery, delta))
		if abs(adj.adjustment_value) < 0.01:
			adj.adjustment_value = 0.0
		if adj.adjustment_value == 0.0:
			remove_adjustment(adj)
