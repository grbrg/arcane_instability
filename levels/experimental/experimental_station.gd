class_name ExperimentalStation
extends Level


@onready var _nav_region: NavigationRegion3D = $NavigationRegion3D
@onready var _hud: VersusHUD = $VersusHUD


func _ready() -> void:
	_hud.setup(player_spawner, enemy_spawner)
	super._ready()




