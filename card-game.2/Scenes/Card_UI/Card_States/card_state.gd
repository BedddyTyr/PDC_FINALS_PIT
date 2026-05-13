extends Node
class_name CardState

signal transition_requested(from, to)

enum State {
	BASE,
	CLICKED,
	DRAGGING,
	RELEASED
}

@export var state: State

var card_ui: CardUI


func enter() -> void:
	pass


func exit() -> void:
	pass


func on_input(_event: InputEvent) -> void:
	pass


func on_gui_input(_event: InputEvent) -> void:
	pass


func on_mouse_entered() -> void:
	pass


func on_mouse_exited() -> void:
	pass
