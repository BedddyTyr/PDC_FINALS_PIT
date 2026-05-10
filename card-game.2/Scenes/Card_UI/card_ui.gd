class_name CardUI
extends Control

@export var card: Card

@onready var color: ColorRect = $Color
@onready var state_label: Label = $State
@onready var drop_point_detector: Area2D = $DropPointDetector
@onready var card_state_machine: CardStateMachine = $CardStateMachine

# 🔥 targets currently hovered / in range
var targets: Array = []

# controls whether card returns to hand
var should_return_to_hand := true


func _ready() -> void:
	card_state_machine.init(self)


func _input(event: InputEvent) -> void:
	card_state_machine.on_input(event)


func _gui_input(event: InputEvent) -> void:
	card_state_machine.on_gui_input(event)


func _on_mouse_entered() -> void:
	card_state_machine.on_mouse_entered()


func _on_mouse_exited() -> void:
	card_state_machine.on_mouse_exited()


func _on_drop_point_detector_area_entered(area: Area2D) -> void:
	if not targets.has(area):
		targets.append(area)


func _on_drop_point_detector_area_exited(area: Area2D) -> void:
	targets.erase(area)
