extends CardState


func enter() -> void:

	# DEPLOYED CARD
	if not card_ui.should_return_to_hand:
		return

	# SAVE CURRENT HAND POSITION
	card_ui.original_global_position = (
		card_ui.global_position
	)

	if not card_ui.is_node_ready():
		await card_ui.ready

	if card_ui.color:
		card_ui.color.color = Color.WEB_GREEN

	if card_ui.state_label:
		card_ui.state_label.text = "BASE"

	card_ui.scale = Vector2.ONE
	card_ui.z_index = 0


func on_mouse_entered() -> void:

	card_ui.scale = Vector2(1.1, 1.1)
	card_ui.z_index = 10


func on_mouse_exited() -> void:

	card_ui.scale = Vector2.ONE
	card_ui.z_index = 0


func on_gui_input(event: InputEvent) -> void:

	if event is InputEventMouseButton:

		if event.button_index == MOUSE_BUTTON_LEFT:

			if event.pressed:

				card_ui.pivot_offset = (
					card_ui.get_global_mouse_position()
					- card_ui.global_position
				)

				transition_requested.emit(
					self,
					CardState.State.DRAGGING
				)
