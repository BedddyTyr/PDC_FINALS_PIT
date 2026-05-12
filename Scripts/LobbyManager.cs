using Godot;
using System.Collections.Generic;

public partial class LobbyManager : Node
{
	public static LobbyManager Instance { get; private set; }

	private List<int> _connectedPlayers = new List<int>();
	private Dictionary<int, bool> _readyPlayers =
		new Dictionary<int, bool>();

	[Signal]
	public delegate void AllPlayersReadyEventHandler();

	[Signal]
	public delegate void ReadyCountChangedEventHandler(
		int readyCount, int totalCount);

	public override void _Ready()
	{
		Instance = this;

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

	[Rpc(MultiplayerApi.RpcMode.AnyPeer, CallLocal = true,
		TransferMode = MultiplayerPeer.TransferModeEnum.Reliable)]
	public void SetPlayerReady(int playerId)
	{
		GD.Print($"Player {playerId} is ready!");

		if (!_readyPlayers.ContainsKey(playerId))
			_readyPlayers[playerId] = false;

		_readyPlayers[playerId] = true;

		int readyCount = GetReadyCount();
		int totalCount = _connectedPlayers.Count;

		EmitSignal(SignalName.ReadyCountChanged,
			readyCount, totalCount);

		CheckAllReady();
	}

	public int GetReadyCount()
	{
		int count = 0;
		foreach (var ready in _readyPlayers.Values)
			if (ready) count++;
		return count;
	}

	public int GetTotalPlayers()
	{
		return _connectedPlayers.Count;
	}

private void CheckAllReady()
{
	if (_connectedPlayers.Count < NetworkManager.MaxPlayers)
		return;

	// Only check non-host players (ID 1 is always host)
	foreach (var kvp in _readyPlayers)
	{
		if (kvp.Key == 1) continue; // Skip host
		if (!kvp.Value) return;
	}

		GD.Print("All players ready!");
		EmitSignal(SignalName.AllPlayersReady);
	}

	[Rpc(MultiplayerApi.RpcMode.Authority, CallLocal = true,
		TransferMode = MultiplayerPeer.TransferModeEnum.Reliable)]
	public void StartGame()
	{
		GetTree().ChangeSceneToFile(
			"res://Scenes/GameMatch.tscn");
	}
}
