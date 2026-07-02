class_name WorldSimulation
extends Node3D



const TICK_TIME = 1.0

@export var camera: Camera3D
@export var grid: GridMap

var _casts_to_resolve: Array[Cast]

var _cells = {}

var _ambient: Ambient

var _time_since_tick: float

var _characters: Array[Character] = []
var _character_cells: Dictionary = {}  # Character -> Vector3i


func _ready() -> void:
	_ambient = Ambient.new()
	_reset_grid()

	_time_since_tick = 0.0


##
func _reset_grid():
	_cells.clear()
	if grid:
		var cell_indices = grid.get_used_cells()

		# first add all cells
		for cell_index in cell_indices:
			var subst = ""
			if cell_index.x > 0:
				subst = "water"
			else:
				if cell_index.z > 0:
					subst = "grass"
				else:
					subst = "kindling"

			var new_cell = GridCell.new(cell_index, grid, subst)
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


func _add_neighbour(cell: GridCell, neighbour: Vector3i) -> void:
	if neighbour in _cells:
		var neighbour_cell = _cells[neighbour]
		cell.neighbours.append(neighbour_cell)

func register_character(character: Character) -> void:
	if not character in _characters:
		_characters.append(character)


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


func add_cast_to_resolve(cast: Cast) -> void:
	if not cast in _casts_to_resolve:
		_casts_to_resolve.append(cast)


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
	# Step 1: resolve spells first
	# Step 2: Update each cell's entities, e. g. temperature slowly goes to down/up
	# 	Step 3: Transfer to neighbours
	# 	Step 4: Check substance reactions
	# 	Step 5: Create new states
	# 	Step 6: Calculate damage
	# 	Step 7: Reduce HP
	# 	Step 8: Decay

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
	

	
