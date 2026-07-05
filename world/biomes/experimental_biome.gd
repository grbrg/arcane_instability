class_name ExperimentalBiome
extends Biome



##
func get_substance(grid_item: int) -> String:
	match grid_item:
		0: return "grass"
		8: return "kindling"
		22: return "water"
	
	return "grass"
