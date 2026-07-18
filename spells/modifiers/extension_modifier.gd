class_name ExtensionModifier
extends CastModifier

enum Extension { NONE, BOUNCING, INVERT, EXPLOSION }

const COOLDOWN_ADJUSTMENT: Dictionary = {
	Extension.NONE:		  0.0,
	Extension.BOUNCING:   0.0,
	Extension.INVERT:   0.0,
	Extension.EXPLOSION:  3.0,
}

@export var extension: Extension = Extension.NONE


func get_cooldown_adjustment() -> float:
	return COOLDOWN_ADJUSTMENT[extension]
