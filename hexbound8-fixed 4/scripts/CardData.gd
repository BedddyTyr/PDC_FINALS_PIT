# CardData.gd
# Defines all card types. Add card art by dropping PNGs into res://assets/cards/
# and setting image_path on each CardData instance.
extends Resource
class_name CardData

enum CardType { ATTACK, DEFEND, SPELL, CURSE, HEAL }

@export var card_name: String = "Unknown Card"
@export var card_type: CardType = CardType.ATTACK
@export var description: String = ""
@export var damage: int = 0
@export var block: int = 0
@export var heal: int = 0
@export var energy_cost: int = 1
@export var draw_cards: int = 0

# Optional: set to "res://assets/cards/strike.png" etc.
# If the file doesn't exist the card renders with a color placeholder.
@export var image_path: String = ""

func get_type_color() -> Color:
	match card_type:
		CardType.ATTACK: return Color(0.75, 0.18, 0.18)
		CardType.DEFEND: return Color(0.18, 0.38, 0.78)
		CardType.SPELL:  return Color(0.55, 0.18, 0.78)
		CardType.CURSE:  return Color(0.28, 0.08, 0.28)
		CardType.HEAL:   return Color(0.18, 0.65, 0.28)
	return Color.WHITE

func get_type_name() -> String:
	return CardType.keys()[card_type]

# Try to load the card texture; returns null if path unset or file missing.
func load_texture() -> Texture2D:
	if image_path.is_empty():
		return null
	if ResourceLoader.exists(image_path):
		return load(image_path) as Texture2D
	return null

# Helper: derive a default image path from the card name
# e.g. "Heavy Blow" -> "res://assets/cards/heavy_blow.png"
static func image_path_for(name: String) -> String:
	return "res://assets/cards/%s.png" % name.to_lower().replace(" ", "_")

# ─── Deck factory ─────────────────────────────────────────────────────────────

static func _make(p_name: String, p_type: CardType, p_desc: String,
		p_dmg: int, p_blk: int, p_heal: int, p_cost: int, p_draw: int) -> CardData:
	var c = CardData.new()
	c.card_name   = p_name
	c.card_type   = p_type
	c.description = p_desc
	c.damage      = p_dmg
	c.block       = p_blk
	c.heal        = p_heal
	c.energy_cost = p_cost
	c.draw_cards  = p_draw
	c.image_path  = image_path_for(p_name)  # auto-set; file may or may not exist
	return c

static func create_default_deck() -> Array[CardData]:
	var deck: Array[CardData] = []
	var A = CardType.ATTACK
	var D = CardType.DEFEND
	var S = CardType.SPELL
	var C = CardType.CURSE
	var H = CardType.HEAL

	for i in 4: deck.append(_make("Strike",         A, "Deal 6 damage.",                          6,  0, 0, 1, 0))
	for i in 2: deck.append(_make("Heavy Blow",     A, "Deal 12 damage. Costs 2 energy.",         12, 0, 0, 2, 0))
	deck.append(             _make("Cleave",         A, "Deal 4 damage to ALL enemies.",           4,  0, 0, 1, 0))
	deck.append(             _make("Twin Strike",    A, "Deal 5 damage twice.",                    10, 0, 0, 1, 0))
	for i in 4: deck.append(_make("Defend",         D, "Gain 5 Block.",                           0,  5, 0, 1, 0))
	deck.append(             _make("Iron Wave",      D, "Deal 5 damage and gain 5 Block.",         5,  5, 0, 1, 0))
	deck.append(             _make("Fireball",       S, "Deal 18 damage. Costs 2 energy.",         18, 0, 0, 2, 0))
	deck.append(             _make("Arcane Bolt",    S, "Deal 8 damage and draw 1 card.",          8,  0, 0, 1, 1))
	deck.append(             _make("Slow",           S, "Target skips their next draw phase.",     0,  0, 0, 1, 0))
	deck.append(             _make("Hex",            C, "Deal 5 dmg. Target loses 1 energy.",      5,  0, 0, 1, 0))
	deck.append(             _make("Wither",         C, "Apply 3 poison stacks to target.",        0,  0, 0, 1, 0))
	for i in 2: deck.append(_make("Healing Potion", H, "Restore 8 HP.",                           0,  0, 8, 1, 0))
	deck.append(             _make("Second Wind",    H, "Restore 5 HP and draw 1 card.",           0,  0, 5, 1, 1))

	deck.shuffle()
	return deck
