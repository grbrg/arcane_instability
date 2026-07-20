class_name GridCell
extends Node

# Fraction of the cell impulse vector applied to a character's velocity per tick.
const CHARACTER_IMPULSE_SCALE := 0.25
# Fraction of the stored impulse that decays per second (for the indicator / visual).
# 0.9375 = retention squared vs. the old 0.75, i.e. same decay curve in half the time.
const IMPULSE_DECAY := 0.99

# Temperature at/above which traction is unaffected.
# Air's thermal_capacity is 0.05 (substance_registry.gd), so a single cold hit at the
# default cast/debug strength of 1.0 only moves air temperature by ~0.05 — these
# thresholds are calibrated against that (a few stacked cold hits), not against
# burning_temperature's 0.2-0.65 range (read off objects with much higher capacity,
# e.g. grass/kindling).
const COLD_TRACTION_START := -0.03
# Temperature at/below which traction bottoms out (full ice).
const COLD_TRACTION_FULL := -0.15
# Acceleration multiplier on full ice.
const MIN_TRACTION := 0.15

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


# Returns the air temperature in this cell, falling back to ambient if no air object is present.
func get_temperature() -> float:
	for wo in world_objects:
		if wo.substance_name == "air":
			var prop := wo.entity.get_property("thermal") as ThermalEnergy
			if prop:
				return prop.get_temperature(ambient)
	return ambient.temperature if ambient else 0.0


# Acceleration multiplier characters should move with in this cell: 1.0 normally,
# dropping toward MIN_TRACTION as the cell gets colder than COLD_TRACTION_START (ice).
func get_traction() -> float:
	var temp := get_temperature()
	if temp >= COLD_TRACTION_START:
		return 1.0
	var t := clampf(inverse_lerp(COLD_TRACTION_START, COLD_TRACTION_FULL, temp), 0.0, 1.0)
	return lerpf(1.0, MIN_TRACTION, t)


# Moves a horizontal velocity toward a target (the desired move speed for characters,
# Vector3.ZERO for friction on world objects) at `rate`, scaled by traction. Shared by
# Character control and WorldObject friction so both slide the same way on icy cells.
static func apply_traction(velocity: Vector3, target: Vector3, rate: float, traction: float, delta: float) -> Vector3:
	var result := velocity
	result.x = move_toward(result.x, target.x, rate * traction * delta)
	result.z = move_toward(result.z, target.z, rate * traction * delta)
	return result


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


# Returns the current value of each axis in this cell, keyed by its debug-overlay letter
# label. T(hermal), E(lectrical), A(rcane) and P(ressure) are the raw signed get_value()
# summed across every world object in the cell, so a cold/inverted cast shows as negative
# instead of vanishing. Character.apply_stress_from_cell() sums the same properties for
# damage but additionally drops any per-object/channel value <= 0 before summing (so a
# cold source can't cancel a hot source's damage elsewhere in the cell) — so T/E/A here
# can differ from the damage total whenever a cell mixes positive and negative sources on
# the same channel; in the common single-source case they match. S(tructure) and
# C(onduction) come from the strongest non-air object present. I(mpulse) is the cell's
# current impulse magnitude.
func get_debug_values() -> Dictionary:
	var thermal := 0.0
	var electrical := 0.0
	var arcane := 0.0
	var pressure := 0.0
	var values := {}
	for wo in world_objects:
		var thermal_prop := wo.entity.get_property("thermal")
		if thermal_prop:
			thermal += thermal_prop.get_value()
		var electrical_prop := wo.entity.get_property("electrical")
		if electrical_prop:
			electrical += electrical_prop.get_value()
		var arcane_prop := wo.entity.get_property("arcane")
		if arcane_prop:
			arcane += arcane_prop.get_value()
		var pressure_prop := wo.entity.get_property("pressure")
		if pressure_prop:
			pressure += pressure_prop.get_value()

		if wo.substance_name != "air":
			var structure := wo.entity.get_property("structure")
			if structure:
				values["S"] = structure.get_value()
			var conduction := wo.entity.get_property("conduction")
			if conduction:
				values["C"] = conduction.get_value()
	values["T"] = thermal
	values["E"] = electrical
	values["A"] = arcane
	values["P"] = pressure
	values["I"] = current_impulse.length()
	return values


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
