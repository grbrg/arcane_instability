class_name ExtensionModifier
extends CastModifier

enum Extension { BOUNCING, PIERCING, EXPLOSION }

const COOLDOWN_ADJUSTMENT: Dictionary = {
	Extension.BOUNCING:   0.0,
	Extension.PIERCING:   0.0,
	Extension.EXPLOSION:  0.0,
}

@export var extension: Extension = Extension.PIERCING


func get_cooldown_adjustment() -> float:
	return COOLDOWN_ADJUSTMENT[extension]
