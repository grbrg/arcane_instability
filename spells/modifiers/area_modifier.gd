class_name AreaModifier
extends CastModifier

enum TargetArea { POINT, PROJECTILE, BEAM, AREA }

@export var target_area: TargetArea = TargetArea.POINT
