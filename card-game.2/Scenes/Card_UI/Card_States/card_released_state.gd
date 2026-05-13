extends CardState


func enter() -> void:

	card_ui.color.color = Color.DARK_ORANGE
	card_ui.state_label.text = "RELEASED"

	# INVALID DROP
	if card_ui.should_return_to_hand:

		var hand = (
			card_ui.get_tree()
			.get_first_node_in_group("hand")
		)

		if hand:

			# REMOVE FROM CURRENT PARENT
			if card_ui.get_parent():
				card_ui.get_parent().remove_child(card_ui)

			# RETURN TO HAND CONTAINER
			hand.add_child(card_ui)

			# RESET UI TRANSFORM
			card_ui.scale = Vector2.ONE
			card_ui.rotation = 0

	# VALID DROP
	else:

		card_ui.original_global_position = (
			card_ui.global_position
		)

	card_ui.scale = Vector2.ONE
	card_ui.z_index = 0

	await get_tree().process_frame

	transition_requested.emit(
		self,
		CardState.State.BASE
	)
