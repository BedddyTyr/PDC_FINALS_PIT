class_name Card
extends Resource

enum Type {ATTACK, DEFEND, POWER, SKILL, STATUS}
enum Target {SELF, SINGLE_ENEMY, ALL_ENEMIES, EVERYONE}

@export_group("Card Attributes")
@export var id: StringName
@export var card_name: String = ""
@export_multiline var description: String = ""
@export var type: Type
@export var target: Target
@export var energy_cost := 1

@export_group("Gameplay Data")
@export var effects: Array[CardEffect] = []
@export var status_effects: Array[Dictionary] = []
@export var tags: Array[StringName] = []
@export var balancing_values: Dictionary = {}

@export_group("Visual Data")
@export var icon: Texture2D
@export var frame: Texture2D

func is_single_targeted() -> bool:
	return target == Target.SINGLE_ENEMY
