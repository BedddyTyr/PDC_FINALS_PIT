extends Node

@export var initial_state: CardState

var current_state: CardState
var card: CardUI


func init(card_ui: CardUI) -> void:

	card = card_ui

	for child in get_children():

		if child is CardState:

			child.card_ui = card_ui

			child.transition_requested.connect(
				on_transition_requested
			)

	# START STATE ONLY AFTER REFERENCES EXIST
	if initial_state:
		current_state = initial_state
		current_state.enter()


func on_gui_input(event: InputEvent) -> void:

	if current_state:
		current_state.on_gui_input(event)


func on_input(event: InputEvent) -> void:

	if current_state:
		current_state.on_input(event)


func on_transition_requested(
	from: CardState,
	to: CardState.State
) -> void:

	if from != current_state:
		return

	current_state.exit()

	current_state = get_state(to)

	if current_state:
		current_state.enter()


func get_state(state: CardState.State) -> CardState:

	for child in get_children():

		if child is CardState:

			if child.state == state:
				return child

	return null
