using Godot;
using System.Collections.Generic;

public partial class LobbyManager : Node
{
	private List<int> _connectedPlayers = new List<int>();

	public override void _Ready()
	{
		Multiplayer.PeerConnected += OnPeerConnected;
		Multiplayer.PeerDisconnected += OnPeerDisconnected;

		// Add host to list
		_connectedPlayers.Add(1);
		UpdateLobbyUI();
	}

	private void OnPeerConnected(long id)
	{
		_connectedPlayers.Add((int)id);
		GD.Print($"Player joined! ({_connectedPlayers.Count}/{NetworkManager.MaxPlayers})");
		UpdateLobbyUI();

		// Start game when all players connected
		if (_connectedPlayers.Count == NetworkManager.MaxPlayers)
		{
			GD.Print("All players connected! Starting game...");
			Rpc(nameof(StartGame));
		}
	}

	private void OnPeerDisconnected(long id)
	{
		_connectedPlayers.Remove((int)id);
		GD.Print($"Player left! ({_connectedPlayers.Count}/{NetworkManager.MaxPlayers})");
		UpdateLobbyUI();
	}

	[Rpc(MultiplayerApi.RpcMode.Authority, CallLocal = true)]
	private void StartGame()
	{
		GetTree().ChangeSceneToFile("res://Scenes/GameMatch.tscn");
	}

	private void UpdateLobbyUI()
	{
		GD.Print($"Lobby: {_connectedPlayers.Count}/{NetworkManager.MaxPlayers} players");
	}
}
