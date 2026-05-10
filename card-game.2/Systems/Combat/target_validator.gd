class_name TargetValidator
extends RefCounted

static func is_valid_target(
	card: Card,
	source: BattleEntity,
	target: BattleEntity
) -> bool:

	if not _has_valid_references(card, source, target):
		return false

	if not _is_target_alive(target):
		return false

	match card.target:

		Card.Target.SELF:
			return _validate_self_target(
				source,
				target
			)

		Card.Target.SINGLE_ENEMY:
			return _validate_enemy_target(
				source,
				target
			)

		Card.Target.EVERYONE:
			return true

		Card.Target.ALL_ENEMIES:
			return true

		_:
			return false


static func _has_valid_references(
	card: Card,
	source: BattleEntity,
	target: BattleEntity
) -> bool:

	return (
		card != null
		and source != null
		and target != null
	)


static func _is_target_alive(
	target: BattleEntity
) -> bool:

	return target.current_hp > 0


static func _validate_self_target(
	source: BattleEntity,
	target: BattleEntity
) -> bool:

	return source == target


static func _validate_enemy_target(
	source: BattleEntity,
	target: BattleEntity
) -> bool:

	return (
		source.owner_peer_id
		!= target.owner_peer_id
	)
