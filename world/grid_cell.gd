class_name GridCell
extends Node



var grid: GridMap
var index: Vector3i
var neighbours: Array[GridCell] = []

var entity: Entity

var _ground: Ground

#
var _property_views = {} #: Array[EntityPropertyView]

var _subst_type: String
var substance: Substance

var ambient: Ambient

## entities on this cell, e. g. water, stone, steam, or other materials
var sub_entities: Array[Entity]

var conditions: Array[Condition]

var characters: Array[Character] = []


##
func _init(idx: Vector3i, _grid: GridMap, _subst: String) -> void:
	index = idx
	grid = _grid
	_subst_type = _subst

	substance = SubstanceRegistry.get_substance(_subst_type)

	"""if _subst == "grass":
		_ground = ResourceManager.grass_scene.instantiate()
	else:
		_ground = ResourceManager.ground_scene.instantiate()
	_ground.set_substance(_subst_type)
	add_child(_ground)
	_ground.position = grid.local_to_map(index)
	_ground.position.y = 0.0"""
	#Log.d("%s -> %d" % [str(index), _ground.position.y])
	

	entity = Entity.new(substance)

	add_condition(BurningCondition.new())


##
func add_effect(type: String, adj: StatAdjustment) -> void:
	# check if we can add thermal properties
	var prop = entity.get_property(type)
	if prop:
		prop.add_adjustment(adj)

		if not type in _property_views:
			var temperature_view = ResourceManager.thermal_view_scene.instantiate() as TemperatureView
			_add_property_view(type, temperature_view, prop)
			self.add_child(temperature_view)
			temperature_view.position = grid.map_to_local(index)
			temperature_view.update(ambient)
			_property_views[type] = temperature_view


func add_character(character: Character) -> void:
	if not character in characters:
		characters.append(character)


func remove_character(character: Character) -> void:
	characters.erase(character)


func add_condition(cond: Condition) -> void:
	conditions.append(cond)
	add_child(cond)


func _add_property_view(type: String, view: EntityPropertyView, prop: EntityProperty) -> void:
	_property_views[type] = view
	view.cell = self
	view.my_property = prop


## 
func activate_condition(condition: Condition) -> bool:
	for c in conditions:
		if c.type == condition.type:
			c.activate(self)
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
			return c.is_active()

	# TODO: check all child entitities (objects) on this cell?

	return false


func invalidate_property_caches() -> void:
	for type in entity.properties:
		entity.get_property(type).invalidate_cache()


func diffuse() -> void:
	for type in entity.properties:
		var prop := entity.get_property(type)
		if not prop is EnergyProperty:
			continue
		var val: float = prop.get_value()
		var cond: float = prop.get_conductivity()
		for n in neighbours:
			var n_val: float = n.entity.get_property(type).get_value()
			var amount: float = (val - n_val) * cond
			var adj := StatAdjustment.new()
			adj.source = str(index)
			adj.adjustment_type = "value"
			adj.adjustment_value = amount
			if amount != 0:
				n.add_effect(type, adj)


##
func tick(delta: float) -> void:
	# update the enitity properties
	entity.tick(delta, ambient)

	# update the views based on that
	for key in _property_views:
		var view = _property_views[key]
		view.update(ambient)

	# check for conditions
	for cond in conditions:
		# check if it should deactivate
		if cond.check_deactiviation(entity, ambient):
			cond.deactivate(self)
		elif cond.check_activation(entity, ambient):
			var cv = cond.activate(self) as ConditionView
			if cv:
				add_child(cv)
				cv.position = grid.map_to_local(index)

	for character in characters:
		character.apply_stress_from_cell(self)
