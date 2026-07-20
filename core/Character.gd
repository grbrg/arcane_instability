class_name Character
extends CharacterBody3D

const HEALTH_BAR_SCENE = preload("res://ui/health_bar.tscn")

@export_category("Integrity")
@export var max_integrity: float = 100.0
@export var health_bar_offset: Vector3 = Vector3(0.0, 1.2, 0.0)
## Total energy (across all channels) a character can withstand before taking damage.
@export var energy_tolerance: float = 0.5
## Pressure a character can withstand before taking damage.
@export var pressure_tolerance: float = 2.0
## Multiplier applied to excess energy/impulse before dealing damage.
@export var damage_scale: float = 20.0
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



func _ready() -> void:
	health = HealthComp.new()
	health.max_integrity = max_integrity
	health.name = "HealthComponent"
	add_child(health)

	var bar: HealthBar = HEALTH_BAR_SCENE.instantiate()
	bar.character = self
	bar.position = health_bar_offset
	add_child(bar)


## Called by the simulation each tick with current entity state totals.
## Damage = excess above tolerance, matching the system simulation loop (Step 6+7).
func take_stress(total_energy: float, pressure: float) -> void:
	var damage := (maxf(0.0, total_energy - energy_tolerance) + maxf(0.0, pressure - pressure_tolerance)) * damage_scale
	if damage > 0:
		health.take_damage(damage)


## Sums all energy channels across all world objects on the given cell and applies stress.
func apply_stress_from_cell(cell: GridCell) -> void:
	var energy_sum := 0.0
	var pressure := 0.0
	for wo in cell.world_objects:
		energy_sum += wo.get_positive_energy_sum()
		var pressure_prop = wo.entity.get_property("pressure")
		if pressure_prop:
			pressure += pressure_prop.get_value()
	take_stress(energy_sum, pressure)


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
	#state = "jump"

	if is_on_floor():
		#self.sprite.play("jump")
		pass
	else:
		#self.sprite.play("double_jump")
		pass

