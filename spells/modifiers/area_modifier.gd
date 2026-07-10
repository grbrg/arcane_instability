class_name AreaModifier
extends CastModifier

enum TargetArea { POINT, PROJECTILE, BEAM, AREA }

const COOLDOWN_ADJUSTMENT: Dictionary = {
	TargetArea.POINT:      0.0,
	TargetArea.PROJECTILE: 1.0,
	TargetArea.BEAM:       2.0,
	TargetArea.AREA:       2.5,
}

@export var target_area: TargetArea = TargetArea.POINT


func get_cooldown_adjustment() -> float:
	return COOLDOWN_ADJUSTMENT[target_area]
