class_name Player
extends Character

@export var move_speed: float = 5.0
@export var acceleration: float = 15.0
@export var device_id: int = -1
@export var level: Level

var _move_dir: Vector3 = Vector3.ZERO
var _last_move_dir: Vector3 = Vector3.FORWARD
var _jump_requested: bool = false
var _spells: Array[Spell] = []
var _active_spell: Spell = null

@onready var _spell_marker: Node3D = $SpellMarker


func _ready() -> void:
	_spells.resize(3)
	assign_spell(0, ThermalBloom.new())


func assign_spell(slot: int, spell: Spell) -> void:
	_spells[slot] = spell
	spell.marker = _spell_marker


func set_move_input(dir: Vector3) -> void:
	_move_dir = dir
	if dir != Vector3.ZERO:
		_last_move_dir = dir.normalized()


func request_jump() -> void:
	_jump_requested = true


func request_spell(slot: int) -> void:
	if _active_spell != null or slot >= _spells.size():
		return
	var spell := _spells[slot]
	if spell != null:
		spell.activate_marker(global_position, _last_move_dir)
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

	if _jump_requested and is_on_floor():
		try_jump()
	_jump_requested = false

	var target := _move_dir * move_speed
	velocity.x = move_toward(velocity.x, target.x, acceleration * delta)
	velocity.z = move_toward(velocity.z, target.z, acceleration * delta)

	move_and_slide()

	_process_spells(delta)


func _process_spells(delta: float) -> void:
	if _active_spell != null:
		_active_spell.process(delta, global_position, _last_move_dir)
		if not _active_spell.is_active:
			_active_spell = null
