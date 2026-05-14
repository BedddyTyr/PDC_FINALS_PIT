# Lobby.gd
# Shows connected players; host can start the game when 2+ joined
extends Control

@onready var player_list: VBoxContainer = $Center/Panel/VBox/PlayerList
@onready var start_btn: Button = $Center/Panel/VBox/StartBtn
@onready var status_label: Label = $Center/Panel/VBox/StatusLabel
@onready var room_code_label: Label = $Center/Panel/VBox/RoomCode

func _ready() -> void:
	NetworkManager.lobby_state_updated.connect(_on_lobby_updated)
	NetworkManager.player_disconnected.connect(_on_player_disconnected)
	NetworkManager.game_action_received.connect(_on_game_action)

	start_btn.visible = NetworkManager.is_host
	start_btn.pressed.connect(_on_start_pressed)

	room_code_label.text = "Host IP: %s  |  Port: %d" % [
		NetworkManager.get_local_ip(),
		NetworkManager.DEFAULT_PORT
	]

	_refresh_player_list(NetworkManager.connected_players)

func _on_lobby_updated(data: Dictionary) -> void:
	_refresh_player_list(data.get("players", {}))
	if data.get("game_started", false):
		_start_game_locally(data.get("players", {}))

func _refresh_player_list(players: Dictionary) -> void:
	for child in player_list.get_children():
		child.queue_free()

	var ids = players.keys()
	ids.sort()
	for pid in ids:
		var label = Label.new()
		var suffix = " [HOST]" if pid == 1 else ""
		var me = " (You)" if pid == NetworkManager.my_peer_id else ""
		label.text = "  ⚔  %s%s%s" % [players[pid], suffix, me]
		label.add_theme_font_size_override("font_size", 20)
		player_list.add_child(label)

	var count = players.size()
	var full_tag = "  —  FULL" if count >= NetworkManager.MAX_PLAYERS else ""
	status_label.text = "%d / %d players connected%s" % [count, NetworkManager.MAX_PLAYERS, full_tag]

	if NetworkManager.is_host:
		start_btn.disabled = count < 2 or count > NetworkManager.MAX_PLAYERS

func _on_player_disconnected(_peer_id: int) -> void:
	_refresh_player_list(NetworkManager.connected_players)

func _on_start_pressed() -> void:
	if not NetworkManager.is_host:
		return
	var action = {
		"type": "start_game",
		"players": NetworkManager.connected_players
	}
	NetworkManager.broadcast_action(action)

func _on_game_action(action: Dictionary) -> void:
	if action.get("type") == "start_game":
		_start_game_locally(action.get("players", {}))

func _start_game_locally(players_dict: Dictionary) -> void:
	var fixed: Dictionary = {}
	for k in players_dict.keys():
		fixed[int(k)] = players_dict[k]
	GameManager.setup_game(fixed)
	get_tree().change_scene_to_file.call_deferred("res://scenes/Game.tscn")
