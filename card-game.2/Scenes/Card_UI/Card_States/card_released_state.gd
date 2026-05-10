extends CardState

var played := false


func enter() -> void:
	card_ui.color.color = Color.DARK_VIOLET
	card_ui.state_label.text = "RELEASED"

	played = false

	# check if card is played
	if card_ui.targets.size() > 0:
		played = true
		print("play card for target(s): ", card_ui.targets)

	# 🔥 CASE 1: PLAYED → do NOT return
	if played:
		return

	# 🔥 CASE 2: NOT PLAYED → return to hand
	if card_ui.should_return_to_hand:
		card_ui.reparent_requested.emit(card_ui)
		# IMPORTANT: force reset state AFTER reparent logic
		transition_requested.emit(self, CardState.State.BASE)
