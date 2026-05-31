class_name WorldSimulation
extends Node3D



const TICK_TIME = 1.0

@export var camera: Camera3D
@export var grid: GridMap


var _cells = {}

var _condition_engine: ConditionEngine

var _ambient: Ambient

var _time_since_tick: float


func _ready() -> void:
	_condition_engine = ConditionEngine.new()
	_ambient = Ambient.new()
	_reset_grid()

	_time_since_tick = 0.0


##
func _reset_grid():
	_cells.clear()
	if grid:
		var cell_indices = grid.get_used_cells()

		# DEBUG substances
		var water = EntitySubstance.new()
		water.heat_capacity = 0.99
		water.heat_conductivity = 0.1
		var copper = EntitySubstance.new()
		copper.heat_capacity = 0.25
		copper.heat_conductivity = 0.9

		# first add all cells
		for cell_index in cell_indices:
			var subst = copper
			if cell_index.x > 0:
				subst = water

			var new_cell = GridCell.new(cell_index, grid, subst)
			new_cell.ambient = _ambient			

			_cells[cell_index] = new_cell
			add_child(new_cell)

		# then connect them
		for cell_index in cell_indices:
			var my_cell = _cells[cell_index]
			for x in [-1 , 1]:
				for z in [-1 , 1]:
					var neighbour = Vector3i(cell_index.x + x, cell_index.y, cell_index.z + z)
					if neighbour in _cells:
						var neighbour_cell = _cells[neighbour]
						my_cell.neighbours.append(neighbour_cell)


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

	# propagate attributes
	# e. g. temperature spreads slowly to neighbours


	# update each condition
	for index in _cells:
		_condition_engine.tick(delta, _cells[index])

	#
