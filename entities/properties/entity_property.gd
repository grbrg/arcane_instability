class_name EntityProperty
extends Node


signal property_value_changed(source: EntityProperty, amount: float)


var base_value: float

var capacity: float = 0.9

var conductivity = 0.9

var decay = 0.1

var _adjustments = []


##
func _init(_base_value: float, _cap: float, _cond: float, _decay: float) -> void:
	base_value = _base_value
	capacity = _cap
	conductivity = _cond
	decay = _decay


##
func add_adjustment(adjustment: StatAdjustment):
	if not adjustment:
		return

	# only one adjustment per source allowed
	if not has_adjustment(adjustment.source):
		_adjustments.append(adjustment)
	else:
		# take the highest/lowest value
		var existing = get_adjustment_from(adjustment.source) as StatAdjustment
		if abs(existing.adjustment_value) < abs(adjustment.adjustment_value):
			existing.adjustment_value = adjustment.adjustment_value


##
func get_adjustment_from(source: String) -> StatAdjustment:
	for adj in _adjustments:
		if adj is StatAdjustment:
			if adj.source == source:
				return adj
	return null


## Return the adjustments of the given type:
# - value
# - capacity
# - conductivity
# - decay
func get_adjustments_of_type(type: String) -> Array[StatAdjustment]:
	var adjs: Array[StatAdjustment] = []
	for adj in _adjustments:
		if adj is StatAdjustment:
			if adj.adjustment_type == type:
				adjs.append(adj)
	return adjs


##
func get_capacity():
	var v = capacity
	for adj in _adjustments:
		if "capacity" == adj.adjustment_type:
			v += adj.adjustment_value
			v *= adj.adjustment_factor
	return v


##
func get_conductivity():
	var v = conductivity
	for adj in _adjustments:
		if "conductivity" == adj.adjustment_type:
			v += adj.adjustment_value
			v *= adj.adjustment_factor
	return v


##
func get_decay():
	var v = decay
	for adj in _adjustments:
		if "decay" == adj.adjustment_type:
			v += adj.adjustment_value
			v *= adj.adjustment_factor
	return v


##
func get_value():
	var v = base_value
	for adj in _adjustments:
		if "value" == adj.adjustment_type:
			v += adj.adjustment_value
			v *= adj.adjustment_factor
	return v


##
func has_adjustment(source: String) -> bool:
	var adj = get_adjustment_from(source)
	if adj:
		return true

	return false


##
func remove_adjustment(adjustment: StatAdjustment):
	_adjustments.erase(adjustment)


##
func remove_adjustments(source: String):
	for adj in _adjustments:
		if adj.source == source:
			_adjustments.erase(adj)


##
func tick(_delta: float, _ambient: Ambient) -> void:
	pass
	# Overwrite in subclasses
