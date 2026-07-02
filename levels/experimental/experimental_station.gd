class_name ExperimentalStation
extends Level


var _colors = [Color.DARK_GREEN, Color.INDIAN_RED, Color.SKY_BLUE, Color.DEEP_PINK]

@onready var _nav_region: NavigationRegion3D = $NavigationRegion3D


func _ready() -> void:
	super._ready()

	var i = 0
	for player in players:
		player.set_player_color(_colors[i])
		i += 1



