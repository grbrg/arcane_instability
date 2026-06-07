class_name Player
extends Character

@export var move_speed: float = 5.0
@export var acceleration: float = 15.0

const SPELL_ACTIONS := ["spell1", "spell2", "spell3"]

var _move_dir: Vector3 = Vector3.ZERO
var _last_move_dir: Vector3 = Vector3.FORWARD
var _jump_requested: bool = false
var _spells: Array[Spell] = []
var _active_spell: Spell = null

@onready var _spell_marker: Node3D = $SpellMarker


func _ready() -> void:
	_spells.resize(SPELL_ACTIONS.size())
	assign_spell(0, ThermalBloom.new())


func assign_spell(slot: int, spell: Spell) -> void:
	_spells[slot] = spell
	spell.action = SPELL_ACTIONS[slot]
	spell.marker = _spell_marker


func set_move_input(dir: Vector3) -> void:
	_move_dir = dir
	if dir != Vector3.ZERO:
		_last_move_dir = dir.normalized()


func request_jump() -> void:
	_jump_requested = true


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
	if _active_spell == null:
		for spell in _spells:
			if spell != null and spell.try_activate(global_position, _last_move_dir):
				_active_spell = spell
				break

	if _active_spell != null:
		_active_spell.process(delta, global_position, _last_move_dir)
		if not _active_spell.is_active:
			_active_spell = null
