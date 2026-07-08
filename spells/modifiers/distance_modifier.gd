class_name DistanceModifier
extends CastModifier

enum Distance { AROUND_PLAYER, SHORT, MIDDLE, FAR }

const MAX_DIST: Dictionary = {
	Distance.AROUND_PLAYER: 0.0,
	Distance.SHORT:         2.0,
	Distance.MIDDLE:        4.0,
	Distance.FAR:           8.0,
}

const COOLDOWN_ADJUSTMENT: Dictionary = {
	Distance.AROUND_PLAYER: 2.0,
	Distance.SHORT:         2.5,
	Distance.MIDDLE:        3.0,
	Distance.FAR:           3.5,
}

@export var distance: Distance = Distance.SHORT


func get_max_dist() -> float:
	return MAX_DIST[distance]


func get_cooldown_adjustment() -> float:
	return COOLDOWN_ADJUSTMENT[distance]
