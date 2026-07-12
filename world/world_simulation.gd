class_name WorldSimulation
extends Node3D



const TICK_TIME = 1.0

@export var camera: Camera3D
@export var grid: GridMap
@export var biome: Biome

var _casts_to_resolve: Array[Cast]

var _cells = {}

var _ambient: Ambient

var _time_since_tick: float

var _characters: Array[Character] = []
var _character_cells: Dictionary = {}  # Character -> Vector3i

var _world_objects: Array[WorldObject] = []
var _world_object_cells: Dictionary = {}  # WorldObject -> Vector3i


func _ready() -> void:
	_ambient = Ambient.new()
	_reset_grid()

	_time_since_tick = 0.0

	call_deferred("_assign_world_objects_to_cells")


##
func _reset_grid():
	_cells.clear()
	if grid:
		var cell_indices = grid.get_used_cells()

		# first add all cells
		for cell_index in cell_indices:
			var new_cell = GridCell.new(cell_index, grid)
			new_cell.ambient = _ambient

			_cells[cell_index] = new_cell
			add_child(new_cell)

		# then connect them
		for cell_index in cell_indices:
			var my_cell = _cells[cell_index]
			_add_neighbour(my_cell, Vector3i(cell_index.x +1, cell_index.y, cell_index.z))
			_add_neighbour(my_cell, Vector3i(cell_index.x -1, cell_index.y, cell_index.z))
			_add_neighbour(my_cell, Vector3i(cell_index.x, cell_index.y, cell_index.z + 1))
			_add_neighbour(my_cell, Vector3i(cell_index.x, cell_index.y, cell_index.z - 1))

		# populate every cell with an AirObject as the ambient medium
		var air_script := preload("res://world/air_object.gd")
		for cell_index in cell_indices:
			var air_obj: WorldObject = air_script.new()
			add_child(air_obj)
			air_obj.global_position = grid.to_global(grid.map_to_local(cell_index))


func _add_neighbour(cell: GridCell, neighbour: Vector3i) -> void:
	if neighbour in _cells:
		var neighbour_cell = _cells[neighbour]
		cell.neighbours.append(neighbour_cell)


## Scan the scene tree for all WorldObject nodes and assign them to their grid cells.
func _assign_world_objects_to_cells() -> void:
	var wos = get_tree().get_nodes_in_group("world_objects")
	for wo in wos:
		if wo is WorldObject:
			register_world_object(wo)
	_update_world_object_cells()


func register_world_object(wo: WorldObject) -> void:
	if wo == null or not is_instance_valid(wo):
		return
	if not wo in _world_objects:
		_world_objects.append(wo)
		wo.tree_exiting.connect(func(): unregister_world_object(wo))


func unregister_world_object(wo: WorldObject) -> void:
	_world_objects.erase(wo)
	var old_index: Vector3i = _world_object_cells.get(wo, Vector3i.MIN)
	if old_index != Vector3i.MIN and old_index in _cells:
		_cells[old_index].remove_world_object(wo)
	_world_object_cells.erase(wo)


func register_character(character: Character) -> void:
	if character == null or not is_instance_valid(character):
		return
	if not character in _characters:
		_characters.append(character)
		character.tree_exiting.connect(func(): unregister_character(character))


func unregister_character(character: Character) -> void:
	_characters.erase(character)
	var old_index: Vector3i = _character_cells.get(character, Vector3i.MIN)
	if old_index != Vector3i.MIN and old_index in _cells:
		_cells[old_index].remove_character(character)
	_character_cells.erase(character)


func _world_to_grid(world_pos: Vector3) -> Vector3i:
	return grid.local_to_map(grid.to_local(world_pos))


##
func _process(delta: float) -> void:
	_update_character_cells()
	_update_world_object_cells()
	_time_since_tick += delta

	if _time_since_tick > TICK_TIME:
		_tick(_time_since_tick)
		_time_since_tick = 0.0


func _update_character_cells() -> void:
	for character in _characters:
		var new_index := _world_to_grid(character.global_position)
		var old_index: Vector3i = _character_cells.get(character, Vector3i.MIN)
		if new_index == old_index:
			continue
		if old_index != Vector3i.MIN and old_index in _cells:
			_cells[old_index].remove_character(character)
		if new_index in _cells:
			_cells[new_index].add_character(character)
		_character_cells[character] = new_index


func _update_world_object_cells() -> void:
	for wo in _world_objects:
		var new_index := _world_to_grid(wo.global_position)
		var old_index: Vector3i = _world_object_cells.get(wo, Vector3i.MIN)
		if new_index == old_index:
			continue
		if old_index != Vector3i.MIN and old_index in _cells:
			_cells[old_index].remove_world_object(wo)
		var new_cell: GridCell = _cells.get(new_index, null)
		if new_cell:
			new_cell.add_world_object(wo)
		wo.set_current_cell(new_cell)
		_world_object_cells[wo] = new_index


func add_cast_to_resolve(cast: Cast) -> void:
	if not cast in _casts_to_resolve:
		_casts_to_resolve.append(cast)


func force_tick() -> void:
	_tick(maxf(_time_since_tick, TICK_TIME))
	_time_since_tick = 0.0


func add_effect(index: Vector3i, type: String, adj: StatAdjustment) -> void:
	if index in _cells:
		var cell = _cells[index]
		if cell:
			cell.add_effect(type, adj)


##
func get_cell(index: Vector3i) -> GridCell:
	if index in _cells:
		return _cells[index]
	return null


##
func get_grid_index(pos: Vector2) -> Vector3i:
	var target = Helper3D.get_object_at(camera, pos)
	if target:
		var grid_index = grid.local_to_map(target.position)
		return grid_index

	return Vector3i.MIN


##
func _tick(delta: float) -> void:
	for cast in _casts_to_resolve:
		cast.resolve(self)
	_casts_to_resolve.clear()

	for index in _cells:
		var cell = _cells[index]
		cell.tick(delta)

	for index in _cells:
		_cells[index].invalidate_property_caches()

	for index in _cells:
		_cells[index].diffuse()
