class_name Enemy
extends Character


@export_category("Detection")
@export var detection_radius: float = 8.0
@export var attack_range: float = 2.0

@export_category("Combat")
@export var attack_duration: float = 0.8
@export var attack_cooldown_duration: float = 2.0

@export_category("Movement")
@export var move_speed: float = 3.0
@export var wander_radius: float = 5.0

var origin_position: Vector3
var target_player: Character = null

var can_attack: bool = true
var attack_cooldown_timer: float = 0.0

var idle_state: EnemyIdleState
var following_state: EnemyFollowingState
var attacking_state: EnemyAttackingState
var recovering_state: EnemyRecoveringState
var wandering_state: EnemyWanderingState

var _state_machine: StateMachine

# Required scene nodes: NavigationAgent3D named "NavigationAgent3D"
#                       Area3D named "DetectionArea" (collision_mask = Player layer)
#                         └── CollisionShape3D with SphereShape3D (radius = detection_radius)
@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var _detection_area: Area3D = $DetectionArea


func _ready() -> void:
	super()
	origin_position = global_position
	_setup_state_machine()
	_detection_area.body_entered.connect(_on_body_entered)
	_detection_area.body_exited.connect(_on_body_exited)


func _setup_state_machine() -> void:
	_state_machine = StateMachine.new()
	_state_machine.name = "StateMachine"
	add_child(_state_machine)

	idle_state = EnemyIdleState.new(self)
	following_state = EnemyFollowingState.new(self)
	attacking_state = EnemyAttackingState.new(self)
	recovering_state = EnemyRecoveringState.new(self)
	wandering_state = EnemyWanderingState.new(self)

	_state_machine.add_child(idle_state)
	_state_machine.add_child(wandering_state)
	_state_machine.add_child(following_state)
	_state_machine.add_child(attacking_state)
	_state_machine.add_child(recovering_state)
	_state_machine.init()


func change_state(new_state: EnemyState) -> void:
	_state_machine.change_to_state(new_state)


## Move toward target_pos using NavigationAgent3D. Sets velocity.x/z only;
## velocity.y is managed by gravity in _physics_process.
func navigate_toward(target_pos: Vector3) -> void:
	nav_agent.target_position = target_pos
	var next_pos := nav_agent.get_next_path_position()
	var dir := next_pos - global_position
	dir.y = 0.0
	if dir.length_squared() < 0.0001:
		velocity.x = 0.0
		velocity.z = 0.0
		return
	dir = dir.normalized()
	velocity.x = dir.x * move_speed
	velocity.z = dir.z * move_speed


func distance_to_player() -> float:
	if target_player == null:
		return INF
	return global_position.distance_to(target_player.global_position)


## Override in subclasses to trigger attack visuals/logic.
func begin_attack() -> void:
	pass


## Override in subclasses to stop attack visuals/logic.
func end_attack() -> void:
	pass


func _on_body_entered(body: Node3D) -> void:
	if body is Character and not body is Enemy and target_player == null:
		target_player = body as Character
		change_state(following_state)


func _on_body_exited(body: Node3D) -> void:
	if body != target_player:
		return
	target_player = null
	# Check if another player is still inside the detection area.
	for b in _detection_area.get_overlapping_bodies():
		if b is Character and not b is Enemy:
			target_player = b as Character
			change_state(following_state)
			return
	change_state(idle_state)


func _physics_process(delta: float) -> void:
	if not can_attack:
		attack_cooldown_timer -= delta
		if attack_cooldown_timer <= 0.0:
			can_attack = true

	if not is_on_floor():
		apply_gravity(delta)

	move_and_slide()
