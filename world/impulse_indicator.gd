class_name ImpulseIndicator
extends Node3D

const SHOW_THRESHOLD := 0.05

var _particles: GPUParticles3D
var _process_mat: ParticleProcessMaterial


func _ready() -> void:
	_process_mat = ParticleProcessMaterial.new()
	_process_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	_process_mat.emission_box_extents = Vector3(0.5, 0.125, 0.5)
	_process_mat.direction = Vector3(0.0, 0.0, 1.0)
	_process_mat.spread = 18.0
	_process_mat.initial_velocity_min = 0.4
	_process_mat.initial_velocity_max = 1.2
	_process_mat.gravity = Vector3.ZERO
	_process_mat.scale_min = 0.008
	_process_mat.scale_max = 0.022
	_process_mat.color = Color(0.75, 0.9, 1.0, 0.15)

	var mesh_mat := StandardMaterial3D.new()
	mesh_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh_mat.vertex_color_use_as_albedo = true
	mesh_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED

	var quad := QuadMesh.new()
	quad.size = Vector2(0.03, 0.03)
	quad.material = mesh_mat

	_particles = GPUParticles3D.new()
	_particles.process_material = _process_mat
	_particles.draw_pass_1 = quad
	_particles.amount = 180
	_particles.lifetime = 0.8
	_particles.emitting = false
	add_child(_particles)

var _emitting := false

func update(impulse: Vector3) -> void:
	var strength := impulse.length()
	var should_emit := strength >= SHOW_THRESHOLD
	if should_emit != _emitting:
		_particles.emitting = should_emit
		_emitting = should_emit
	if should_emit:
		rotation.y = atan2(impulse.x, impulse.z)
		_process_mat.initial_velocity_max = clampf(strength * 0.8, 0.2, 2.0)
