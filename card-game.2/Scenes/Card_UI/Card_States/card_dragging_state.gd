extends CardState

func enter() -> void:
	var ui_layer := get_tree().get_first_node_in_group("ui_layer")
	if ui_layer:
		card_ui.reparent(ui_layer)

	card_ui.color.color = Color.NAVY_BLUE
	card_ui.state_label.text = "DRAGGING"

	# reset decision each drag
	card_ui.should_return_to_hand = true


func on_input(event: InputEvent) -> void:
	var mouse_motion := event is InputEventMouseMotion
	var cancel := event.is_action_pressed("right_mouse")
	var release := event.is_action_released("left_mouse")

	if mouse_motion:
		card_ui.global_position = card_ui.get_global_mouse_position() - card_ui.pivot_offset

	if cancel:
		card_ui.should_return_to_hand = true
		transition_requested.emit(self, CardState.State.BASE)

	elif release:
		# 🔥 Decide if card should stay or return
		var valid_drop := card_ui.drop_point_detector.get_overlapping_areas().size() > 0

		card_ui.should_return_to_hand = not valid_drop

		get_viewport().set_input_as_handled()
		transition_requested.emit(self, CardState.State.RELEASED)
