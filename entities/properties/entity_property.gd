class_name EntityProperty
extends Node


signal property_value_changed(source: EntityProperty)


var base_value: float

var capacity: float = 0.9

var conductivity = 0.0

var decay = 0.1

var _adjustments = []

var _value_valid: bool = false
var _capacity_valid: bool = false
var _conductivity_valid: bool = false
var _decay_valid: bool = false
var _value_cache: float = 0.0
var _capacity_cache: float = 0.0
var _conductivity_cache: float = 0.0
var _decay_cache: float = 0.0


func invalidate_cache() -> void:
	_value_valid = false
	_capacity_valid = false
	_conductivity_valid = false
	_decay_valid = false


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
		if abs(existing.adjustment_value) <= abs(adjustment.adjustment_value):
			existing.adjustment_value = adjustment.adjustment_value
	invalidate_cache()


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
	if not _capacity_valid:
		var v = capacity
		for adj in _adjustments:
			if "capacity" == adj.adjustment_type:
				v += adj.adjustment_value
				v *= adj.adjustment_factor
		_capacity_cache = v
		_capacity_valid = true
	return _capacity_cache


##
func get_conductivity():
	if not _conductivity_valid:
		var v = conductivity
		for adj in _adjustments:
			if "conductivity" == adj.adjustment_type:
				v += adj.adjustment_value
				v *= adj.adjustment_factor
		_conductivity_cache = v
		_conductivity_valid = true
	return _conductivity_cache


##
func get_decay():
	if not _decay_valid:
		var v = decay
		for adj in _adjustments:
			if "decay" == adj.adjustment_type:
				v += adj.adjustment_value
				v *= adj.adjustment_factor
		_decay_cache = v
		_decay_valid = true
	return _decay_cache


##
func get_value():
	if not _value_valid:
		var v = base_value
		for adj in _adjustments:
			if "value" == adj.adjustment_type:
				v += adj.adjustment_value
				v *= adj.adjustment_factor
		_value_cache = v
		_value_valid = true
	return _value_cache


##
func has_adjustment(source: String) -> bool:
	var adj = get_adjustment_from(source)
	if adj:
		return true

	return false


##
func remove_adjustment(adjustment: StatAdjustment):
	_adjustments.erase(adjustment)
	invalidate_cache()


##
func remove_adjustments(source: String):
	_adjustments = _adjustments.filter(func(a): return a.source != source)
	invalidate_cache()


##
func tick(_delta: float, _ambient: Ambient) -> void:
	pass
	# Overwrite in subclasses
