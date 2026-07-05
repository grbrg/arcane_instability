class_name EnergyTypeModifier
extends CastModifier

enum Type { THERMAL, ELECTRICAL, ARCANE }

@export var type: Type = Type.THERMAL


func get_energy_type() -> String:
	match type:
		Type.ELECTRICAL: return "electrical"
		Type.ARCANE:     return "arcane"
	return "thermal"
