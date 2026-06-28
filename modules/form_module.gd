class_name FormModule
extends Module

enum Form { BEAM, PROJECTILE, AURA, MINE, CONE }

@export var form: Form = Form.PROJECTILE
@export var speed: float = 5.0
@export var max_dist: float = 10.0
