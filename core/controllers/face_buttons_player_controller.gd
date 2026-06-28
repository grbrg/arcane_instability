class_name FaceButtonsPlayerController
extends PlayerController


func handle_joypad_button(event: InputEventJoypadButton) -> void:
	var player := get_parent() as Player
	if event.is_pressed():
		match event.button_index:
			JOY_BUTTON_X: player.request_cast(Player.SLOT_ENERGY)
			JOY_BUTTON_B: player.request_cast(Player.SLOT_IMPULSE)
			JOY_BUTTON_Y: player.request_cast(Player.SLOT_STRUCTURE)
			JOY_BUTTON_A: player.request_cast(Player.SLOT_CONDUCTION)
	else:
		match event.button_index:
			JOY_BUTTON_X: player.release_cast(Player.SLOT_ENERGY)
			JOY_BUTTON_B: player.release_cast(Player.SLOT_IMPULSE)
			JOY_BUTTON_Y: player.release_cast(Player.SLOT_STRUCTURE)
			JOY_BUTTON_A: player.release_cast(Player.SLOT_CONDUCTION)
