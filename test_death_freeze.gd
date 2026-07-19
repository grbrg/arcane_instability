extends Node3D

var _t: float = 0.0
var _damaged := false
var _level: Node3D

func _ready() -> void:
	var scene: PackedScene = load("res://levels/experimental/experimental_station.tscn")
	_level = scene.instantiate()
	add_child(_level)

func _process(delta: float) -> void:
	_t += delta
	print("heartbeat t=%.2f" % _t)
	if _t > 1.5 and not _damaged:
		_damaged = true
		for p in _level.find_children("*", "Player", true, false):
			print("found player, dealing lethal damage")
			p.health.take_damage(99999)
	if _t > 8.0:
		print("TEST DONE - no freeze")
		get_tree().quit()
