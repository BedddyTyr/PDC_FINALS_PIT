extends CardState

func enter() -> void:
	card_ui.color.color = Color.ORANGE
	card_ui.state_label.text = "CLICKED"  # ✅ FIXED
	card_ui.drop_point_detector.monitoring = true

func on_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		emit_signal("transition_requested", self, CardState.State.DRAGGING)
