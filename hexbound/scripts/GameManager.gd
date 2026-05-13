# GameManager.gd
# Autoload Singleton — manages game state, turn order, card resolution
extends Node

signal turn_started(player_index: int)
signal turn_ended(player_index: int)
signal game_over(winner_name: String)
signal state_updated()
signal card_played(player_index: int, card: CardData, target_index: int)
signal damage_dealt(target_index: int, amount: int)
signal block_gained(player_index: int, amount: int)
signal hp_healed(player_index: int, amount: int)

var players: Array[PlayerState] = []
var current_turn_index: int = 0
var turn_number: int = 1
var game_active: bool = false
var my_player_index: int = -1

# FIX: track whether we're currently processing an action to prevent double-fires
var _processing_action: bool = false

const HAND_SIZE: int = 5

# ─── Setup ────────────────────────────────────────────────────────────────────

func setup_game(peer_id_to_name: Dictionary) -> void:
	players.clear()
	_processing_action = false
	var ids = peer_id_to_name.keys()
	ids.sort()

	for idx in range(ids.size()):
		var pid = ids[idx]
		var ps = PlayerState.new()
		ps.player_id = pid
		ps.player_name = peer_id_to_name[pid]
		ps.deck = CardData.create_default_deck()
		ps.draw_cards(HAND_SIZE)
		players.append(ps)
		if pid == NetworkManager.my_peer_id:
			my_player_index = idx

	current_turn_index = 0
	turn_number = 1
	game_active = true
	emit_signal("state_updated")
	emit_signal("turn_started", current_turn_index)

# ─── Turn flow ────────────────────────────────────────────────────────────────

func is_my_turn() -> bool:
	return game_active and my_player_index == current_turn_index

func get_active_player() -> PlayerState:
	if players.is_empty():
		return null
	return players[current_turn_index]

func end_turn() -> void:
	if not is_my_turn() or not game_active or _processing_action:
		return
	var action = {
		"type": "end_turn",
		"player_index": current_turn_index
	}
	NetworkManager.broadcast_action(action)

func _process_end_turn(player_index: int) -> void:
	# FIX: guard against processing a stale/duplicate end_turn
	if player_index != current_turn_index:
		push_warning("Ignoring end_turn for player %d, current is %d" % [player_index, current_turn_index])
		return

	var player = players[player_index]
	player.end_turn()   # discards hand, resets block
	emit_signal("turn_ended", player_index)

	# Advance
	current_turn_index = (current_turn_index + 1) % players.size()
	if current_turn_index == 0:
		turn_number += 1

	# FIX: skip dead players
	var skips = 0
	while not players[current_turn_index].is_alive():
		current_turn_index = (current_turn_index + 1) % players.size()
		skips += 1
		if skips >= players.size():
			# Everyone is dead — shouldn't happen but avoid infinite loop
			break

	var next = players[current_turn_index]
	next.start_turn()
	# FIX: draw up to HAND_SIZE, not HAND_SIZE on top of existing hand
	var draw_count = max(0, HAND_SIZE - next.hand.size())
	next.draw_cards(draw_count)

	emit_signal("state_updated")
	emit_signal("turn_started", current_turn_index)

# ─── Card play ────────────────────────────────────────────────────────────────

func play_card(hand_index: int, target_index: int) -> void:
	if not is_my_turn() or not game_active or _processing_action:
		return
	var player = players[my_player_index]
	if hand_index < 0 or hand_index >= player.hand.size():
		return
	var card = player.hand[hand_index]
	if player.energy < card.energy_cost:
		push_warning("Not enough energy to play %s" % card.card_name)
		return

	var action = {
		"type": "play_card",
		"player_index": my_player_index,
		"hand_index": hand_index,
		"target_index": target_index,
		"card_data": _card_to_dict(card)
	}
	NetworkManager.broadcast_action(action)

func _process_play_card(player_index: int, hand_index: int, target_index: int, card_dict: Dictionary) -> void:
	var player = players[player_index]
	var card = PlayerState.card_from_dict(card_dict)

	# FIX: validate hand_index is still valid (network delay edge case)
	if hand_index >= player.hand.size():
		push_warning("hand_index %d out of range (%d cards)" % [hand_index, player.hand.size()])
		return

	player.hand.remove_at(hand_index)
	player.discard.append(card)
	player.energy -= card.energy_cost

	emit_signal("card_played", player_index, card, target_index)

	# Resolve effects
	if card.damage > 0:
		var targets: Array[int] = []
		if card.card_name == "Cleave":
			for i in range(players.size()):
				if i != player_index and players[i].is_alive():
					targets.append(i)
		else:
			if target_index >= 0 and target_index < players.size():
				targets.append(target_index)

		for t in targets:
			var dealt = players[t].take_damage(card.damage)
			emit_signal("damage_dealt", t, dealt)

	if card.block > 0:
		player.add_block(card.block)
		emit_signal("block_gained", player_index, card.block)

	if card.heal > 0:
		player.heal_hp(card.heal)
		emit_signal("hp_healed", player_index, card.heal)

	if card.draw_cards > 0:
		player.draw_cards(card.draw_cards)

	if card.card_name == "Slow" and target_index < players.size():
		players[target_index].skip_draw = true

	if card.card_name == "Hex" and target_index < players.size():
		players[target_index].energy_penalty += 1

	if card.card_name == "Wither" and target_index < players.size():
		players[target_index].poison_stacks += 3

	emit_signal("state_updated")
	_check_win_condition()

# ─── Win condition ────────────────────────────────────────────────────────────

func _check_win_condition() -> void:
	var alive: Array[PlayerState] = []
	for p in players:
		if p.is_alive():
			alive.append(p)

	if alive.size() == 1:
		game_active = false
		emit_signal("game_over", alive[0].player_name)
	elif alive.is_empty():
		game_active = false
		emit_signal("game_over", "Nobody")

# ─── Network dispatcher ───────────────────────────────────────────────────────

func _ready() -> void:
	NetworkManager.game_action_received.connect(_on_action_received)

func _on_action_received(action: Dictionary) -> void:
	if _processing_action:
		return
	_processing_action = true
	match action.get("type", ""):
		"play_card":
			_process_play_card(
				action["player_index"],
				action["hand_index"],
				action["target_index"],
				action["card_data"]
			)
		"end_turn":
			_process_end_turn(action["player_index"])
	_processing_action = false

# ─── Helpers ──────────────────────────────────────────────────────────────────

func _card_to_dict(card: CardData) -> Dictionary:
	return {
		"card_name": card.card_name,
		"card_type": card.card_type,
		"description": card.description,
		"damage": card.damage,
		"block": card.block,
		"heal": card.heal,
		"energy_cost": card.energy_cost,
		"draw_cards": card.draw_cards
	}
