class_name FaceButtonsPlayerController
extends PlayerController


func handle_joypad_button(event: InputEventJoypadButton) -> void:
	var player := get_parent() as Player
	if event.is_pressed():
		match event.button_index:
			JOY_BUTTON_X: player.request_spell(0)
			JOY_BUTTON_B: player.request_spell(1)
			JOY_BUTTON_Y: player.request_spell(2)
	else:
		match event.button_index:
			JOY_BUTTON_X: player.release_spell(0)
			JOY_BUTTON_B: player.release_spell(1)
			JOY_BUTTON_Y: player.release_spell(2)
