class_name Character
extends CharacterBody3D



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

