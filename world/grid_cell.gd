class_name GridCell
extends Node



var grid: GridMap
var index: Vector3i
var neighbours: Array[GridCell] = []

var ambient: Ambient

var characters: Array[Character] = []
var world_objects: Array[WorldObject] = []


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


func tick(delta: float) -> void:
	for wo in world_objects:
		wo.tick(delta, ambient)

	for character in characters:
		character.apply_stress_from_cell(self)
