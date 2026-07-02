class_name Entity
extends Node
##
#
##


## the states currenty acitve
var _conditions: Array[Condition]

var substance: Substance

var properties = {}



##
func _init(subst: Substance) -> void:
	substance = subst

	properties = substance.create_properties()


##
func get_property(type: String) -> EntityProperty:
	if type in properties:
		return properties[type]

	return null


## Return the current conditions of the entity
func get_active_conditions() -> Array[Condition]:
	return _conditions


##
func tick(delta: float, ambient: Ambient) -> void:
	for prop_type in properties:
		var property = properties[prop_type]
		property.tick(delta, ambient)

