class_name BurningView
extends ConditionView


@onready var _sound: AudioStreamPlayer3D = $Sound


func _ready() -> void:
	_sound.finished.connect(_sound.play)
	_sound.play()
