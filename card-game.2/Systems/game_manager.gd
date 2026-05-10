class_name GameManager
extends Node

signal action_request_created(action_request: Dictionary)
signal action_resolved(action_result: Dictionary)

@export var combat_manager_path: NodePath
@export var turn_manager_path: NodePath

@onready var combat_manager: CombatManager = get_node_or_null(
	combat_manager_path
)

@onready var turn_manager: TurnManager = get_node_or_null(
	turn_manager_path
)

var entities_by_peer: Dictionary = {}

func register_entity(
	entity: BattleEntity
) -> void:

	entities_by_peer[entity.owner_peer_id] = entity

	if combat_manager != null:
		combat_manager.register_entity(entity)


func request_card_play(
	source_peer_id: int,
	card: Card,
	target_entity_id: StringName = &""
) -> Dictionary:

	var source: BattleEntity = _get_source_entity(
		source_peer_id
	)

	var target: BattleEntity = _find_entity_by_id(
		target_entity_id
	)

	var action_request: Dictionary = {
		"source": source,
		"card": card,
		"target": target,
		"source_peer_id": source_peer_id,
		"target_entity_id": target_entity_id
	}

	action_request_created.emit(action_request)

	if combat_manager == null:

		return {
			"ok": false,
			"reason": "combat_manager_missing"
		}

	var result: Dictionary = combat_manager.resolve_card_action(
		action_request
	)

	action_resolved.emit(result)

	return result


func start_battle() -> void:

	if turn_manager != null:
		turn_manager.start_match()


func _get_source_entity(
	source_peer_id: int
) -> BattleEntity:

	return entities_by_peer.get(
		source_peer_id
	) as BattleEntity


func _find_entity_by_id(
	entity_id: StringName
) -> BattleEntity:

	if entity_id == &"":
		return null

	for entity: BattleEntity in entities_by_peer.values():

		if entity.entity_id == entity_id:
			return entity

	return null
