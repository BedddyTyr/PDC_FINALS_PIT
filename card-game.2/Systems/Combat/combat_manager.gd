class_name CombatManager
extends Node

signal action_resolved(action_result: Dictionary)

var entities: Array[BattleEntity] = []
var effect_resolver: EffectResolver = EffectResolver.new()

func register_entity(entity: BattleEntity) -> void:

	if not entities.has(entity):
		entities.append(entity)

func resolve_card_action(action_request: Dictionary) -> Dictionary:

	var source: BattleEntity = action_request.get("source") as BattleEntity
	var card: Card = action_request.get("card") as Card
	var selected_target: BattleEntity = action_request.get("target") as BattleEntity

	if source == null or card == null:
		return {
			"ok": false,
			"reason": "invalid_request"
		}

	if not source.spend_energy(card.energy_cost):
		return {
			"ok": false,
			"reason": "not_enough_energy"
		}

	var targets: Array[BattleEntity] = _collect_targets(
		card,
		source,
		selected_target
	)

	var all_results: Array[Dictionary] = []

	for effect: Resource in card.effects:

		all_results.append_array(
			effect_resolver.resolve_card_effect(
				effect,
				source,
				targets,
				self
			)
		)

	var result: Dictionary = {
		"ok": true,
		"card_id": card.id,
		"source": source.entity_id,
		"events": all_results
	}

	action_resolved.emit(result)

	return result

func apply_damage(
	source: BattleEntity,
	target: BattleEntity,
	amount: int
) -> Dictionary:

	var remaining: int = max(0, amount)

	var blocked: int = min(
		target.current_block,
		remaining
	)

	target.current_block -= blocked
	remaining -= blocked

	target.current_hp = max(
		0,
		target.current_hp - remaining
	)

	target.stats_changed.emit(target)

	if target.current_hp <= 0:
		target.died.emit(target)

	return {
		"kind": "damage",
		"source": source.entity_id,
		"target": target.entity_id,
		"amount": amount,
		"blocked": blocked
	}

func apply_block(
	target: BattleEntity,
	amount: int
) -> Dictionary:

	target.current_block += max(0, amount)

	target.stats_changed.emit(target)

	return {
		"kind": "block",
		"target": target.entity_id,
		"amount": amount
	}

func apply_heal(
	target: BattleEntity,
	amount: int
) -> Dictionary:

	target.current_hp = min(
		target.max_hp,
		target.current_hp + max(0, amount)
	)

	target.stats_changed.emit(target)

	return {
		"kind": "heal",
		"target": target.entity_id,
		"amount": amount
	}

func _collect_targets(
	card: Card,
	source: BattleEntity,
	selected_target: BattleEntity
) -> Array[BattleEntity]:

	match card.target:

		Card.Target.SELF:
			return [source]

		Card.Target.SINGLE_ENEMY:

			if (
				selected_target
				and TargetValidator.is_valid_target(
					card,
					source,
					selected_target
				)
			):
				return [selected_target]

			return []

		Card.Target.ALL_ENEMIES:

			return entities.filter(
				func(e: BattleEntity):
					return (
						e.owner_peer_id != source.owner_peer_id
						and e.current_hp > 0
					)
			)

		Card.Target.EVERYONE:

			return entities.filter(
				func(e: BattleEntity):
					return e.current_hp > 0
			)

		_:
			return []
