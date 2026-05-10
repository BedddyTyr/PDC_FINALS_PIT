extends CardState


func enter() -> void:
	# Make sure card is ready before accessing nodes
	if not card_ui.is_node_ready():
		await card_ui.ready
	
	# Bring card to front (useful for hover/interaction)
	card_ui.reparent_requested.emit(card_ui)
	
	# Visual state
	card_ui.color.color = Color.WEB_GREEN
	card_ui.state_label.text = "BASE"
	
	# Reset pivot (important for scaling/dragging)
	card_ui.pivot_offset = Vector2.ZERO
	
	# Reset transform
	card_ui.scale = Vector2.ONE
	card_ui.z_index = 0


func exit() -> void:
	pass


func on_mouse_entered() -> void:
	if not card_ui:
		return
	
	# Simple hover effect
	card_ui.scale = Vector2(1.1, 1.1)
	card_ui.z_index = 10


func on_mouse_exited() -> void:
	if not card_ui:
		return
	
	# Reset hover effect
	card_ui.scale = Vector2.ONE
	card_ui.z_index = 0


func on_gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("left_mouse"):
		# Set pivot to mouse position for smooth dragging
		card_ui.pivot_offset = card_ui.get_global_mouse_position() - card_ui.global_position
		
		# Transition to CLICKED state
		emit_signal("transition_requested", self, CardState.State.CLICKED)


func on_input(_event: InputEvent) -> void:
	pass
