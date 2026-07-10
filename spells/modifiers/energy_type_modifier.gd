class_name EnergyTypeModifier
extends CastModifier

enum Type { THERMAL, ELECTRICAL, ARCANE }

const COOLDOWN_ADJUSTMENT: Dictionary = {
	Type.THERMAL:     0.0,
	Type.ELECTRICAL:  0.0,
	Type.ARCANE:      0.0,
}

@export var type: Type = Type.THERMAL


func get_cooldown_adjustment() -> float:
	return COOLDOWN_ADJUSTMENT[type]


func get_energy_type() -> String:
	match type:
		Type.ELECTRICAL: return "electrical"
		Type.ARCANE:     return "arcane"
	return "thermal"
