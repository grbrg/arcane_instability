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




##
#
##
func _process(delta):
	if len(follow_targets) > 0:
		var centroid = Vector3.ZERO
		for target in follow_targets:
			centroid += target.global_position
		centroid /= len(follow_targets)

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
