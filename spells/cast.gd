class_name Cast
extends Node

enum Axis { ENERGY, IMPULSE, STRUCTURE, CONDUCTION }

var axis: Axis = Axis.ENERGY
var energy_channel: EnergyChannelModule = null
var form: FormModule = null
var modifiers: Array[ModifierModule] = []

# One modifier slot per type; subclasses set defaults in _init.
var energy_type_modifier: EnergyTypeModifier = null
var area_modifier: AreaModifier = null
var distance_modifier: DistanceModifier = null
var extension_modifier: ExtensionModifier = null

@export var speed: float = 5.0

var max_dist: float:
	get:
		if distance_modifier != null:
			return distance_modifier.get_max_dist()
		return 10.0

# When false the marker node is never touched; resolve position is
# computed from cast direction × max_dist instead.
var show_marker: bool = true

# When true the marker snaps immediately to max_dist instead of sweeping.
var snap_to_distance: bool = false

var marker: Node3D = null

var is_active: bool:
	get: return _active

var _active: bool = false
var _dist: float = 0.0
var _cast_dir: Vector3 = Vector3.FORWARD
var _manual_dist: bool = false

var _resolve_cell: Vector3i


func activate_marker(origin: Vector3, dir: Vector3) -> void:
	_active = true
	_cast_dir = dir
	_manual_dist = false
	_dist = max_dist if snap_to_distance else 0.0
	if show_marker:
		marker.visible = true
		marker.global_position = origin + _cast_dir * _dist
		marker.rotation.y = atan2(_cast_dir.x, _cast_dir.z)


func deactivate_marker(world_simulation: WorldSimulation, cell_index: Vector3i) -> void:
	if not _active:
		return
	_active = false
	if show_marker:
		marker.visible = false
	_on_cast(world_simulation, cell_index)


func redirect(dir: Vector3, magnitude: float = -1.0) -> void:
	if not _active or dir == Vector3.ZERO:
		return
	_cast_dir = dir
	if magnitude >= 0.0:
		_dist = magnitude * max_dist
		_manual_dist = true


func process(delta: float, origin: Vector3, _dir: Vector3) -> void:
	if not show_marker:
		return
	if snap_to_distance:
		_dist = max_dist
	elif not _manual_dist:
		_dist = minf(_dist + speed * delta, max_dist)
	marker.global_position = origin + _cast_dir * _dist
	marker.rotation.y = atan2(_cast_dir.x, _cast_dir.z)


func _on_cast(world_simulation: WorldSimulation, cell_index: Vector3i) -> void:
	_resolve_cell = cell_index
	world_simulation.add_cast_to_resolve(self)


## Override in subclasses to define the cast effect.
func resolve(_world_simulation: WorldSimulation) -> void:
	pass
