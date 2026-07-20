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
# Deceleration from friction, in units/s^2. Scaled by the current cell's traction via
# GridCell.apply_traction, the same mechanic that slows character control on ice, so a
# pushed object slides further across a cold cell instead of stopping quickly.
const FRICTION := 10.0


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
## Cleans up cell-anchored property views; condition views stay parented to this object.
func set_current_cell(new_cell: GridCell) -> void:
	for type in _property_views:
		_property_views[type].queue_free()
	_property_views.clear()

	current_cell = new_cell


## Sums this object's own energy channels (thermal/electrical/arcane), positive-only.
func get_positive_energy_sum() -> float:
	var total := 0.0
	for key in entity.properties:
		var prop = entity.properties[key]
		if prop is EnergyProperty and not (prop is PressureProperty):
			total += prop.get_damage_value()
	return total


## Damages this object's own structure once its energy exceeds the substance's tolerance.
## Flat per-tick, matching Character.take_stress (both fire on the same simulation tick).
func _apply_energy_stress() -> void:
	var excess = maxf(0.0, get_positive_energy_sum() - substance.energy_tolerance)
	if excess <= 0.0:
		return
	var structure = entity.get_property("structure")
	if not structure:
		return
	var adj := StatAdjustment.new()
	adj.source = "energy_stress"
	adj.adjustment_type = "value"
	adj.adjustment_value = -excess * substance.energy_damage_scale
	structure.add_adjustment(adj)


func tick(delta: float, ambient: Ambient) -> void:
	for cond in conditions:
		cond.tick(delta, entity, ambient)

	entity.tick(delta, ambient)

	_apply_energy_stress()

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
	var traction: float = current_cell.get_traction() if current_cell else 1.0
	_velocity = GridCell.apply_traction(_velocity, Vector3.ZERO, FRICTION, traction, delta)


func invalidate_property_caches() -> void:
	for type in entity.properties:
		entity.get_property(type).invalidate_cache()


## Diffuses every EnergyProperty channel (thermal/electrical/arcane/pressure) to neighbouring
## cells' world objects. Pressure is an EnergyProperty (see pressure_property.gd) so it's
## covered here too — no separate pressure pass needed.
func diffuse_to_neighbours() -> void:
	if not current_cell:
		return
	for type in entity.properties:
		var prop := entity.get_property(type)
		if not prop is EnergyProperty:
			continue
		var val: float = prop.get_value()
		var cond_val: float = prop.get_conductivity() * prop.get_diffusion_rate()
		for n in current_cell.neighbours:
			for n_obj in n.world_objects:
				var n_prop = n_obj.entity.get_property(type)
				if not n_prop:
					continue
				var n_val: float = n_prop.get_value()
				var gap: float = val - n_val
				# Clamp to the gap itself: the source is never decremented here, so an
				# uncapped transfer with conductivity * diffusion_rate > 1.0 can push the
				# neighbour past the source's own value, flipping which side is "high" and
				# compounding into a runaway oscillation over subsequent ticks.
				var amount: float = minf(gap * cond_val, gap)
				if amount > 0:
					var adj := StatAdjustment.new()
					adj.source = str(current_cell.index)
					adj.adjustment_type = "value"
					adj.adjustment_value = amount
					n_obj.add_effect(type, adj)
