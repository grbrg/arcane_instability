class_name Entity
extends Node
##
# 
##


## the states currenty acitve
var _conditions: Array[Condition]

var _substance: EntitySubstance

var properties = {}



## WIP: will be removed

var movability: EntityProperty

var pressure: EntityProperty

## Influences the spread of the other values (randomness)
## high stability means a very small spread of the value (e. g. damage 9-11)
## low stability means a very large spread of the values (e. g. damage 2-40)
var stability: EntityProperty

## How hard is the enitity
## low hardness means it can be deformed
var hardness: EntityProperty

## How the entity interacts mechanically
## - high friction means movement with other (player, objects) is limited
## - low friction means other slide over/by the entity
var friction: EntityProperty

var absorption: EntityProperty

## How the entity reacts to metals
## <0 ... repulses metals
## 0 ... no magnetism
## >0 ... attracts metals
var magnetism: EntityProperty

## How visible is the entity
var observability: EntityProperty

var impulse: Vector3

var mass: EntityProperty




func _init(subst: EntitySubstance) -> void:
	_substance = subst
	properties["thermal"] = ThermalEnergy.new(0.1, _substance)


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
