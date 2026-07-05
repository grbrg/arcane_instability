class_name FaceButtonsPlayerController
extends PlayerController


func handle_joypad_button(event: InputEventJoypadButton) -> void:
	if event.is_pressed():
		match event.button_index:
			JOY_BUTTON_X: _player.request_cast(Player.SLOT_ENERGY)
			JOY_BUTTON_B: _player.request_cast(Player.SLOT_IMPULSE)
			JOY_BUTTON_Y: _player.request_cast(Player.SLOT_STRUCTURE)
			JOY_BUTTON_A: _player.request_cast(Player.SLOT_CONDUCTION)
	else:
		match event.button_index:
			JOY_BUTTON_X: _player.release_cast(Player.SLOT_ENERGY)
			JOY_BUTTON_B: _player.release_cast(Player.SLOT_IMPULSE)
			JOY_BUTTON_Y: _player.release_cast(Player.SLOT_STRUCTURE)
			JOY_BUTTON_A: _player.release_cast(Player.SLOT_CONDUCTION)
