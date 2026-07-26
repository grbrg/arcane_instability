extends Node

const THEME := preload("res://music/arcane_instability_theme.mp3")

@onready var _player := AudioStreamPlayer.new()


func _ready() -> void:
	add_child(_player)
	_player.stream = THEME
	_player.finished.connect(_player.play)
	_player.play()
