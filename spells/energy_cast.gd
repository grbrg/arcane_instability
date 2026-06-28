class_name EnergyCast
extends Cast


func _init() -> void:
	axis = Cast.Axis.ENERGY
	speed = 4.0
	max_dist = 8.0


func resolve(world_simulation: WorldSimulation) -> void:
	var type := _energy_type()
	var adj := StatAdjustment.new()
	adj.source = "player"
	adj.adjustment_type = "value"
	adj.adjustment_value = 1.0
	world_simulation.add_effect(_resolve_cell, type, adj)


func _energy_type() -> String:
	if energy_channel == null:
		return "thermal"
	match energy_channel.channel:
		EnergyChannelModule.Channel.ELECTRICAL: return "electrical"
		EnergyChannelModule.Channel.ARCANE:     return "arcane"
	return "thermal"
