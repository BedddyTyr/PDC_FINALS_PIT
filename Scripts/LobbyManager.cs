using Godot;
using System.Collections.Generic;

public partial class LobbyManager : Node
{
	private List<int> _connectedPlayers = new List<int>();
	private Dictionary<int, bool> _readyPlayers = 
		new Dictionary<int, bool>();

	public override void _Ready()
	{
		Multiplayer.PeerConnected += OnPeerConnected;
		Multiplayer.PeerDisconnected += OnPeerDisconnected;

		_connectedPlayers.Add(1);
		_readyPlayers[1] = false;
	}

	private void OnPeerConnected(long id)
	{
		_connectedPlayers.Add((int)id);
		_readyPlayers[(int)id] = false;
		GD.Print($"Player joined! ({_connectedPlayers.Count}/{NetworkManager.MaxPlayers})");
	}

	private void OnPeerDisconnected(long id)
	{
		_connectedPlayers.Remove((int)id);
		_readyPlayers.Remove((int)id);
		GD.Print($"Player left! ({_connectedPlayers.Count}/{NetworkManager.MaxPlayers})");
	}

	[Rpc(MultiplayerApi.RpcMode.AnyPeer, CallLocal = true)]
	public void SetPlayerReady(int playerId)
	{
		_readyPlayers[playerId] = true;
		GD.Print($"Player {playerId} is ready!");
		CheckAllReady();
	}

	private void CheckAllReady()
	{
		if (_connectedPlayers.Count < NetworkManager.MaxPlayers)
			return;

		foreach (var ready in _readyPlayers.Values)
		{
			if (!ready) return;
		}

		GD.Print("All players ready! Starting game...");
		Rpc(nameof(StartGame));
	}

	[Rpc(MultiplayerApi.RpcMode.Authority, CallLocal = true)]
	private void StartGame()
	{
		GetTree().ChangeSceneToFile("res://Scenes/GameMatch.tscn");
	}
}
