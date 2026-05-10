class_name BattleEntity
extends Node

signal stats_changed(entity: BattleEntity)
signal died(entity: BattleEntity)

@export var entity_id: StringName
@export var owner_peer_id := 1
@export var max_hp := 80
@export var base_energy := 3
@export var draw_per_turn := 5

var current_hp: int = 0
var current_block: int = 0
var temporary_hp: int = 0
var energy: int = 0

var deck: Array[Card] = []
var draw_pile: Array[Card] = []
var discard_pile: Array[Card] = []
var hand: Array[Card] = []
var exhaust_pile: Array[Card] = []

var status_effects: Dictionary = {}
var relics: Array[StringName] = []

func _ready() -> void:
	current_hp = max_hp
	energy = base_energy

func start_turn() -> void:
	energy = base_energy
	draw_card(draw_per_turn)
	_emit_stats_changed()

func end_turn() -> void:
	current_block = 0
	_emit_stats_changed()

func draw_card(amount := 1) -> Array[Card]:

	var drawn: Array[Card] = []

	for _i in range(amount):

		if draw_pile.is_empty():
			_reshuffle_discard_into_draw()

		if draw_pile.is_empty():
			break

		var card: Card = draw_pile.pop_back()

		hand.append(card)
		drawn.append(card)

	_emit_stats_changed()

	return drawn

func discard_card(card: Card) -> void:

	if hand.has(card):
		hand.erase(card)
		discard_pile.append(card)

	_emit_stats_changed()

func exhaust_card(card: Card) -> void:

	if hand.has(card):
		hand.erase(card)
		exhaust_pile.append(card)

	_emit_stats_changed()

func gain_energy(amount: int) -> void:
	energy += max(0, amount)
	_emit_stats_changed()

func spend_energy(amount: int) -> bool:

	if amount < 0 or energy < amount:
		return false

	energy -= amount

	_emit_stats_changed()

	return true

func gain_block(amount: int) -> void:
	current_block += amount
	_emit_stats_changed()

func heal(amount: int) -> void:
	current_hp = min(current_hp + amount, max_hp)
	_emit_stats_changed()

func take_damage(amount: int) -> void:

	var remaining_damage: int = amount

	if current_block > 0:

		if current_block >= remaining_damage:
			current_block -= remaining_damage
			remaining_damage = 0
		else:
			remaining_damage -= current_block
			current_block = 0

	current_hp -= remaining_damage

	if current_hp <= 0:
		current_hp = 0
		died.emit(self)

	_emit_stats_changed()

func play_card(card: Card, target: BattleEntity) -> bool:

	if not hand.has(card):
		return false

	if not spend_energy(card.mana_cost):
		return false

	if card.damage > 0 and target != null:
		target.take_damage(card.damage)

	if card.defense > 0:
		gain_block(card.defense)

	for effect: Resource in card.effects:

		if effect == null:
			continue

		if effect.has_method("apply"):
			effect.apply(self, target)

	discard_card(card)

	return true

func apply_status_effect(
	effect_id: StringName,
	stacks := 1,
	duration := 1,
	trigger: StringName = &"turn_end"
) -> void:

	if not status_effects.has(effect_id):

		status_effects[effect_id] = {
			"stacks": 0,
			"duration": duration,
			"trigger": trigger
		}

	status_effects[effect_id]["stacks"] += stacks
	status_effects[effect_id]["duration"] = max(
		status_effects[effect_id]["duration"],
		duration
	)

	_emit_stats_changed()

func _reshuffle_discard_into_draw() -> void:

	draw_pile = discard_pile.duplicate()
	discard_pile.clear()
	draw_pile.shuffle()

func _emit_stats_changed() -> void:
	stats_changed.emit(self)
