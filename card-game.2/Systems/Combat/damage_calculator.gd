class_name DamageCalculator
extends RefCounted

static func calculate_damage(
	base_damage: int,
	source: BattleEntity,
	target: BattleEntity,
	context: Dictionary = {}
) -> int:

	var final_damage: int = max(0, base_damage)

	if source and source.status_effects.has(&"strength"):
		final_damage += int(
			source.status_effects[&"strength"]["stacks"]
		)

	if target and target.status_effects.has(&"weak"):
		final_damage = maxi(
			0,
			final_damage - int(
				target.status_effects[&"weak"]["stacks"]
			)
		)

	if context.has("bonus_damage"):
		final_damage += int(context["bonus_damage"])

	return max(0, final_damage)
