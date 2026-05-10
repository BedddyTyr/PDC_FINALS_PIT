class_name TurnManager
extends Node

signal turn_phase_changed(active_peer_id: int, phase: StringName)
signal turn_started(active_peer_id: int)
signal turn_ended(active_peer_id: int)

const PHASE_START: StringName = &"start"
const PHASE_DRAW: StringName = &"draw"
const PHASE_MAIN: StringName = &"main"
const PHASE_END: StringName = &"end"
const PHASE_CLEANUP: StringName = &"cleanup"

@export var player_order: Array[int] = [1, 2]
@export var draw_amount := 5

var current_player_index := 0
var current_phase: StringName = PHASE_START

func start_match() -> void:
	current_player_index = 0
	_begin_turn(player_order[current_player_index])

func advance_phase(entity_by_peer: Dictionary) -> void:
	match current_phase:
		PHASE_START:
			_set_phase(PHASE_DRAW)
			var active := _active_entity(entity_by_peer)
			if active:
				active.gain_energy(active.base_energy)
			advance_phase(entity_by_peer)
		PHASE_DRAW:
			_set_phase(PHASE_MAIN)
			var active := _active_entity(entity_by_peer)
			if active:
				active.draw_card(draw_amount)
		PHASE_MAIN:
			_set_phase(PHASE_END)
		PHASE_END:
			_set_phase(PHASE_CLEANUP)
		PHASE_CLEANUP:
			_end_turn(entity_by_peer)

func _begin_turn(peer_id: int) -> void:
	current_phase = PHASE_START
	turn_started.emit(peer_id)
	turn_phase_changed.emit(peer_id, current_phase)

func _end_turn(entity_by_peer: Dictionary) -> void:
	turn_ended.emit(player_order[current_player_index])
	current_player_index = (current_player_index + 1) % player_order.size()
	_begin_turn(player_order[current_player_index])

func _set_phase(phase: StringName) -> void:
	current_phase = phase
	turn_phase_changed.emit(player_order[current_player_index], phase)

func _active_entity(entity_by_peer: Dictionary) -> BattleEntity:
	return entity_by_peer.get(player_order[current_player_index])
