class_name Player
extends Character

@export var device_id: int = -1
@export var level: Level

# Slot indices match Cast.Axis enum — fixed to shoulder buttons:
# R2=ENERGY, R1=IMPULSE, L2=STRUCTURE, L1=CONDUCTION
const SLOT_ENERGY     = 0
const SLOT_IMPULSE    = 1
const SLOT_STRUCTURE  = 2
const SLOT_CONDUCTION = 3

var _casts: Array[Cast] = []
var _active_cast: Cast = null
var _controller: PlayerController

@onready var _cast_marker: SpellMarker = $SpellMarker
@onready var mesh: MeshInstance3D = $MeshInstance3D


func _ready() -> void:
	super._ready()
	
	_casts.resize(4)
	_assign_cast(SLOT_ENERGY, EnergyCast.new())
	_assign_cast(SLOT_IMPULSE, ImpulseCast.new())
	_assign_cast(SLOT_STRUCTURE, StructureCast.new())
	_assign_cast(SLOT_CONDUCTION, ConductionCast.new())

	_controller = WorldCursorPlayerController.new(self)


func _assign_cast(slot: int, cast: Cast) -> void:
	_casts[slot] = cast
	cast.marker = _cast_marker


func set_player_color(color: Color) -> void:
	if not mesh.material_override:
		mesh.material_override = StandardMaterial3D.new()
	mesh.material_override.albedo_color = color
	_cast_marker.set_color(color)


func set_move_input(dir: Vector3) -> void:
	_controller.set_move_input(dir)


func handle_joypad_button(event: InputEventJoypadButton) -> void:
	_controller.handle_joypad_button(event)


func poll_joypad(joypad_id: int, camera: Camera3D) -> void:
	_controller.poll_joypad(joypad_id, camera)


func request_jump() -> void:
	_controller.request_jump()


func redirect_active_cast(dir: Vector3, magnitude: float = -1.0) -> void:
	if _active_cast != null:
		_active_cast.redirect(dir, magnitude)


func set_cast_marker_position(world_pos: Vector3) -> void:
	_cast_marker.global_position = world_pos
	if _active_cast != null:
		var to := world_pos - global_position
		if to.length() > 0.001:
			_active_cast.redirect(to.normalized(), to.length() / _active_cast.max_dist)
		else:
			_active_cast.redirect(_controller.get_facing_dir(), 0.0)


func set_cast_marker_visible(marker_visible: bool) -> void:
	_cast_marker.visible = marker_visible


func request_cast(slot: int) -> void:
	if _active_cast != null or slot >= _casts.size():
		return
	var cast := _casts[slot]
	if cast != null:
		cast.activate_marker(global_position, _controller.get_facing_dir())
		_active_cast = cast


func release_cast(slot: int) -> void:
	if slot >= _casts.size():
		return
	var cast := _casts[slot]
	if cast != null and cast == _active_cast:
		var grid := level.world_simulation.grid
		var index = grid.local_to_map(grid.to_local(_cast_marker.global_position))
		cast.deactivate_marker(level.world_simulation, index)
		_active_cast = null


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		apply_gravity(delta)
	_controller.physics_process(delta, _active_cast != null)
	_process_casts(delta)


func _process_casts(delta: float) -> void:
	if _active_cast != null:
		_active_cast.process(delta, global_position, _controller.get_facing_dir())
		if not _active_cast.is_active:
			_active_cast = null
