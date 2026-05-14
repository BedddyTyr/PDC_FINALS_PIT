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

const HAND_SIZE: int = 5

# Action queue — network actions are pushed here and drained one per _process tick.
# This is intentionally single-threaded: game state mutation must be sequential.
# Multithreading is unsafe here because Godot signals, Node ops, and Array mutation
# are not thread-safe and would require mutexes on every field access.
var _action_queue: Array = []
var _processing: bool = false

# Tracks the last hand_index sent per player so we can detect staleness
var _last_sent_hand_index: Dictionary = {}   # my_player_index -> int

# ─── Setup ────────────────────────────────────────────────────────────────────

func setup_game(peer_id_to_name: Dictionary) -> void:
	players.clear()
	_action_queue.clear()
	_last_sent_hand_index.clear()
	_processing = false
	var ids = peer_id_to_name.keys()
	ids.sort()

	for idx in range(ids.size()):
		var pid = ids[idx]
		var ps = PlayerState.new()
		ps.player_id   = pid
		ps.player_name = peer_id_to_name[pid]
		ps.deck        = CardData.create_default_deck()
		ps.draw_cards(HAND_SIZE)
		players.append(ps)
		if pid == NetworkManager.my_peer_id:
			my_player_index = idx

	current_turn_index = 0
	turn_number        = 1
	game_active        = true
	emit_signal("state_updated")
	emit_signal("turn_started", current_turn_index)

# ─── Turn flow ────────────────────────────────────────────────────────────────

func is_my_turn() -> bool:
	return game_active \
		and my_player_index >= 0 \
		and my_player_index < players.size() \
		and my_player_index == current_turn_index

func get_active_player() -> PlayerState:
	return null if players.is_empty() else players[current_turn_index]

func end_turn() -> void:
	if not is_my_turn() or not game_active:
		return
	print("[GM] end_turn — player %d, turn %d" % [current_turn_index, turn_number])
	NetworkManager.broadcast_action({
		"type":         "end_turn",
		"player_index": current_turn_index,
	})

func _process_end_turn(player_index: int) -> void:
	if player_index != current_turn_index:
		push_warning("[GM] Stale end_turn for %d (current %d)" % [player_index, current_turn_index])
		return

	players[player_index].end_turn()
	emit_signal("turn_ended", player_index)

	current_turn_index = (current_turn_index + 1) % players.size()
	if current_turn_index == 0:
		turn_number += 1

	_check_win_condition()
	if not game_active:
		return

	var skips = 0
	while skips < players.size() and not players[current_turn_index].is_alive():
		current_turn_index = (current_turn_index + 1) % players.size()
		skips += 1

	var next = players[current_turn_index]
	next.start_turn()
	next.draw_cards(max(0, HAND_SIZE - next.hand.size()))

	print("[GM] turn_started — player %d (%s), hand=%d, energy=%d" % [
		current_turn_index, next.player_name, next.hand.size(), next.energy])

	emit_signal("state_updated")
	emit_signal("turn_started", current_turn_index)

# ─── Card play ────────────────────────────────────────────────────────────────

func play_card(hand_index: int, target_index: int) -> void:
	if not is_my_turn() or not game_active:
		push_warning("[GM] play_card ignored — not my turn or game inactive")
		return
	var player = players[my_player_index]
	if hand_index < 0 or hand_index >= player.hand.size():
		push_warning("[GM] play_card — hand_index %d invalid (hand size %d)" % [hand_index, player.hand.size()])
		return
	var card = player.hand[hand_index]
	if player.energy < card.energy_cost:
		push_warning("[GM] Not enough energy for %s (%d need %d)" % [card.card_name, player.energy, card.energy_cost])
		return

	# Guard: reject if this index was already sent and not yet processed
	# This prevents double-sending the same card when the UI refreshes mid-click
	if _last_sent_hand_index.get(my_player_index, -1) == hand_index:
		push_warning("[GM] play_card — hand_index %d already in-flight, ignoring duplicate" % hand_index)
		return
	_last_sent_hand_index[my_player_index] = hand_index

	print("[GM] play_card — %s at index %d -> target %d" % [card.card_name, hand_index, target_index])

	NetworkManager.broadcast_action({
		"type":         "play_card",
		"player_index": my_player_index,
		"hand_index":   hand_index,
		"target_index": target_index,
		"card_data":    _card_to_dict(card),
	})

func _process_play_card(player_index: int, hand_index: int, target_index: int, card_dict: Dictionary) -> void:
	var player = players[player_index]
	var card   = PlayerState.card_from_dict(card_dict)

	if hand_index >= player.hand.size():
		push_error("[GM] _process_play_card — hand_index %d out of range (hand=%d). card=%s. Dropping." % [
			hand_index, player.hand.size(), card.card_name])
		# Clear the in-flight lock so the player isn't permanently stuck
		_last_sent_hand_index.erase(player_index)
		return

	player.hand.remove_at(hand_index)
	player.discard.append(card)
	player.energy -= card.energy_cost

	# Clear in-flight lock now that the action has been applied
	_last_sent_hand_index.erase(player_index)

	print("[GM] applied %s — %s hand now %d cards, energy %d" % [
		card.card_name, player.player_name, player.hand.size(), player.energy])

	emit_signal("card_played", player_index, card, target_index)

	if card.damage > 0:
		var targets: Array[int] = []
		if card.card_name == "Cleave":
			for i in range(players.size()):
				if i != player_index and players[i].is_alive():
					targets.append(i)
		elif target_index >= 0 and target_index < players.size():
			targets.append(target_index)
		for t in targets:
			emit_signal("damage_dealt", t, players[t].take_damage(card.damage))

	if card.block > 0:
		player.add_block(card.block)
		emit_signal("block_gained", player_index, card.block)

	if card.heal > 0:
		player.heal_hp(card.heal)
		emit_signal("hp_healed", player_index, card.heal)

	if card.draw_cards > 0:
		player.draw_cards(card.draw_cards)

	if card.card_name == "Slow"   and target_index < players.size():
		players[target_index].skip_draw      = true
	if card.card_name == "Hex"    and target_index < players.size():
		players[target_index].energy_penalty += 1
	if card.card_name == "Wither" and target_index < players.size():
		players[target_index].poison_stacks  += 3

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
		print("[GM] Game over — %s wins!" % alive[0].player_name)
		emit_signal("game_over", alive[0].player_name)
	elif alive.is_empty():
		game_active = false
		emit_signal("game_over", "Nobody")

# ─── Action queue ─────────────────────────────────────────────────────────────

func _ready() -> void:
	NetworkManager.game_action_received.connect(_on_action_received)
	set_process(true)

func _on_action_received(action: Dictionary) -> void:
	_action_queue.push_back(action)
	print("[GM] queued action '%s' (queue depth: %d)" % [action.get("type","?"), _action_queue.size()])

func _process(_delta: float) -> void:
	if _action_queue.is_empty() or _processing:
		return
	_processing = true
	var action = _action_queue.pop_front()
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
		_:
			push_warning("[GM] Unknown action type: %s" % action.get("type","?"))
	_processing = false

# ─── Helpers ─────────────────────────────────────────────────────────────────

func _card_to_dict(card: CardData) -> Dictionary:
	return {
		"card_name":   card.card_name,
		"card_type":   card.card_type,
		"description": card.description,
		"damage":      card.damage,
		"block":       card.block,
		"heal":        card.heal,
		"energy_cost": card.energy_cost,
		"draw_cards":  card.draw_cards,
	}
