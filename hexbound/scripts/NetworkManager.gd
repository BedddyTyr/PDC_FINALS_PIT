# NetworkManager.gd
# Autoload Singleton — handles all P2P LAN networking
# Host creates the session; clients join via local IP
extends Node

signal player_connected(peer_id: int, player_name: String)
signal player_disconnected(peer_id: int)
signal connection_failed()
signal server_disconnected()
signal game_action_received(action: Dictionary)
signal lobby_state_updated(lobby_info: Dictionary)

const DEFAULT_PORT: int = 5286
const MAX_PLAYERS: int = 4
const HANDSHAKE_CHANNEL: int = 0

var my_peer_id: int = 0
var my_player_name: String = "Player"
var connected_players: Dictionary = {}   # peer_id -> player_name
var is_host: bool = false
var game_started: bool = false

# ─── Host ────────────────────────────────────────────────────────────────────

func host_game(player_name: String, port: int = DEFAULT_PORT) -> Error:
	my_player_name = player_name
	var peer = ENetMultiplayerPeer.new()
	var err = peer.create_server(port, MAX_PLAYERS)
	if err != OK:
		push_error("Failed to create server: %s" % error_string(err))
		return err

	multiplayer.multiplayer_peer = peer
	my_peer_id = 1  # Host is always peer 1
	is_host = true
	connected_players[1] = player_name

	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)

	print("[NetworkManager] Hosting on port %d as '%s'" % [port, player_name])
	emit_signal("lobby_state_updated", _get_lobby_dict())
	return OK

# ─── Join ─────────────────────────────────────────────────────────────────────

func join_game(host_ip: String, player_name: String, port: int = DEFAULT_PORT) -> Error:
	my_player_name = player_name
	var peer = ENetMultiplayerPeer.new()
	var err = peer.create_client(host_ip, port)
	if err != OK:
		push_error("Failed to connect: %s" % error_string(err))
		return err

	multiplayer.multiplayer_peer = peer
	is_host = false

	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)

	print("[NetworkManager] Connecting to %s:%d as '%s'" % [host_ip, port, player_name])
	return OK

func disconnect_from_game() -> void:
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
	connected_players.clear()
	is_host = false
	game_started = false
	my_peer_id = 0

# ─── Peer callbacks ───────────────────────────────────────────────────────────

func _on_connected_to_server() -> void:
	my_peer_id = multiplayer.get_unique_id()
	print("[NetworkManager] Connected! My peer ID: %d" % my_peer_id)
	# Send our name to host
	rpc_id(1, "register_player", my_peer_id, my_player_name)

func _on_connection_failed() -> void:
	print("[NetworkManager] Connection failed.")
	emit_signal("connection_failed")

func _on_server_disconnected() -> void:
	print("[NetworkManager] Server disconnected.")
	disconnect_from_game()
	emit_signal("server_disconnected")

func _on_peer_connected(peer_id: int) -> void:
	print("[NetworkManager] Peer connected: %d" % peer_id)

func _on_peer_disconnected(peer_id: int) -> void:
	print("[NetworkManager] Peer disconnected: %d" % peer_id)
	connected_players.erase(peer_id)
	emit_signal("player_disconnected", peer_id)
	if is_host:
		_broadcast_lobby_state()

# ─── RPCs ─────────────────────────────────────────────────────────────────────

@rpc("any_peer", "reliable")
func register_player(peer_id: int, player_name: String) -> void:
	if not is_host:
		return
	connected_players[peer_id] = player_name
	print("[NetworkManager] Registered: %s (id=%d)" % [player_name, peer_id])
	emit_signal("player_connected", peer_id, player_name)
	_broadcast_lobby_state()

@rpc("authority", "reliable")
func receive_lobby_state(lobby_data: Dictionary) -> void:
	connected_players = lobby_data.get("players", {})
	# Convert string keys back to int (JSON serialization artifact)
	var fixed: Dictionary = {}
	for k in connected_players.keys():
		fixed[int(k)] = connected_players[k]
	connected_players = fixed
	emit_signal("lobby_state_updated", lobby_data)

@rpc("authority", "reliable")
func receive_game_action(action: Dictionary) -> void:
	emit_signal("game_action_received", action)

# Host broadcasts an action to all peers
func broadcast_action(action: Dictionary) -> void:
	if is_host:
		# Apply locally, then push to clients
		emit_signal("game_action_received", action)
		for peer_id in connected_players.keys():
			if peer_id != 1:
				rpc_id(peer_id, "receive_game_action", action)
	else:
		# Send to host, who will rebroadcast
		rpc_id(1, "relay_action_to_host", action)

@rpc("any_peer", "reliable")
func relay_action_to_host(action: Dictionary) -> void:
	if not is_host:
		return
	broadcast_action(action)

# ─── Helpers ──────────────────────────────────────────────────────────────────

func _get_lobby_dict() -> Dictionary:
	return {
		"players": connected_players,
		"host_id": 1,
		"game_started": game_started
	}

func _broadcast_lobby_state() -> void:
	var data = _get_lobby_dict()
	for peer_id in connected_players.keys():
		if peer_id != 1:
			rpc_id(peer_id, "receive_lobby_state", data)
	emit_signal("lobby_state_updated", data)

func get_local_ip() -> String:
	var addresses = IP.get_local_addresses()
	for addr in addresses:
		if addr.begins_with("192.168.") or addr.begins_with("10.") or addr.begins_with("172."):
			return addr
	return "127.0.0.1"

func get_player_count() -> int:
	return connected_players.size()
