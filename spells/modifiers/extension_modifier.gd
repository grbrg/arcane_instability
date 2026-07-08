class_name ExtensionModifier
extends CastModifier

enum Extension { BOUNCING, PIERCING, EXPLOSION }

const COOLDOWN_ADJUSTMENT: Dictionary = {
	Extension.BOUNCING:   0.5,
	Extension.PIERCING:   1.0,
	Extension.EXPLOSION:  2.0,
}

@export var extension: Extension = Extension.PIERCING


func get_cooldown_adjustment() -> float:
	return COOLDOWN_ADJUSTMENT[extension]
