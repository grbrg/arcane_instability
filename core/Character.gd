class_name Character
extends CharacterBody3D

const HEALTH_BAR_SCENE = preload("res://ui/health_bar.tscn")

@export_category("Integrity")
@export var max_integrity: float = 100.0
@export var health_bar_offset: Vector3 = Vector3(0.0, 1.2, 0.0)
## Per-axis tolerance/scale this character withstands before taking damage.
## See AxisTolerance (entities/axis_tolerance.gd) — shared with WorldObject.
@export var axis_tolerance: AxisTolerance = AxisTolerance.new()
@export var mass: float = 1.0

var health: HealthComp

var current_cell: GridCell


@export_category("Jump")
@export var jump_height : float = 2.0
@export var jump_time_to_peak : float = 0.4
@export var jump_time_to_descent : float = 0.2
@onready var _jump_velocity : float = ((-2.0 * jump_height) / jump_time_to_peak) * -1.0
@onready var _jump_gravity : float = ((2.0 * jump_height) / (jump_time_to_peak * jump_time_to_peak)) * -1.0
@onready var _fall_gravity : float = ((2.0 * jump_height) / (jump_time_to_descent * jump_time_to_descent)) * -1.0
const JUMP_BUFFER_TIME = 0.1 # time for a jump command before touching the floor
const COYOTE_TIME = 0.25 # time for a jump command after leaving the floor
const MAX_JUMP_COUNT = 2 # double/triple-jumps
var _jump_count = 0
var _jump_buffer_timer: float = 0
var _coyote_timer: float = 0
# falling helpers
var is_falling: bool = false
var was_falling: bool = false
const FALLING_MAX = 9999999.9
var falling_y: float = FALLING_MAX

@onready var mesh: MeshInstance3D = %Main_Mesh
@onready var anim_player: AnimationPlayer = $AnimationPlayer

const ANIM_IDLE := "idle"
const ANIM_RUN := "run"
const ANIM_JUMP := "jump"
const ANIM_CAST := "cast"
const ANIM_DIE := "die"
const DEATH_REMOVE_DELAY := 3.0
const MOVE_ANIM_THRESHOLD := 0.1

var _is_dying: bool = false
var _one_shot_playing: bool = false


func _ready() -> void:
	health = HealthComp.new()
	health.max_integrity = max_integrity
	health.name = "HealthComponent"
	add_child(health)
	health.died.connect(_on_died)

	var bar: HealthBar = HEALTH_BAR_SCENE.instantiate()
	bar.character = self
	bar.position = health_bar_offset
	add_child(bar)


## Axes that stress a character standing in a cell. Excludes structure/conduction: those are
## a world object's own material properties (its hitpoints, its conductivity), not something
## that radiates out to bystanders the way heat, current, arcane charge or pressure do.
const AMBIENT_AXES: Array[String] = ["thermal", "electrical", "arcane", "pressure"]


## Called by the simulation each tick with per-axis energy totals for the cell.
## Damage = each axis's excess above its own tolerance, summed (Step 6+7).
func take_stress(channel_totals: Dictionary) -> void:
	var damage := axis_tolerance.compute_damage(channel_totals)
	if damage > 0:
		health.take_damage(damage)


## Sums each ambient axis across all world objects on the given cell and applies stress,
## checking each axis against its own tolerance instead of tolerancing their combined sum.
func apply_stress_from_cell(cell: GridCell) -> void:
	var channel_totals := {}
	for wo in cell.world_objects:
		var wo_totals := wo.get_axis_totals()
		for key in AMBIENT_AXES:
			if key in wo_totals:
				channel_totals[key] = channel_totals.get(key, 0.0) + wo_totals[key]
	take_stress(channel_totals)


func receive_impulse(impulse: Vector3) -> void:
	var effective := impulse / maxf(mass, 0.1)
	if effective.length_squared() < 0.00001:
		return
	var dir := effective.normalized()
	var current_component := velocity.dot(dir)
	if current_component < effective.length():
		velocity += dir * (effective.length() - current_component)


func apply_gravity(delta):
	velocity.y += get_gravity_force() * delta

	# are we falling?
	if velocity.y > 0:
		self.is_falling = true
		if global_position.y < self.falling_y:
			self.falling_y = global_position.y


func get_gravity_force() -> float:
	return _jump_gravity if velocity.y < 0 else _fall_gravity


##
# Checks whether we can execute a jump and does so
##
func try_jump():
	_jump_buffer_timer = JUMP_BUFFER_TIME
	var has_jumps_left = _jump_count < MAX_JUMP_COUNT
	var is_coyote_jump = _coyote_timer > 0 and has_jumps_left
	if is_on_floor() or is_coyote_jump or has_jumps_left:
		jump()

##
# Executes a jump (no matter the context)
##
func jump():
	velocity.y = _jump_velocity
	_jump_count += 1


## Called when health reaches zero: plays the death animation, then removes
## the character from the scene 3s after the animation finishes.
func _on_died() -> void:
	_is_dying = true
	velocity.x = 0.0
	velocity.z = 0.0
	if anim_player != null and anim_player.has_animation(ANIM_DIE):
		anim_player.play(ANIM_DIE)
		await anim_player.animation_finished
		await get_tree().create_timer(DEATH_REMOVE_DELAY).timeout
	queue_free()


## Plays a one-off animation (e.g. cast) that update_animation() won't
## interrupt with idle/run/jump until it finishes.
func play_one_shot(anim_name: String) -> void:
	if _is_dying or anim_player == null or not anim_player.has_animation(anim_name):
		return
	_one_shot_playing = true
	anim_player.play(anim_name)
	await anim_player.animation_finished
	_one_shot_playing = false


## Drives idle/run/jump based on current physics state. Call once per physics
## frame; does nothing while dying or while a one-shot animation is playing.
func update_animation() -> void:
	if _is_dying or _one_shot_playing:
		return
	var target: String
	if not is_on_floor():
		target = ANIM_JUMP
	elif Vector2(velocity.x, velocity.z).length() > MOVE_ANIM_THRESHOLD:
		target = ANIM_RUN
	else:
		target = ANIM_IDLE
	if anim_player.current_animation != target:
		anim_player.play(target)

