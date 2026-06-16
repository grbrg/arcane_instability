class_name Player
extends Character

@export var device_id: int = -1
@export var level: Level

var _spells: Array[Spell] = []
var _active_spell: Spell = null
var _controller: PlayerController

@onready var _spell_marker: SpellMarker = $SpellMarker
@onready var mesh: MeshInstance3D = $MeshInstance3D




func _ready() -> void:
	_spells.resize(3)
	assign_spell(0, ThermalBloom.new())

	_controller = WorldCursorPlayerController.new(self)


func assign_spell(slot: int, spell: Spell) -> void:
	_spells[slot] = spell
	spell.marker = _spell_marker


func set_player_color(color: Color) -> void:
	if not mesh.material_override:
		mesh.material_override = StandardMaterial3D.new()
	mesh.material_override.albedo_color = color
	_spell_marker.set_color(color)


func set_move_input(dir: Vector3) -> void:
	_controller.set_move_input(dir)


func handle_joypad_button(event: InputEventJoypadButton) -> void:
	_controller.handle_joypad_button(event)


func poll_joypad(joypad_id: int, camera: Camera3D) -> void:
	_controller.poll_joypad(joypad_id, camera)


func request_jump() -> void:
	_controller.request_jump()


func redirect_active_spell(dir: Vector3, magnitude: float = -1.0) -> void:
	if _active_spell != null:
		_active_spell.redirect(dir, magnitude)


func set_spell_marker_position(world_pos: Vector3) -> void:
	_spell_marker.global_position = world_pos
	if _active_spell != null:
		var to := world_pos - global_position
		if to.length() > 0.001:
			_active_spell.redirect(to.normalized(), to.length() / _active_spell.max_dist)
		else:
			_active_spell.redirect(_controller.get_facing_dir(), 0.0)


func set_spell_marker_visible(marker_visible: bool) -> void:
	_spell_marker.visible = marker_visible


func request_spell(slot: int) -> void:
	if _active_spell != null or slot >= _spells.size():
		return
	var spell := _spells[slot]
	if spell != null:
		spell.activate_marker(global_position, _controller.get_facing_dir())
		_active_spell = spell


func release_spell(slot: int) -> void:
	if slot >= _spells.size():
		return
	var spell := _spells[slot]
	if spell != null and spell == _active_spell:
		var grid := level.world_simulation.grid
		var index = grid.local_to_map(grid.to_local(_spell_marker.global_position))
		spell.deactivate_marker(level.world_simulation, index)
		_active_spell = null


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		apply_gravity(delta)
	_controller.physics_process(delta, _active_spell != null)
	_process_spells(delta)


func _process_spells(delta: float) -> void:
	if _active_spell != null:
		_active_spell.process(delta, global_position, _controller.get_facing_dir())
		if not _active_spell.is_active:
			_active_spell = null
