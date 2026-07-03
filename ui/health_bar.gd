class_name HealthBar
extends Node3D

@export var bar_color: Color = Color(0.2, 0.8, 0.2):
	set(value):
		bar_color = value
		if _fill_material:
			_fill_material.albedo_color = value

@export var background_color: Color = Color(0.15, 0.15, 0.15, 0.8)
@export var bar_width: float = 0.75
@export var bar_height: float = 0.1
@export var character: Character:
	set(value):
		_disconnect_health()
		character = value
		if is_node_ready():
			_connect_health()

var _fill_material: StandardMaterial3D
var _fill_mesh: MeshInstance3D


func _ready() -> void:
	_setup_visuals()
	_connect_health()


func _process(_delta: float) -> void:
	var camera := get_viewport().get_camera_3d()
	if not camera:
		return
	var away := global_position - camera.global_position
	if away.length_squared() < 0.0001:
		return
	var up := Vector3.UP if abs(away.normalized().dot(Vector3.UP)) < 0.999 else Vector3.FORWARD
	look_at(global_position + away, up)


func _setup_visuals() -> void:
	var bg := MeshInstance3D.new()
	var bg_quad := QuadMesh.new()
	bg_quad.size = Vector2(bar_width, bar_height)
	bg.mesh = bg_quad
	var bg_mat := StandardMaterial3D.new()
	bg_mat.albedo_color = background_color
	bg_mat.no_depth_test = true
	bg_mat.flags_transparent = true
	bg_mat.render_priority = 1
	bg.material_override = bg_mat
	add_child(bg)

	_fill_mesh = MeshInstance3D.new()
	var fill_quad := QuadMesh.new()
	fill_quad.size = Vector2(bar_width, bar_height)
	_fill_mesh.mesh = fill_quad
	_fill_material = StandardMaterial3D.new()
	_fill_material.albedo_color = bar_color
	_fill_material.no_depth_test = true
	_fill_material.flags_transparent = true
	_fill_material.render_priority = 2
	_fill_mesh.material_override = _fill_material
	add_child(_fill_mesh)

	_update_fill(1.0)


func _connect_health() -> void:
	if not character:
		return
	if not character.health:
		character.ready.connect(_connect_health, CONNECT_ONE_SHOT)
		return
	character.health.integrity_changed.connect(_on_integrity_changed)
	_update_fill(character.health.integrity / character.health.max_integrity)


func _disconnect_health() -> void:
	if character and character.health:
		if character.health.integrity_changed.is_connected(_on_integrity_changed):
			character.health.integrity_changed.disconnect(_on_integrity_changed)


func _on_integrity_changed(current: float, maximum: float) -> void:
	_update_fill(current / maximum if maximum > 0.0 else 0.0)


func _update_fill(ratio: float) -> void:
	if not _fill_mesh:
		return
	_fill_mesh.visible = ratio > 0.0
	var fill_quad := _fill_mesh.mesh as QuadMesh
	fill_quad.size.x = bar_width * ratio
	_fill_mesh.position.x = (ratio - 1.0) * bar_width * 0.5
