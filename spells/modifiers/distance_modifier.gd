class_name DistanceModifier
extends CastModifier

enum Distance { AROUND_PLAYER, SHORT, MIDDLE, FAR }

const MAX_DIST: Dictionary = {
	Distance.AROUND_PLAYER: 0.0,
	Distance.SHORT:         2.0,
	Distance.MIDDLE:        5.0,
	Distance.FAR:           10.0,
}

@export var distance: Distance = Distance.SHORT


func get_max_dist() -> float:
	return MAX_DIST[distance]
