class_name CardStateMachine
extends Node

@export var initial_state: CardState

var current_state: CardState
var states := {}


func init(card: CardUI) -> void:
	print("=== INIT STATE MACHINE ===")

	# Register all child states
	for child in get_children():
		print("Found child:", child)

		if child is CardState:
			print("Registered state:", child, " | Enum:", child.state)

			states[child.state] = child
			child.transition_requested.connect(_on_transition_requested)
			child.card_ui = card

	# Debug: show all registered states
	print("All states:", states)

	# Set initial state
	if initial_state:
		current_state = initial_state
		print("Using initial state:", current_state)
		current_state.enter()
	else:
		# Fallback if not set in inspector
		if states.size() > 0:
			current_state = states.values()[0]
			print("Fallback state:", current_state)
			current_state.enter()
		else:
			print("ERROR: No states found!")


func _process(delta: float) -> void:
	if current_state and current_state.has_method("on_process"):
		current_state.on_process(delta)


func on_input(event: InputEvent) -> void:
	if current_state:
		current_state.on_input(event)


func on_gui_input(event: InputEvent) -> void:
	if current_state:
		current_state.on_gui_input(event)


func on_mouse_entered() -> void:
	if current_state:
		current_state.on_mouse_entered()


func on_mouse_exited() -> void:
	if current_state:
		current_state.on_mouse_exited()


func _on_transition_requested(from: CardState, to: CardState.State) -> void:
	print("Transition requested:", from, "→", to)

	if from != current_state:
		print("Ignored: not current state")
		return

	var new_state: CardState = states.get(to)

	if not new_state:
		print("ERROR: State not found for:", to)
		return

	print("Switching to:", new_state)

	current_state.exit()
	current_state = new_state
	current_state.enter()
