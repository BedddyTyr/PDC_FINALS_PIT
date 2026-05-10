class_name StatusEffectManager
extends RefCounted

func process_trigger(
	entity: BattleEntity,
	trigger: StringName
) -> Array[Dictionary]:

	var events: Array[Dictionary] = []

	for effect_id: Variant in entity.status_effects.keys():

		var payload: Dictionary = entity.status_effects[effect_id]

		var effect_trigger: StringName = payload.get(
			"trigger",
			&"turn_end"
		)

		if effect_trigger != trigger:
			continue

		events.append(
			_create_status_event(
				effect_id,
				payload,
				entity
			)
		)

		_update_effect_duration(
			entity,
			effect_id,
			payload
		)

	return events


func _create_status_event(
	effect_id: StringName,
	payload: Dictionary,
	entity: BattleEntity
) -> Dictionary:

	return {
		"effect_id": effect_id,
		"stacks": int(payload.get("stacks", 0)),
		"target": entity
	}


func _update_effect_duration(
	entity: BattleEntity,
	effect_id: StringName,
	payload: Dictionary
) -> void:

	var duration: int = int(
		payload.get("duration", 1)
	)

	duration -= 1

	if duration <= 0:

		entity.status_effects.erase(effect_id)

	else:

		payload["duration"] = duration
		entity.status_effects[effect_id] = payload
