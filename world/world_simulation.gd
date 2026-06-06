class_name WorldSimulation
extends Node3D



const TICK_TIME = 1.0

@export var camera: Camera3D
@export var grid: GridMap


var _cells = {}

var _ambient: Ambient

var _time_since_tick: float


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
			var subst = null
			if cell_index.x > 0:
				subst = SubstanceRegistry.get_substance("water")
			else:
				if cell_index.z > 0:
					subst = SubstanceRegistry.get_substance("gras")
				else:
					subst = SubstanceRegistry.get_substance("copper")

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

##
func _process(delta: float) -> void:
	_time_since_tick += delta

	if _time_since_tick > TICK_TIME:
		_tick(_time_since_tick)
		_time_since_tick = 0.0


func add_effect(index: Vector3i, adj: StatAdjustment) -> void:
	if index in _cells:
		var cell = _cells[index]
		if cell:
			cell.add_effect("thermal", adj)


##
func get_grid_index(pos: Vector2) -> Vector3i:
	var target = Helper3D.get_object_at(camera, pos)
	if target:
		var grid_index = grid.local_to_map(target.position)
		return grid_index

	return Vector3i.MIN


##
func _tick(delta: float) -> void:

	# Update each cell's entities
	# e. g. temperature slowly goes to down/up
	for index in _cells:
		var cell = _cells[index]
		cell.tick(delta)
