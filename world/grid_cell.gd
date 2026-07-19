class_name GridCell
extends Node

# Fraction of the cell impulse vector applied to a character's velocity per tick.
const CHARACTER_IMPULSE_SCALE := 0.25
# Fraction of the stored impulse that decays per second (for the indicator / visual).
# 0.9375 = retention squared vs. the old 0.75, i.e. same decay curve in half the time.
const IMPULSE_DECAY := 0.99

var grid: GridMap
var index: Vector3i
var neighbours: Array[GridCell] = []

var ambient: Ambient

var characters: Array[Character] = []
var world_objects: Array[WorldObject] = []

var impulse_indicator: ImpulseIndicator

var current_impulse: Vector3 = Vector3.ZERO


func _init(idx: Vector3i, _grid: GridMap) -> void:
	index = idx
	grid = _grid


func add_effect(type: String, adj: StatAdjustment) -> void:
	for wo in world_objects:
		wo.add_effect(type, adj)


func add_world_object(wo: WorldObject) -> void:
	if not wo in world_objects:
		world_objects.append(wo)


func remove_world_object(wo: WorldObject) -> void:
	world_objects.erase(wo)


func add_character(character: Character) -> void:
	if not character in characters:
		characters.append(character)


func remove_character(character: Character) -> void:
	characters.erase(character)


func can_have_condition(type: String) -> bool:
	for wo in world_objects:
		for c in wo.conditions:
			if c.type == type:
				return c.is_possible
	return false


func has_active_condition(type: String) -> bool:
	for wo in world_objects:
		for c in wo.conditions:
			if c.type == type and c.is_active():
				return true
	return false


func invalidate_property_caches() -> void:
	for wo in world_objects:
		wo.invalidate_property_caches()


func diffuse() -> void:
	for wo in world_objects:
		wo.diffuse_to_neighbours()


func diffuse_pressure() -> void:
	for wo in world_objects:
		wo.diffuse_pressure_to_neighbours()


func tick(delta: float) -> void:
	for wo in world_objects:
		wo.tick(delta, ambient)

	for character in characters:
		character.apply_stress_from_cell(self)


# Returns the air pressure in this cell. Only air drives impulse;
# pressure stored in solid objects does not contribute to air flow.
func get_pressure() -> float:
	for wo in world_objects:
		if wo.substance_name == "air":
			var prop = wo.entity.get_property("pressure")
			if prop:
				return prop.get_value()
	return 0.0


# Computes the impulse vector for this cell from pressure differences to neighbours.
# Direction points toward lower-pressure neighbours; magnitude reflects the gradient.
func compute_impulse() -> Vector3:
	var my_pressure := get_pressure()
	var impulse := Vector3.ZERO
	for neighbour in neighbours:
		var diff := my_pressure - neighbour.get_pressure()
		var dir := Vector3(
			float(neighbour.index.x - index.x),
			0.0,
			float(neighbour.index.z - index.z)
		).normalized()
		impulse += dir * diff
	if not neighbours.is_empty():
		impulse /= float(neighbours.size())
	return impulse


# Called once per tick: only replaces the stored impulse if the new gradient is stronger.
func update_impulse(impulse: Vector3) -> void:
	if impulse.length() > current_impulse.length():
		current_impulse = impulse


# Called once per tick: kicks object velocities and character velocity from the impulse.
func apply_impulse_to_objects(impulse: Vector3) -> void:
	var flat := Vector3(impulse.x, 0.0, impulse.z)
	if flat.length() < 0.01:
		return
	for wo in world_objects:
		if wo.moveable:
			wo.receive_impulse(flat)
	for character in characters:
		character.receive_impulse(flat * CHARACTER_IMPULSE_SCALE)


# Called every frame: integrates object velocities and updates the indicator.
func apply_frame_movement(delta: float) -> void:
	current_impulse = current_impulse.lerp(Vector3.ZERO, 1.0 - pow(1.0 - IMPULSE_DECAY, delta))

	if impulse_indicator:
		impulse_indicator.update(current_impulse)

	var flat := Vector3(current_impulse.x, 0.0, current_impulse.z)
	for wo in world_objects:
		if wo.moveable:
			wo.apply_velocity(delta)
			wo.receive_impulse(flat)
		wo.apply_impulse_visual(flat)
	for character in characters:
		character.receive_impulse(flat * CHARACTER_IMPULSE_SCALE)
