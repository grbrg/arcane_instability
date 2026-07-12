class_name WorldObject
extends Node3D


@export var substance_name: String = "grass"
@export var mass: float = 1.0
@export var moveable: bool = false

var substance: Substance
var entity: Entity
var conditions: Array[Condition] = []
var _property_views = {}
var current_cell: GridCell

var _velocity: Vector3 = Vector3.ZERO
# Fraction of velocity lost per second via friction.
const VELOCITY_DECAY := 0.85


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
		elif type == "pressure" and substance_name != "air":
			var view = ResourceManager.pressure_view_scene.instantiate() as PressureView
			_create_property_view(type, view, prop)


func _create_property_view(type: String, view: EntityPropertyView, prop: EntityProperty) -> void:
	_property_views[type] = view
	view.cell = current_cell
	view.my_property = prop
	current_cell.add_child(view)
	view.position = current_cell.grid.map_to_local(current_cell.index)
	view.update(current_cell.ambient)


## Called by WorldSimulation when this object moves to a different cell.
## Cleans up cell-anchored property views; condition views stay parented to this object.
func set_current_cell(new_cell: GridCell) -> void:
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
			if cv:
				add_child(cv)
				cv.position = Vector3.ZERO


## Override to respond to impulse visually without moving (e.g. grass sway, fire lean).
func apply_impulse_visual(_impulse: Vector3) -> void:
	pass


func receive_impulse(impulse: Vector3) -> void:
	var effective := impulse / maxf(mass, 0.1)
	if effective.length_squared() < 0.00001:
		return
	var dir := effective.normalized()
	var current_component := _velocity.dot(dir)
	if current_component < effective.length():
		_velocity += dir * (effective.length() - current_component)


func apply_velocity(delta: float) -> void:
	if _velocity.length_squared() < 0.0001:
		_velocity = Vector3.ZERO
		return
	global_position += _velocity * delta
	_velocity = _velocity.lerp(Vector3.ZERO, 1.0 - pow(1.0 - VELOCITY_DECAY, delta))


func invalidate_property_caches() -> void:
	for type in entity.properties:
		entity.get_property(type).invalidate_cache()


func diffuse_pressure_to_neighbours() -> void:
	if not current_cell:
		return
	var prop := entity.get_property("pressure")
	if not prop:
		return
	var val: float = prop.get_value()
	var cond_val: float = prop.get_conductivity()
	for n in current_cell.neighbours:
		for n_obj in n.world_objects:
			var n_prop = n_obj.entity.get_property("pressure")
			if not n_prop:
				continue
			var amount: float = (val - n_obj.entity.get_property("pressure").get_value()) * cond_val
			if amount > 0:
				var adj := StatAdjustment.new()
				adj.source = str(current_cell.index)
				adj.adjustment_type = "value"
				adj.adjustment_value = amount
				n_obj.add_effect("pressure", adj)


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
