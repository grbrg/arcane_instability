class_name FaceButtonsPlayerController
extends PlayerController


func uses_cast_marker() -> bool:
	return false


func snaps_cast_to_distance() -> bool:
	return true


func handle_joypad_button(event: InputEventJoypadButton) -> void:
	if event.is_pressed():
		match event.button_index:
			JOY_BUTTON_X: _player.request_cast(Player.SLOT_ENERGY)
			JOY_BUTTON_B: _player.request_cast(Player.SLOT_PRESSURE)
			JOY_BUTTON_Y: _player.request_cast(Player.SLOT_STRUCTURE)
			JOY_BUTTON_A: _player.request_cast(Player.SLOT_CONDUCTION)
	else:
		match event.button_index:
			JOY_BUTTON_X: _player.release_cast(Player.SLOT_ENERGY)
			JOY_BUTTON_B: _player.release_cast(Player.SLOT_PRESSURE)
			JOY_BUTTON_Y: _player.release_cast(Player.SLOT_STRUCTURE)
			JOY_BUTTON_A: _player.release_cast(Player.SLOT_CONDUCTION)
