extends CardState


func enter() -> void:

	card_ui.color.color = Color.NAVY_BLUE
	card_ui.state_label.text = "DRAGGING"

	card_ui.should_return_to_hand = true

	card_ui.z_index = 100

	# SAVE POSITION
	card_ui.original_global_position = (
		card_ui.global_position
	)

	var drag_layer = (
		card_ui.get_tree()
		.get_first_node_in_group("drag_layer")
	)

	if drag_layer:

		var current_global_position = (
			card_ui.global_position
		)

		var parent = card_ui.get_parent()

		if parent:
			parent.remove_child(card_ui)

		drag_layer.add_child(card_ui)

		card_ui.mouse_filter = (
			Control.MOUSE_FILTER_STOP
		)

		card_ui.global_position = (
			current_global_position
		)


func on_gui_input(event: InputEvent) -> void:

	# DRAG
	if event is InputEventMouseMotion:

		card_ui.global_position = (
			card_ui.get_global_mouse_position()
			- card_ui.pivot_offset
		)

	# RELEASE
	if event is InputEventMouseButton:

		if event.button_index == MOUSE_BUTTON_LEFT:

			if not event.pressed:

				var overlapping_areas = (
					card_ui.drop_point_detector
					.get_overlapping_areas()
				)

				var valid_drop: bool = false

				for area in overlapping_areas:

					if area.name == "CardDropArea":

						valid_drop = true
						break

				card_ui.should_return_to_hand = (
					not valid_drop
				)

				transition_requested.emit(
					self,
					CardState.State.RELEASED
				)
