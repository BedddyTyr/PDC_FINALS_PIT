# PlayerState.gd
# Holds all data for one player — synced across all peers each turn
extends RefCounted
class_name PlayerState

var player_id: int = 0
var player_name: String = "Player"
var max_hp: int = 30
var current_hp: int = 30
var block: int = 0
var energy: int = 3
var max_energy: int = 3
var hand: Array[CardData] = []
var deck: Array[CardData] = []
var discard: Array[CardData] = []
var poison_stacks: int = 0   # from Wither
var skip_draw: bool = false  # from Slow
var energy_penalty: int = 0  # from Hex

func is_alive() -> bool:
	return current_hp > 0

func draw_cards(count: int) -> void:
	if skip_draw:
		skip_draw = false
		return
	for i in range(count):
		if deck.is_empty():
			if discard.is_empty():
				return
			deck = discard.duplicate()
			discard.clear()
			deck.shuffle()
		if not deck.is_empty():
			hand.append(deck.pop_back())

func take_damage(amount: int) -> int:
	var actual = max(0, amount - block)
	block = max(0, block - amount)
	current_hp = max(0, current_hp - actual)
	return actual

func add_block(amount: int) -> void:
	block += amount

func heal_hp(amount: int) -> void:
	current_hp = min(max_hp, current_hp + amount)

func start_turn() -> void:
	block = 0  # Block resets each turn
	energy = max_energy - energy_penalty
	energy_penalty = 0
	# Apply poison
	if poison_stacks > 0:
		take_damage(poison_stacks)
		poison_stacks = max(0, poison_stacks - 1)

func end_turn() -> void:
	discard.append_array(hand)
	hand.clear()

# Serialize to dictionary for network transmission
func to_dict() -> Dictionary:
	var hand_data = []
	for card in hand:
		hand_data.append(_card_to_dict(card))
	return {
		"player_id": player_id,
		"player_name": player_name,
		"max_hp": max_hp,
		"current_hp": current_hp,
		"block": block,
		"energy": energy,
		"max_energy": max_energy,
		"poison_stacks": poison_stacks,
		"skip_draw": skip_draw,
		"energy_penalty": energy_penalty,
		"hand": hand_data,
		"deck_count": deck.size(),
		"discard_count": discard.size()
	}

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

static func card_from_dict(d: Dictionary) -> CardData:
	var card = CardData.new()
	card.card_name = d.get("card_name", "Unknown")
	card.card_type = d.get("card_type", CardData.CardType.ATTACK)
	card.description = d.get("description", "")
	card.damage = d.get("damage", 0)
	card.block = d.get("block", 0)
	card.heal = d.get("heal", 0)
	card.energy_cost = d.get("energy_cost", 1)
	card.draw_cards = d.get("draw_cards", 0)
	return card
