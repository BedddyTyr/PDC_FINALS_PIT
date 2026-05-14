# MainMenu.gd
# Entry screen: enter name, host or join
extends Control

@onready var name_input: LineEdit = $Center/VBox/NameInput
@onready var ip_input: LineEdit = $Center/VBox/IPInput
@onready var host_btn: Button = $Center/VBox/HostBtn
@onready var join_btn: Button = $Center/VBox/JoinBtn
@onready var status_label: Label = $Center/VBox/StatusLabel
@onready var local_ip_label: Label = $Center/VBox/LocalIPLabel

func _ready() -> void:
	local_ip_label.text = "Your LAN IP: %s" % NetworkManager.get_local_ip()
	host_btn.pressed.connect(_on_host_pressed)
	join_btn.pressed.connect(_on_join_pressed)
	NetworkManager.connection_failed.connect(_on_connection_failed)
	NetworkManager.lobby_state_updated.connect(_on_lobby_ready)

func _on_host_pressed() -> void:
	var player_name = name_input.text.strip_edges()
	if player_name.is_empty():
		player_name = "Host"
	status_label.text = "Creating lobby..."
	var err = NetworkManager.host_game(player_name)
	if err == OK:
		get_tree().change_scene_to_file.call_deferred("res://scenes/Lobby.tscn")
	else:
		status_label.text = "Failed to host. Check port availability."

func _on_join_pressed() -> void:
	var player_name = name_input.text.strip_edges()
	var host_ip = ip_input.text.strip_edges()
	if player_name.is_empty():
		player_name = "Player"
	if host_ip.is_empty():
		status_label.text = "Enter host IP address."
		return
	status_label.text = "Connecting to %s..." % host_ip
	join_btn.disabled = true
	NetworkManager.join_game(host_ip, player_name)

func _on_connection_failed() -> void:
	status_label.text = "Could not connect — lobby may be full (max %d players) or IP is wrong." % NetworkManager.MAX_PLAYERS
	join_btn.disabled = false

func _on_lobby_ready(_data: Dictionary) -> void:
	get_tree().change_scene_to_file.call_deferred("res://scenes/Lobby.tscn")
