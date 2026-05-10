class_name Hand
extends HBoxContainer

func _ready() -> void:
	for child in get_children():
		var card_ui := child as CardUI
		card_ui.reparent_requested.connect(_on_card_ui_reparent_requested)


func _on_card_ui_reparent_requested(child: CardUI) -> void:
	child.reparent(self)

	await get_tree().process_frame

	child.scale = Vector2.ONE
	child.rotation = 0
