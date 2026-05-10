class_name CardEffect
extends Resource

enum EffectType {
	NONE,
	BUFF_ATTACK,
	BUFF_DEFENSE,
	HEAL,
	POISON,
	WEAKEN,
	DRAW,
	STUN
}

@export_group("Effect Identity")
@export var effect_id: StringName
@export var trigger: StringName = &"on_play"

@export_group("Targeting")
@export var target_scope: StringName = &"selected_target"
@export var can_target_dead := false

@export_group("Values")
@export var values: Dictionary = {}
@export var scaling: Dictionary = {}

@export_group("Status Payload")
@export var status_payload: Dictionary = {}
