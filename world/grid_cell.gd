class_name GridCell
extends Node


var index: Vector3i
var neighbours: Array[GridCell] = []

var entity: Entity
var _property_views: Array[EntityPropertyView]

var substance: EntitySubstance

## entities on this cell, e. g. water, stone, steam, or other materials
var sub_entities: Array[Entity]

var conditions: Array[Condition]


func _init(idx: Vector3i) -> void:
	index = idx

	# DEBUG:
	substance = EntitySubstance.new()

	entity = Entity.new(substance)


func add_property_view(view: EntityPropertyView, prop: EntityProperty) -> void:
	_property_views.append(view)
	view.cell = self
	view.my_property = prop


func _ready() -> void:
	# gather all conditions
	for child in get_children():
		if child is Condition:
			conditions.append(child)


## TODO: Do we need this? Or is this done automatically 
func activate_condition(condition: Condition) -> bool:
	for c in conditions:
		if c.type == condition.type:
			c.is_active = true
			return true
	
	return false


## check whether the cell can have the given condition
func can_have_condition(type: String) -> bool:
	for c in conditions:
		if c.type == type:
			return c.is_possible
	
	# TODO: check all child entitities (objects) on this cell?

	return false


## check whether the cell has the given condition active
func has_active_condition(type: String) -> bool:
	for c in conditions:
		if c.type == type:
			return c.is_active
	
	# TODO: check all child entitities (objects) on this cell?

	return false



func tick(delta: float, ambient: Ambient) -> void:
	entity.tick(delta, ambient)

	for view in _property_views:
		view.update(ambient)