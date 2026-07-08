class_name AreaModifier
extends CastModifier

enum TargetArea { POINT, PROJECTILE, BEAM, AREA }

const COOLDOWN_ADJUSTMENT: Dictionary = {
	TargetArea.POINT:      0.0,
	TargetArea.PROJECTILE: 0.5,
	TargetArea.BEAM:       1.0,
	TargetArea.AREA:       2.0,
}

@export var target_area: TargetArea = TargetArea.POINT


func get_cooldown_adjustment() -> float:
	return COOLDOWN_ADJUSTMENT[target_area]
