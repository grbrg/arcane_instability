class_name EntityProperty
extends Node


var base_value: float

var _substance: EntitySubstance

var _adjustments = []


##
func _init(_base_value: float, _subst: EntitySubstance) -> void:
	base_value = _base_value
	_substance = _subst


func add_adjustment(adjustment: StatAdjustment):
	# only one adjustment per source allowed
	if adjustment and not has_adjustment(adjustment.source):
		_adjustments.append(adjustment)


func get_adjustments_from(source: String) -> Array[StatAdjustment]:
	var adjs: Array[StatAdjustment] = []
	for adj in _adjustments:
		if adj is StatAdjustment:
			if adj.source == source:
				adjs.append(adj)
	return adjs


func get_adjustments_of_type(type: String) -> Array[StatAdjustment]:
	var adjs: Array[StatAdjustment] = []
	for adj in _adjustments:
		if adj is StatAdjustment:
			if adj.adjustment_type == type:
				adjs.append(adj)
	return adjs


func get_value(val: float, for_type: String = ""):
	var v = val
	for adj in _adjustments:
		if for_type.is_empty() or for_type == adj.adjustment_type:
			v += adj.adjustment_value
			v *= adj.adjustment_factor
	return v


func has_adjustment(source: String) -> bool:
	var adj = get_adjustments_from(source)
	if len(adj) > 0:
		return true

	return false


func remove_adjustment(adjustment: StatAdjustment):
	_adjustments.erase(adjustment)


func remove_adjustments(source: String):
	for adj in _adjustments:
		if adj.source == source:
			_adjustments.erase(adj)


func tick(_delta: float, ambient: Ambient) -> void:
	pass
