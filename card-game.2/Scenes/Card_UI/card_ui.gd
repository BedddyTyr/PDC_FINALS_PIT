extends Control
class_name CardUI

signal reparent_requested(which_card_ui)

@onready var color: ColorRect = $Color
@onready var state_label: Label = $StateLabel
@onready var state_machine = $CardStateMachine
@onready var drop_point_detector: Area2D = $DropPointDetector

var original_global_position: Vector2
var should_return_to_hand: bool = true


func _ready() -> void:

	mouse_filter = Control.MOUSE_FILTER_STOP

	# Wait one frame so hand container finishes layout
	await get_tree().process_frame

	original_global_position = global_position

	state_machine.init(self)


func _gui_input(event: InputEvent) -> void:
	state_machine.on_gui_input(event)


func _unhandled_input(event: InputEvent) -> void:
	state_machine.on_input(event)


func return_to_original_position() -> void:

	var tween = create_tween()

	tween.tween_property(
		self,
		"global_position",
		original_global_position,
		0.2
	)
