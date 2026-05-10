class_name EffectResolver
extends RefCounted

func resolve_card_effect(
	effect: CardEffect,
	source: BattleEntity,
	targets: Array[BattleEntity],
	combat_manager: CombatManager
) -> Array[Dictionary]:

	var results: Array[Dictionary] = []

	match effect.effect_id:

		&"damage":
			results = _resolve_damage(
				effect,
				source,
				targets,
				combat_manager
			)

		&"block":
			results = _resolve_block(
				effect,
				targets,
				combat_manager
			)

		&"heal":
			results = _resolve_heal(
				effect,
				targets,
				combat_manager
			)

		&"status":
			results = _resolve_status(
				effect,
				targets
			)

		_:
			results.append({
				"kind": "unhandled",
				"effect_id": effect.effect_id
			})

	return results


func _resolve_damage(
	effect: CardEffect,
	source: BattleEntity,
	targets: Array[BattleEntity],
	combat_manager: CombatManager
) -> Array[Dictionary]:

	var results: Array[Dictionary] = []

	var base_amount: int = int(
		effect.values.get("amount", 0)
	)

	for target: BattleEntity in targets:

		var final_damage: int = DamageCalculator.calculate_damage(
			base_amount,
			source,
			target
		)

		results.append(
			combat_manager.apply_damage(
				source,
				target,
				final_damage
			)
		)

	return results


func _resolve_block(
	effect: CardEffect,
	targets: Array[BattleEntity],
	combat_manager: CombatManager
) -> Array[Dictionary]:

	var results: Array[Dictionary] = []

	var amount: int = int(
		effect.values.get("amount", 0)
	)

	for target: BattleEntity in targets:

		results.append(
			combat_manager.apply_block(
				target,
				amount
			)
		)

	return results


func _resolve_heal(
	effect: CardEffect,
	targets: Array[BattleEntity],
	combat_manager: CombatManager
) -> Array[Dictionary]:

	var results: Array[Dictionary] = []

	var amount: int = int(
		effect.values.get("amount", 0)
	)

	for target: BattleEntity in targets:

		results.append(
			combat_manager.apply_heal(
				target,
				amount
			)
		)

	return results


func _resolve_status(
	effect: CardEffect,
	targets: Array[BattleEntity]
) -> Array[Dictionary]:

	var results: Array[Dictionary] = []

	var status_id: StringName = effect.status_payload.get(
		"status_id",
		&"generic"
	)

	var stacks: int = int(
		effect.status_payload.get("stacks", 1)
	)

	var duration: int = int(
		effect.status_payload.get("duration", 1)
	)

	var trigger: StringName = effect.status_payload.get(
		"trigger",
		&"turn_end"
	)

	for target: BattleEntity in targets:

		target.apply_status_effect(
			status_id,
			stacks,
			duration,
			trigger
		)

		results.append({
			"kind": "status",
			"target": target.entity_id,
			"status_id": status_id
		})

	return results
