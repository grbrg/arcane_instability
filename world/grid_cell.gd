class_name GridCell
extends Node


var grid: GridMap
var index: Vector3i
var neighbours: Array[GridCell] = []

var entity: Entity

#
var _property_views = {} #: Array[EntityPropertyView]

var substance: EntitySubstance

var ambient: Ambient

## entities on this cell, e. g. water, stone, steam, or other materials
var sub_entities: Array[Entity]

var conditions: Array[Condition]


func _init(idx: Vector3i, _grid: GridMap, _subst: EntitySubstance) -> void:
	index = idx
	grid = _grid

	substance = _subst

	entity = Entity.new(substance)
	entity.thermal_energy_diffusion.connect(on_thermal_energy_diffusion)


##
func add_effect(type: String, adj: StatAdjustment) -> void:
	# check if we can add thermal properties
	var prop = entity.get_property(type) #as ThermalEnergy
	if prop:
		"""var adj = StatAdjustment.new()
		adj.source = "debug"
		adj.adjustment_type = "spell"
		adj.adjustment_value = amount		
		"""
		prop.add_adjustment(adj)

		if not type in _property_views:
			var temperature_view = ResourceManager.thermal_view_scene.instantiate() as TemperatureView
			_add_property_view("thermal", temperature_view, prop)
			self.add_child(temperature_view)
			temperature_view.position = grid.map_to_local(index)
			temperature_view.update(ambient)
			_property_views["thermal"] = temperature_view



func _add_property_view(type: String, view: EntityPropertyView, prop: EntityProperty) -> void:
	_property_views[type] = view
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


func on_thermal_energy_diffusion(amount: float):
	var amount_per_neighbour = amount / len(neighbours)
	if amount_per_neighbour > 0.01:
		for n in neighbours:
			var adj = StatAdjustment.new()
			adj.source = str(index)
			adj.adjustment_type = "spell"
			adj.adjustment_value = amount_per_neighbour				
			n.add_effect("thermal", adj)


func tick(delta: float) -> void:
	entity.tick(delta, ambient)

	for key in _property_views:
		var view = _property_views[key]
		view.update(ambient)