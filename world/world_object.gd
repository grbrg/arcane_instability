class_name WorldObject
extends Node3D


@export var substance_name: String = "grass"
@export var mass: float = 1.0

var substance: Substance
var entity: Entity
var conditions: Array[Condition] = []
var _property_views = {}
var current_cell: GridCell


func _ready() -> void:
	add_to_group("world_objects")
	substance = SubstanceRegistry.get_substance(substance_name)
	entity = Entity.new(substance)
	_setup_conditions()


## Override in subclasses to add specific conditions
func _setup_conditions() -> void:
	_add_condition(BurningCondition.new())


func _add_condition(cond: Condition) -> void:
	conditions.append(cond)
	add_child(cond)


func add_effect(type: String, adj: StatAdjustment) -> void:
	var prop = entity.get_property(type)
	if not prop:
		return
	prop.add_adjustment(adj)
	if not type in _property_views and current_cell:
		if type == "thermal":
			var view = ResourceManager.thermal_view_scene.instantiate() as TemperatureView
			_create_property_view(type, view, prop)


func _create_property_view(type: String, view: EntityPropertyView, prop: EntityProperty) -> void:
	_property_views[type] = view
	view.cell = current_cell
	view.my_property = prop
	current_cell.add_child(view)
	view.position = current_cell.grid.map_to_local(current_cell.index)
	view.update(current_cell.ambient)


## Called by WorldSimulation when this object moves to a different cell.
## Cleans up views tied to the old cell; they will be recreated on the next add_effect call.
func set_current_cell(new_cell: GridCell) -> void:
	for cond in conditions:
		if cond.is_active():
			cond.deactivate(current_cell)

	for type in _property_views:
		_property_views[type].queue_free()
	_property_views.clear()

	current_cell = new_cell


func tick(delta: float, ambient: Ambient) -> void:
	for cond in conditions:
		cond.tick(delta, entity, ambient)

	entity.tick(delta, ambient)

	for key in _property_views:
		_property_views[key].update(ambient)

	for cond in conditions:
		if cond.check_deactiviation(entity, ambient):
			cond.deactivate(current_cell)
		elif cond.check_activation(entity, ambient):
			var cv = cond.activate(current_cell) as ConditionView
			if cv and current_cell:
				current_cell.add_child(cv)
				cv.position = current_cell.grid.map_to_local(current_cell.index)


func invalidate_property_caches() -> void:
	for type in entity.properties:
		entity.get_property(type).invalidate_cache()


func diffuse_to_neighbours() -> void:
	if not current_cell:
		return
	for type in entity.properties:
		var prop := entity.get_property(type)
		if not prop is EnergyProperty:
			continue
		var val: float = prop.get_value()
		var cond_val: float = prop.get_conductivity()
		for n in current_cell.neighbours:
			for n_obj in n.world_objects:
				var n_prop = n_obj.entity.get_property(type)
				if not n_prop:
					continue
				var n_val: float = n_prop.get_value()
				var amount: float = (val - n_val) * cond_val
				if amount > 0:
					var adj := StatAdjustment.new()
					adj.source = str(current_cell.index)
					adj.adjustment_type = "value"
					adj.adjustment_value = amount
					n_obj.add_effect(type, adj)
