# Game.gd — Main battle scene
extends Control

@onready var hand_container: HBoxContainer    = $GameLayout/Bottom/HandContainer
@onready var players_container: HBoxContainer = $GameLayout/MainArea/Center/PlayersArea
@onready var turn_label: Label                = $GameLayout/Top/TurnLabel
@onready var end_turn_btn: Button             = $GameLayout/Bottom/EndTurnBtn
@onready var log_container: VBoxContainer     = $GameLayout/MainArea/Right/LogScroll/LogBox
@onready var game_over_panel: Panel           = $GameOverPanel
@onready var winner_label: Label              = $GameOverPanel/VBox/WinnerLabel
@onready var energy_label: Label              = $GameLayout/Bottom/LeftInfo/EnergyLabel

var selected_card_index: int = -1
var player_panels: Array = []   # Array[Dictionary] — direct node refs per panel
const LOG_MAX: int = 14

func _ready() -> void:
	GameManager.state_updated.connect(_refresh_ui)
	GameManager.turn_started.connect(_on_turn_started)
	GameManager.game_over.connect(_on_game_over)
	GameManager.card_played.connect(_on_card_played)
	GameManager.damage_dealt.connect(_on_damage_dealt)
	GameManager.block_gained.connect(_on_block_gained)
	GameManager.hp_healed.connect(_on_hp_healed)
	end_turn_btn.pressed.connect(_on_end_turn_pressed)
	$GameOverPanel/VBox/ReturnBtn.pressed.connect(_on_return_to_menu)
	game_over_panel.visible = false
	_build_player_panels()
	_refresh_ui()

# ─── Player panels ────────────────────────────────────────────────────────────

func _build_player_panels() -> void:
	for child in players_container.get_children():
		child.queue_free()
	player_panels.clear()
	for i in range(GameManager.players.size()):
		var refs = _create_player_panel(i)
		players_container.add_child(refs["panel"])
		player_panels.append(refs)

func _create_player_panel(index: int) -> Dictionary:
	var panel = Panel.new()
	panel.name = "PlayerPanel_%d" % index
	panel.custom_minimum_size = Vector2(190, 250)

	var vbox = VBoxContainer.new()
	vbox.name = "VBox"
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 8)
	vbox.add_theme_constant_override("separation", 4)

	var name_lbl = Label.new()
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 15)

	var hp_bar = ProgressBar.new()
	hp_bar.min_value = 0
	hp_bar.max_value = 30
	hp_bar.custom_minimum_size = Vector2(0, 18)
	hp_bar.show_percentage = false

	var hp_lbl = Label.new()
	hp_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hp_lbl.add_theme_font_size_override("font_size", 13)

	var block_lbl = Label.new()
	block_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	block_lbl.add_theme_font_size_override("font_size", 13)
	block_lbl.add_theme_color_override("font_color", Color(0.5, 0.7, 1.0))

	var poison_lbl = Label.new()
	poison_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	poison_lbl.add_theme_font_size_override("font_size", 13)
	poison_lbl.add_theme_color_override("font_color", Color(0.4, 0.9, 0.3))

	var energy_lbl = Label.new()
	energy_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	energy_lbl.add_theme_font_size_override("font_size", 13)
	energy_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))

	var target_btn = Button.new()
	target_btn.text = "▶ TARGET"
	target_btn.visible = false
	target_btn.pressed.connect(_on_target_selected.bind(index))

	vbox.add_child(name_lbl)
	vbox.add_child(hp_bar)
	vbox.add_child(hp_lbl)
	vbox.add_child(block_lbl)
	vbox.add_child(poison_lbl)
	vbox.add_child(energy_lbl)
	vbox.add_child(target_btn)
	panel.add_child(vbox)

	return {
		"panel":      panel,
		"name_lbl":   name_lbl,
		"hp_bar":     hp_bar,
		"hp_lbl":     hp_lbl,
		"block_lbl":  block_lbl,
		"poison_lbl": poison_lbl,
		"energy_lbl": energy_lbl,
		"target_btn": target_btn,
	}

# ─── Refresh ──────────────────────────────────────────────────────────────────

func _refresh_ui() -> void:
	_refresh_player_panels()
	_refresh_hand()
	var my = GameManager.my_player_index
	if my >= 0 and my < GameManager.players.size():
		var ps = GameManager.players[my]
		energy_label.text = "⚡ %d / %d energy" % [ps.energy, ps.max_energy]
	end_turn_btn.disabled = not GameManager.is_my_turn()

func _refresh_player_panels() -> void:
	for i in range(min(GameManager.players.size(), player_panels.size())):
		var ps: PlayerState = GameManager.players[i]
		var r: Dictionary   = player_panels[i]

		var you = " (You)" if i == GameManager.my_player_index else ""
		var dead = " ☠" if not ps.is_alive() else ""
		r["name_lbl"].text   = ps.player_name + you + dead
		r["hp_bar"].max_value = ps.max_hp
		r["hp_bar"].value     = ps.current_hp
		r["hp_lbl"].text      = "HP: %d / %d" % [ps.current_hp, ps.max_hp]
		r["block_lbl"].text   = "🛡 %d" % ps.block if ps.block > 0 else ""
		r["poison_lbl"].text  = "☠ Poison %d" % ps.poison_stacks if ps.poison_stacks > 0 else ""
		r["energy_lbl"].text  = "⚡ %d / %d" % [ps.energy, ps.max_energy]

		var is_enemy = i != GameManager.my_player_index
		var wants_target = selected_card_index >= 0 and _selected_card_needs_target()
		r["target_btn"].visible = is_enemy and wants_target and GameManager.is_my_turn() and ps.is_alive()

		# Panel border: gold = active turn, dim = inactive
		var active = (i == GameManager.current_turn_index)
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.32, 0.22, 0.08) if active else Color(0.12, 0.09, 0.07)
		style.set_border_width_all(3 if active else 1)
		style.border_color = Color(0.95, 0.78, 0.3) if active else Color(0.35, 0.28, 0.18)
		style.corner_radius_top_left    = 6
		style.corner_radius_top_right   = 6
		style.corner_radius_bottom_left = 6
		style.corner_radius_bottom_right = 6
		r["panel"].add_theme_stylebox_override("panel", style)

# ─── Hand / card buttons ──────────────────────────────────────────────────────

func _refresh_hand() -> void:
	for child in hand_container.get_children():
		child.queue_free()
	var my = GameManager.my_player_index
	if my < 0 or my >= GameManager.players.size():
		return
	var ps: PlayerState = GameManager.players[my]
	for i in range(ps.hand.size()):
		hand_container.add_child(_create_card_button(ps.hand[i], i))

func _create_card_button(card: CardData, index: int) -> Control:
	# Outer container so image + text stack vertically inside a fixed size
	var container = Panel.new()
	container.custom_minimum_size = Vector2(115, 165)
	container.name = "Card_%d" % index

	var vbox = VBoxContainer.new()
	vbox.name = "VBox"
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 4)
	vbox.add_theme_constant_override("separation", 3)

	# ── Card image area ──────────────────────────────────────────────────────
	var img_rect = TextureRect.new()
	img_rect.custom_minimum_size = Vector2(0, 70)
	img_rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	img_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	img_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	var tex = card.load_texture()
	if tex:
		img_rect.texture = tex
	else:
		# Placeholder: colored panel with card-type initial
		var placeholder = Panel.new()
		placeholder.custom_minimum_size = Vector2(0, 70)
		placeholder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var ph_style = StyleBoxFlat.new()
		ph_style.bg_color = card.get_type_color().darkened(0.2)
		ph_style.corner_radius_top_left    = 4
		ph_style.corner_radius_top_right   = 4
		ph_style.corner_radius_bottom_left = 0
		ph_style.corner_radius_bottom_right = 0
		placeholder.add_theme_stylebox_override("panel", ph_style)
		var type_lbl = Label.new()
		type_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		type_lbl.text = card.get_type_name()[0]  # "A", "D", "S", "C", "H"
		type_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		type_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		type_lbl.add_theme_font_size_override("font_size", 28)
		type_lbl.add_theme_color_override("font_color", Color(1, 1, 1, 0.4))
		placeholder.add_child(type_lbl)
		vbox.add_child(placeholder)

	if tex:
		vbox.add_child(img_rect)

	# ── Text area ─────────────────────────────────────────────────────────────
	var name_lbl = Label.new()
	name_lbl.text = card.card_name
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 11)
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	var cost_lbl = Label.new()
	cost_lbl.text = "⚡ %d" % card.energy_cost
	cost_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cost_lbl.add_theme_font_size_override("font_size", 11)
	cost_lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))

	var stats_lbl = Label.new()
	var parts: Array = []
	if card.damage > 0:    parts.append("⚔%d" % card.damage)
	if card.block > 0:     parts.append("🛡%d" % card.block)
	if card.heal > 0:      parts.append("💚%d" % card.heal)
	if card.draw_cards > 0: parts.append("🃏+%d" % card.draw_cards)
	stats_lbl.text = "  ".join(parts)
	stats_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_lbl.add_theme_font_size_override("font_size", 11)

	vbox.add_child(name_lbl)
	vbox.add_child(cost_lbl)
	vbox.add_child(stats_lbl)
	container.add_child(vbox)

	# ── Card panel style ──────────────────────────────────────────────────────
	var style = StyleBoxFlat.new()
	var selected = (index == selected_card_index)
	style.bg_color = card.get_type_color().darkened(0.35) if not selected else card.get_type_color().lightened(0.1)
	style.set_border_width_all(3 if selected else 1)
	style.border_color = Color.WHITE if selected else card.get_type_color()
	style.corner_radius_top_left    = 5
	style.corner_radius_top_right   = 5
	style.corner_radius_bottom_left = 5
	style.corner_radius_bottom_right = 5
	container.add_theme_stylebox_override("panel", style)

	# ── Click area over entire card ───────────────────────────────────────────
	var btn = Button.new()
	btn.name = "ClickArea"
	btn.flat = true
	btn.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	btn.disabled = not GameManager.is_my_turn()
	# Transparent style so the panel art shows through
	var flat_style = StyleBoxEmpty.new()
	btn.add_theme_stylebox_override("normal",   flat_style)
	btn.add_theme_stylebox_override("hover",    flat_style)
	btn.add_theme_stylebox_override("pressed",  flat_style)
	btn.add_theme_stylebox_override("disabled", flat_style)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.tooltip_text = card.description
	btn.pressed.connect(_on_card_selected.bind(index))
	container.add_child(btn)

	return container

# ─── Input ────────────────────────────────────────────────────────────────────

func _on_card_selected(index: int) -> void:
	if not GameManager.is_my_turn():
		return
	selected_card_index = index if selected_card_index != index else -1
	_refresh_ui()
	# Self-targeted cards play immediately
	if selected_card_index >= 0 and not _selected_card_needs_target():
		GameManager.play_card(selected_card_index, GameManager.my_player_index)
		selected_card_index = -1
		_refresh_ui()

func _on_target_selected(target_index: int) -> void:
	if selected_card_index < 0:
		return
	GameManager.play_card(selected_card_index, target_index)
	selected_card_index = -1
	_refresh_ui()

func _on_end_turn_pressed() -> void:
	selected_card_index = -1
	GameManager.end_turn()

func _selected_card_needs_target() -> bool:
	var my = GameManager.my_player_index
	if my < 0: return false
	var ps = GameManager.players[my]
	if selected_card_index < 0 or selected_card_index >= ps.hand.size():
		return false
	var card = ps.hand[selected_card_index]
	return card.damage > 0 and card.card_name != "Cleave"

# ─── Events ───────────────────────────────────────────────────────────────────

func _on_turn_started(player_index: int) -> void:
	var ps = GameManager.players[player_index]
	turn_label.text = "Turn %d  —  %s's turn" % [GameManager.turn_number, ps.player_name]
	_add_log("↩  %s's turn begins." % ps.player_name)
	_refresh_ui()

func _on_card_played(player_index: int, card: CardData, _ti: int) -> void:
	_add_log("  %s played %s" % [GameManager.players[player_index].player_name, card.card_name])

func _on_damage_dealt(target_index: int, amount: int) -> void:
	_add_log("  💥 %s took %d damage" % [GameManager.players[target_index].player_name, amount])

func _on_block_gained(player_index: int, amount: int) -> void:
	_add_log("  🛡 %s gained %d block" % [GameManager.players[player_index].player_name, amount])

func _on_hp_healed(player_index: int, amount: int) -> void:
	_add_log("  💚 %s healed %d HP" % [GameManager.players[player_index].player_name, amount])

func _on_game_over(winner_name: String) -> void:
	game_over_panel.visible = true
	winner_label.text = "🏆 %s wins!" % winner_name
	_add_log("═══ GAME OVER — %s wins! ═══" % winner_name)

func _add_log(msg: String) -> void:
	var lbl = Label.new()
	lbl.text = msg
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.add_theme_font_size_override("font_size", 12)
	log_container.add_child(lbl)
	while log_container.get_child_count() > LOG_MAX:
		log_container.get_child(0).queue_free()

func _on_return_to_menu() -> void:
	NetworkManager.disconnect_from_game()
	get_tree().change_scene_to_file.call_deferred("res://scenes/MainMenu.tscn")
