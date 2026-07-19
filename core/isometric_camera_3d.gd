class_name IsometricCamera3D
extends Camera3D



@export var min_height: float
@export var max_height: float
@export var zoom_speed = 2.0
@export var move_speed = 20
@export var follow_targets: Array[Player]

# offset of the camera, if following a specific node
const _follow_target_offset: Vector3 = Vector3(0, 20, -10)

var _velocity: Vector3

# last known position of a player removed from follow_targets (e.g. on death),
# keyed by device_id, so the viewport doesn't jump when they're removed
var _last_known_positions: Dictionary = {}


func remove_follow_target(player: Player) -> void:
	follow_targets.erase(player)
	_last_known_positions[player.device_id] = player.global_position


func add_follow_target(player: Player) -> void:
	follow_targets.append(player)
	_last_known_positions.erase(player.device_id)


##
#
##
func _process(delta):
	var anchors: Array[Vector3] = []
	for target in follow_targets:
		anchors.append(target.global_position)
	for pos in _last_known_positions.values():
		anchors.append(pos)

	if len(anchors) > 0:
		var centroid = Vector3.ZERO
		for pos in anchors:
			centroid += pos
		centroid /= len(anchors)

		# Step backward along the camera's forward ray so centroid lands at
		# the center of the viewport, keeping the camera _follow_target_offset.y
		# units above the centroid regardless of the camera's yaw/pitch.
		var cam_fwd := -global_basis.z
		if abs(cam_fwd.y) > 0.001:
			var t := -_follow_target_offset.y / cam_fwd.y
			global_position = centroid - t * cam_fwd
		else:
			global_position = centroid + _follow_target_offset
	
	else:
		# dampen any scrolling we might have
		_velocity = _velocity.lerp(Vector3.ZERO, delta * 20)

		var dir = Vector3.ZERO
		if Input.is_action_pressed("camera_down"):
			dir.z += move_speed
		elif Input.is_action_pressed("camera_up"):
			dir.z -= move_speed
		elif Input.is_action_pressed("camera_right"):
			dir.x += move_speed
		elif Input.is_action_pressed("camera_left"):
			dir.x -= move_speed
		
		dir = dir.rotated(Vector3(0, 1, 0), global_rotation.y)	
		_velocity += (dir.normalized() * move_speed)
		
		global_position += _velocity * delta
