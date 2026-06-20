class_name Grass
extends Ground




@onready var grass_mesh = $Grass

@onready var plane_mesh = $Plane


func _ready() -> void:
	if grass_mesh.material_override != null:
		grass_mesh.material_override = mesh.material_override.duplicate()


## Can be ignored, we set our specific shader
func set_substance(subst: String) -> void:
	pass