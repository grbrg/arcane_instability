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
@export var strength: float = 1.0

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
var _cooldown_remaining: float = 0.0

var is_on_cooldown: bool:
	get: return _cooldown_remaining > 0.0

var cooldown_fraction: float:
	get:
		var total := cooldown
		if total <= 0.0:
			return 0.0
		return minf(_cooldown_remaining / total, 1.0)

var cooldown: float:
	get:
		var total := 0.5
		for m in [energy_type_modifier, area_modifier, distance_modifier, extension_modifier]:
			if m != null:
				total += m.get_cooldown_adjustment()
		return max(0, total)

var _resolve_cell: Vector3i

var resolve_cell: Vector3i:
	get: return _resolve_cell


func activate_marker(origin: Vector3, dir: Vector3) -> void:
	_active = true
	_cast_dir = dir
	_manual_dist = false
	_dist = max_dist if snap_to_distance else 0.0
	if show_marker:
		marker.visible = true
		marker.global_position = origin + _cast_dir * _dist
		marker.rotation.y = atan2(_cast_dir.x, _cast_dir.z)


func deactivate_marker(_world_simulation: WorldSimulation, cell_index: Vector3i) -> void:
	if not _active:
		return
	_active = false
	if show_marker:
		marker.visible = false
	_resolve_cell = cell_index
	_cooldown_remaining = cooldown


func redirect(dir: Vector3, magnitude: float = -1.0) -> void:
	if not _active or dir == Vector3.ZERO:
		return
	_cast_dir = dir
	if magnitude >= 0.0:
		_dist = magnitude * max_dist
		_manual_dist = true


func process(delta: float, origin: Vector3, _dir: Vector3) -> void:
	if _cooldown_remaining > 0.0:
		_cooldown_remaining = maxf(_cooldown_remaining - delta, 0.0)
	if not show_marker or not _active:
		return
	if snap_to_distance:
		_dist = max_dist
	elif not _manual_dist:
		_dist = minf(_dist + speed * delta, max_dist)
	marker.global_position = origin + _cast_dir * _dist
	marker.rotation.y = atan2(_cast_dir.x, _cast_dir.z)


## Override in subclasses to apply the cast effect to a specific cell at a given strength.
func apply_to_cell(_world_simulation: WorldSimulation, _cell: Vector3i, _strength: float) -> void:
	pass


func resolve(world_simulation: WorldSimulation) -> void:
	apply_to_cell(world_simulation, _resolve_cell, strength)
	if area_modifier != null and area_modifier.target_area == AreaModifier.TargetArea.AREA:
		var cell := world_simulation.get_cell(_resolve_cell)
		if cell != null:
			for neighbour in cell.neighbours:
				apply_to_cell(world_simulation, neighbour.index, strength)
